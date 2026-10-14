-- Optional ambulance configuration and booking-specific validation for
-- BiPAP machines and laryngoscopes. Existing ambulances remain disabled until
-- an Admin explicitly enables a capability for that unit.
--
-- Apply after PHASE_18_DRIVER_STRUCTURED_EQUIPMENT_INVENTORY.sql.

BEGIN;

ALTER TABLE public.ambulances
  ADD COLUMN IF NOT EXISTS has_bipap boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS has_laryngoscope boolean NOT NULL DEFAULT false;

-- Preserve the existing registration transaction and add opt-in flags as a
-- wrapper overload so clients using the original signature remain supported.
CREATE OR REPLACE FUNCTION public.admin_register_ambulance_with_driver(
  p_call_sign text,
  p_vehicle_number text,
  p_model text,
  p_subtype text,
  p_category text,
  p_base_station text,
  p_has_oxygen boolean,
  p_has_icu boolean,
  p_has_ventilator boolean,
  p_has_pediatric_icu boolean,
  p_has_incubator boolean,
  p_has_freezer boolean,
  p_has_cardiac_monitor boolean,
  p_has_stretcher boolean,
  p_driver_id uuid,
  p_has_bipap boolean DEFAULT false,
  p_has_laryngoscope boolean DEFAULT false
)
RETURNS public.ambulances
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_ambulance public.ambulances;
BEGIN
  v_ambulance := public.admin_register_ambulance_with_driver(
    p_call_sign,
    p_vehicle_number,
    p_model,
    p_subtype,
    p_category,
    p_base_station,
    p_has_oxygen,
    p_has_icu,
    p_has_ventilator,
    p_has_pediatric_icu,
    p_has_incubator,
    p_has_freezer,
    p_has_cardiac_monitor,
    p_has_stretcher,
    p_driver_id
  );

  UPDATE public.ambulances
  SET has_bipap = COALESCE(p_has_bipap, false),
      has_laryngoscope = COALESCE(p_has_laryngoscope, false)
  WHERE id = v_ambulance.id
  RETURNING * INTO v_ambulance;

  RETURN v_ambulance;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_register_ambulance_with_driver(
  text, text, text, text, text, text,
  boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean,
  uuid, boolean, boolean
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_register_ambulance_with_driver(
  text, text, text, text, text, text,
  boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean,
  uuid, boolean, boolean
) TO authenticated;

CREATE OR REPLACE FUNCTION public.validate_booking_special_equipment()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_booking jsonb := to_jsonb(NEW);
  v_requested jsonb;
  v_ambulance jsonb;
  v_driver jsonb;
  v_inventory jsonb;
  v_item jsonb;
  v_name text;
  v_booking_service text;
  v_ambulance_service text;
  v_requested_bipap boolean;
  v_requested_laryngoscope boolean;
  v_required_check text;
BEGIN
  v_requested := CASE
    WHEN jsonb_typeof(v_booking->'additional_equipment') = 'array'
      THEN v_booking->'additional_equipment'
    ELSE '[]'::jsonb
  END;

  SELECT EXISTS (
    SELECT 1
    FROM jsonb_array_elements_text(v_requested) AS requested(item)
    WHERE lower(btrim(requested.item)) = 'bipap machine'
  ) INTO v_requested_bipap;

  SELECT EXISTS (
    SELECT 1
    FROM jsonb_array_elements_text(v_requested) AS requested(item)
    WHERE lower(btrim(requested.item)) =
      'laryngoscope with compatible blades'
  ) INTO v_requested_laryngoscope;

  IF NOT v_requested_bipap AND NOT v_requested_laryngoscope THEN
    RETURN NEW;
  END IF;

  v_booking_service := NULLIF(btrim(v_booking->>'service_subtype'), '');
  IF v_booking_service IS NULL THEN
    RAISE EXCEPTION
      'BiPAP and laryngoscope requirements need an explicitly selected booking service';
  END IF;

  SELECT to_jsonb(a)
  INTO v_ambulance
  FROM public.ambulances AS a
  WHERE a.id::text = v_booking->>'assigned_ambulance_id';

  IF v_ambulance IS NULL THEN
    RAISE EXCEPTION 'Selected ambulance was not found for equipment validation';
  END IF;

  v_ambulance_service := COALESCE(
    NULLIF(btrim(v_ambulance->>'service_subtype'), ''),
    NULLIF(btrim(v_ambulance->>'subtype'), '')
  );
  IF v_ambulance_service IS NULL
     OR btrim(regexp_replace(
          upper(v_booking_service), '[^A-Z0-9]+', '_', 'g'
        ), '_')
        IS DISTINCT FROM
        btrim(regexp_replace(
          upper(v_ambulance_service), '[^A-Z0-9]+', '_', 'g'
        ), '_')
  THEN
    RAISE EXCEPTION
      'Selected ambulance configuration does not match the explicitly selected booking service';
  END IF;

  IF v_requested_bipap AND v_ambulance->>'has_bipap' IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION
      'Selected ambulance is not approved/configured for BiPAP';
  END IF;

  IF v_requested_laryngoscope
     AND v_ambulance->>'has_laryngoscope' IS DISTINCT FROM 'true'
  THEN
    RAISE EXCEPTION
      'Selected ambulance is not approved/configured for a laryngoscope';
  END IF;

  SELECT to_jsonb(d)
  INTO v_driver
  FROM public.drivers AS d
  WHERE d.id::text = v_booking->>'assigned_driver_id';

  IF v_driver IS NULL THEN
    RAISE EXCEPTION 'Selected driver was not found for equipment validation';
  END IF;

  v_inventory := CASE
    WHEN jsonb_typeof(v_driver->'available_equipment_details') = 'array'
      THEN v_driver->'available_equipment_details'
    ELSE '[]'::jsonb
  END;

  FOREACH v_name IN ARRAY ARRAY[
    CASE WHEN v_requested_bipap THEN 'BiPAP machine' END,
    CASE WHEN v_requested_laryngoscope
      THEN 'Laryngoscope with compatible blades'
    END
  ]
  LOOP
    IF v_name IS NULL THEN
      CONTINUE;
    END IF;

    SELECT item.value
    INTO v_item
    FROM jsonb_array_elements(v_inventory) AS item(value)
    WHERE lower(btrim(item.value->>'name')) = lower(v_name)
    LIMIT 1;

    IF v_item IS NULL
       OR v_item->>'available' IS DISTINCT FROM 'true'
       OR COALESCE((v_item->>'quantity')::numeric, 0) < 1
       OR upper(COALESCE(v_item->>'functional_condition', '')) <>
          'FUNCTIONAL'
       OR upper(COALESCE(v_item->>'inspection_status', '')) <> 'PASSED'
    THEN
      RAISE EXCEPTION
        'Paired driver has no inspected, functional % available',
        v_name;
    END IF;

    IF lower(v_name) = 'bipap machine' THEN
      FOREACH v_required_check IN ARRAY ARRAY[
        'Power supply and battery checked',
        'Circuit and tubing present',
        'Compatible mask/interface present',
        'Filter present',
        'Self-test and alarms checked'
      ]
      LOOP
        IF v_item->'checks'->>v_required_check IS DISTINCT FROM 'true' THEN
          RAISE EXCEPTION 'BiPAP inspection is incomplete: %', v_required_check;
        END IF;
      END LOOP;
    ELSE
      FOREACH v_required_check IN ARRAY ARRAY[
        'Handle operates',
        'Light or power function works',
        'Compatible blades available'
      ]
      LOOP
        IF v_item->'checks'->>v_required_check IS DISTINCT FROM 'true' THEN
          RAISE EXCEPTION
            'Laryngoscope inspection is incomplete: %',
            v_required_check;
        END IF;
      END LOOP;
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.validate_booking_special_equipment() FROM PUBLIC;

DROP TRIGGER IF EXISTS bookings_validate_special_equipment
  ON public.bookings;
CREATE TRIGGER bookings_validate_special_equipment
  BEFORE UPDATE OF assigned_ambulance_id, assigned_driver_id
  ON public.bookings
  FOR EACH ROW
  WHEN (
    NEW.assigned_ambulance_id IS NOT NULL
    AND NEW.assigned_driver_id IS NOT NULL
  )
  EXECUTE FUNCTION public.validate_booking_special_equipment();

COMMIT;
