-- Driver-reported emergency medicine inventory.
--
-- Apply this migration before using the Driver inventory update action.
-- Drivers update only their own stock through a role-checked RPC. Team Lead
-- visibility uses the existing get_team_lead_drivers() SECURITY DEFINER feed.

BEGIN;

ALTER TABLE public.drivers
  ADD COLUMN IF NOT EXISTS available_medications text[] NOT NULL
  DEFAULT ARRAY[]::text[];

CREATE OR REPLACE FUNCTION public.update_current_driver_medication_inventory(
  p_medications text[]
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
    FROM unnest(p_medications) AS selected(medicine)
    WHERE selected.medicine IS NULL
      OR btrim(selected.medicine) NOT IN (
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

  UPDATE public.drivers
  SET available_medications = COALESCE(
    (
      SELECT array_agg(DISTINCT btrim(selected.medicine)
                       ORDER BY btrim(selected.medicine))
      FROM unnest(p_medications) AS selected(medicine)
    ),
    ARRAY[]::text[]
  )
  WHERE id = v_driver.id
  RETURNING * INTO v_driver;

  RETURN v_driver;
END;
$$;

REVOKE ALL ON FUNCTION public.update_current_driver_medication_inventory(text[])
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_current_driver_medication_inventory(text[])
  TO authenticated;

COMMIT;
