-- Fix the structured driver inventory RPC's DISTINCT/ORDER BY aggregate.
--
-- Apply after PHASE_18_DRIVER_STRUCTURED_EQUIPMENT_INVENTORY.sql. PostgreSQL
-- requires an ORDER BY expression in array_agg(DISTINCT ...) to also appear
-- in that aggregate's argument list. Deduplicate first, then sort separately.

BEGIN;

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

  SELECT COALESCE(
    array_agg(
      btrim(item->>'name')
      ORDER BY lower(btrim(item->>'name'))
    ),
    ARRAY[]::text[]
  )
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
    SELECT lower(item)
    FROM unnest(v_equipment_from_details) AS available(item)
    EXCEPT
    SELECT lower(item)
    FROM unnest(v_equipment_input) AS selected(item)
  ) OR EXISTS (
    SELECT lower(item)
    FROM unnest(v_equipment_input) AS selected(item)
    EXCEPT
    SELECT lower(item)
    FROM unnest(v_equipment_from_details) AS available(item)
  ) THEN
    RAISE EXCEPTION 'Equipment selection does not match equipment details';
  END IF;

  UPDATE public.drivers
  SET available_medications = COALESCE(
        (
          SELECT array_agg(
            DISTINCT btrim(selected.item)
            ORDER BY btrim(selected.item)
          )
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
