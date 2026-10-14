-- Driver-reported medical equipment inventory.
--
-- Apply in the Supabase SQL Editor before using Update inventory. The Driver
-- can update only their own stock. Team Lead visibility uses the existing
-- get_team_lead_drivers() SECURITY DEFINER feed.

BEGIN;

ALTER TABLE public.drivers
  ADD COLUMN IF NOT EXISTS available_medications text[] NOT NULL
  DEFAULT ARRAY[]::text[];

ALTER TABLE public.drivers
  ADD COLUMN IF NOT EXISTS available_equipment text[] NOT NULL
  DEFAULT ARRAY[]::text[];

CREATE OR REPLACE FUNCTION public.update_current_driver_inventory(
  p_medications text[],
  p_equipment text[]
)
RETURNS public.drivers
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_driver public.drivers;
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
        'Epinephrine',
        'Atropine',
        'Flumazenil',
        'Glucagon',
        'Amiodarone',
        'Sodium bicarbonate',
        'Naloxone',
        'Midazolam',
        'Lorazepam',
        'Diazepam',
        'Vasopressors',
        'Dopamine',
        'Norepinephrine',
        'Adenosine',
        'Metoprolol',
        'Chlorpheniramine',
        'Dexamethasone',
        'Hydrocortisone',
        'Tramadol'
      )
  ) THEN
    RAISE EXCEPTION 'Medicine inventory contains an unsupported medicine';
  END IF;

  IF p_equipment IS NULL OR EXISTS (
    SELECT 1
    FROM unnest(p_equipment) AS selected(item)
    WHERE selected.item IS NULL
      OR btrim(selected.item) NOT IN (
        'Oxygen cylinder',
        'Oxygen mask and nasal cannula',
        'Bag-valve mask',
        'BiPAP machine',
        'Laryngoscope with compatible blades',
        'Portable suction unit',
        'Pulse oximeter',
        'Blood pressure monitor',
        'Cardiac monitor',
        'AED / defibrillator',
        'Portable ECG machine',
        'Transport ventilator',
        'Nebulizer',
        'Glucometer',
        'Thermometer',
        'Stethoscope',
        'IV infusion pump',
        'Syringe pump',
        'Airway management kit',
        'Cervical collars',
        'Spine board',
        'Splints',
        'Trauma and wound-care kit',
        'Hemorrhage-control kit',
        'PPE and isolation kit',
        'Burn dressing kit',
        'Obstetric delivery kit',
        'Neonatal transport incubator',
        'Stretcher',
        'Wheelchair'
      )
  ) THEN
    RAISE EXCEPTION 'Equipment inventory contains unsupported equipment';
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
      available_equipment = COALESCE(
        (
          SELECT array_agg(DISTINCT btrim(selected.item)
                           ORDER BY btrim(selected.item))
          FROM unnest(p_equipment) AS selected(item)
        ),
        ARRAY[]::text[]
      )
  WHERE id = v_driver.id
  RETURNING * INTO v_driver;

  RETURN v_driver;
END;
$$;

REVOKE ALL ON FUNCTION public.update_current_driver_inventory(text[], text[])
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_current_driver_inventory(text[], text[])
  TO authenticated;

COMMIT;
