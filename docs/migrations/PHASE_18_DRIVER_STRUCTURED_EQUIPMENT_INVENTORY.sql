-- Structured, per-driver equipment inventory.
--
-- Apply after PHASE_17_DRIVER_EQUIPMENT_INVENTORY.sql. Existing medication
-- and equipment arrays remain available for older clients and Team Lead views.

BEGIN;

ALTER TABLE public.drivers
  ADD COLUMN IF NOT EXISTS available_equipment_details jsonb NOT NULL
  DEFAULT '[]'::jsonb;

-- Convert existing stock without deleting or duplicating it. Legacy "Ambu
-- Bag" labels are normalized to the existing canonical Bag-valve mask entry.
WITH legacy_items AS (
  SELECT
    d.id,
    CASE
      WHEN lower(btrim(item)) = 'ambu bag' THEN 'Bag-valve mask'
      ELSE btrim(item)
    END AS name
  FROM public.drivers AS d
  CROSS JOIN LATERAL unnest(COALESCE(d.available_equipment, ARRAY[]::text[])) AS item
  WHERE btrim(item) <> ''
),
deduplicated AS (
  SELECT id, min(name) AS name
  FROM legacy_items
  GROUP BY id, lower(name)
)
UPDATE public.drivers AS d
SET available_equipment_details = COALESCE((
  SELECT jsonb_agg(
    jsonb_build_object(
      'name', item.name,
      'available', true,
      'quantity', 1,
      'functional_condition', 'UNKNOWN',
      'inspection_status', 'NOT_INSPECTED',
      'checks', '{}'::jsonb
    )
    ORDER BY item.name
  )
  FROM deduplicated AS item
  WHERE item.id = d.id
), '[]'::jsonb)
WHERE d.available_equipment_details = '[]'::jsonb;

CREATE OR REPLACE FUNCTION public.is_valid_driver_equipment_inventory(
  p_inventory jsonb
)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
SET search_path = public
AS $$
DECLARE
  v_item jsonb;
  v_name text;
  v_available boolean;
  v_quantity integer;
  v_condition text;
  v_inspection text;
  v_checks jsonb;
  v_required_check text;
BEGIN
  IF p_inventory IS NULL OR jsonb_typeof(p_inventory) <> 'array' THEN
    RETURN false;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM jsonb_array_elements(p_inventory) AS entry(value)
    WHERE jsonb_typeof(entry.value) IS DISTINCT FROM 'object'
       OR NULLIF(btrim(entry.value->>'name'), '') IS NULL
       OR jsonb_typeof(entry.value->'available') IS DISTINCT FROM 'boolean'
       OR jsonb_typeof(entry.value->'quantity') IS DISTINCT FROM 'number'
       OR jsonb_typeof(entry.value->'checks') IS DISTINCT FROM 'object'
  ) THEN
    RETURN false;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM jsonb_array_elements(p_inventory) AS entry(value)
    GROUP BY lower(btrim(entry.value->>'name'))
    HAVING count(*) > 1
  ) THEN
    RETURN false;
  END IF;

  FOR v_item IN SELECT value FROM jsonb_array_elements(p_inventory)
  LOOP
    v_name := btrim(v_item->>'name');
    v_available := (v_item->>'available')::boolean;
    v_quantity := (v_item->>'quantity')::integer;
    v_condition := upper(COALESCE(v_item->>'functional_condition', ''));
    v_inspection := upper(COALESCE(v_item->>'inspection_status', ''));
    v_checks := v_item->'checks';

    IF (v_item->>'quantity')::numeric <> v_quantity
       OR v_quantity < 0 OR v_quantity > 9999
       OR (v_available AND v_quantity = 0)
       OR (NOT v_available AND v_quantity <> 0)
       OR v_condition NOT IN (
         'UNKNOWN', 'FUNCTIONAL', 'PARTIALLY_FUNCTIONAL', 'NON_FUNCTIONAL'
       )
       OR v_inspection NOT IN (
         'NOT_INSPECTED', 'PASSED', 'NEEDS_SERVICE', 'FAILED'
       )
    THEN
      RETURN false;
    END IF;

    IF v_inspection = 'PASSED' THEN
      IF v_condition <> 'FUNCTIONAL' THEN
        RETURN false;
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
          IF v_checks->>v_required_check IS DISTINCT FROM 'true' THEN
            RETURN false;
          END IF;
        END LOOP;
      ELSIF lower(v_name) = 'laryngoscope with compatible blades' THEN
        FOREACH v_required_check IN ARRAY ARRAY[
          'Handle operates',
          'Light or power function works',
          'Compatible blades available'
        ]
        LOOP
          IF v_checks->>v_required_check IS DISTINCT FROM 'true' THEN
            RETURN false;
          END IF;
        END LOOP;
      END IF;
    END IF;
  END LOOP;

  RETURN true;
EXCEPTION
  WHEN invalid_text_representation OR numeric_value_out_of_range THEN
    RETURN false;
END;
$$;

ALTER TABLE public.drivers
  ADD CONSTRAINT drivers_equipment_details_valid
  CHECK (public.is_valid_driver_equipment_inventory(available_equipment_details));

REVOKE ALL ON FUNCTION public.is_valid_driver_equipment_inventory(jsonb)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_valid_driver_equipment_inventory(jsonb)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.update_current_driver_inventory(
  p_medications text[],
  p_equipment text[],
  p_equipment_details jsonb
)
RETURNS public.drivers
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_driver public.drivers;
  v_equipment_from_details text[];
  v_equipment_input text[];
BEGIN
  IF auth.uid() IS NULL OR public.app_role() <> 'DRIVER' THEN
    RAISE EXCEPTION 'Driver authentication required';
  END IF;

  SELECT *
  INTO v_driver
  FROM public.drivers
  WHERE profile_id = auth.uid()
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Driver resource does not belong to the authenticated user';
  END IF;

  IF p_medications IS NULL OR EXISTS (
    SELECT 1
    FROM unnest(p_medications) AS selected(item)
    WHERE selected.item IS NULL
      OR btrim(selected.item) NOT IN (
        'Epinephrine', 'Atropine', 'Flumazenil', 'Glucagon', 'Amiodarone',
        'Sodium bicarbonate', 'Naloxone', 'Midazolam', 'Lorazepam',
        'Diazepam', 'Vasopressors', 'Dopamine', 'Norepinephrine',
        'Adenosine', 'Metoprolol', 'Chlorpheniramine', 'Dexamethasone',
        'Hydrocortisone', 'Tramadol'
      )
  ) THEN
    RAISE EXCEPTION 'Medicine inventory contains an unsupported medicine';
  END IF;

  IF NOT public.is_valid_driver_equipment_inventory(p_equipment_details) THEN
    RAISE EXCEPTION 'Equipment inventory details are invalid';
  END IF;

  SELECT COALESCE(array_agg(btrim(item->>'name') ORDER BY lower(btrim(item->>'name'))), ARRAY[]::text[])
  INTO v_equipment_from_details
  FROM jsonb_array_elements(p_equipment_details) AS details(item)
  WHERE (item->>'available')::boolean;

  SELECT COALESCE(
    array_agg(item ORDER BY lower(item), item),
    ARRAY[]::text[]
  )
  INTO v_equipment_input
  FROM (
    SELECT DISTINCT btrim(selected.item) AS item
    FROM unnest(COALESCE(p_equipment, ARRAY[]::text[])) AS selected(item)
    WHERE btrim(selected.item) <> ''
  ) AS deduplicated_equipment;

  IF EXISTS (
    SELECT lower(item) FROM unnest(v_equipment_from_details) AS available(item)
    EXCEPT
    SELECT lower(item) FROM unnest(v_equipment_input) AS selected(item)
  ) OR EXISTS (
    SELECT lower(item) FROM unnest(v_equipment_input) AS selected(item)
    EXCEPT
    SELECT lower(item) FROM unnest(v_equipment_from_details) AS available(item)
  ) THEN
    RAISE EXCEPTION 'Equipment selection does not match equipment details';
  END IF;

  UPDATE public.drivers
  SET available_medications = COALESCE(
        (
          SELECT array_agg(DISTINCT btrim(selected.item)
                           ORDER BY btrim(selected.item))
          FROM unnest(p_medications) AS selected(item)
        ),
        ARRAY[]::text[]
      ),
      available_equipment = v_equipment_from_details,
      available_equipment_details = p_equipment_details
  WHERE id = v_driver.id
  RETURNING * INTO v_driver;

  RETURN v_driver;
END;
$$;

REVOKE ALL ON FUNCTION public.update_current_driver_inventory(text[], text[], jsonb)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_current_driver_inventory(text[], text[], jsonb)
  TO authenticated;

COMMIT;
