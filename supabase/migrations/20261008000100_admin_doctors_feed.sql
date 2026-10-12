BEGIN;

CREATE OR REPLACE FUNCTION public.get_admin_doctors()
RETURNS TABLE (
    id uuid,
    profile_id uuid,
    full_name text,
    phone text,
    specialization text,
    status text,
    created_at timestamptz,
    updated_at timestamptz
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF auth.uid() IS NULL OR public.app_role() <> 'ADMIN' THEN
        RAISE EXCEPTION 'Only ADMIN may read the doctor roster';
    END IF;

    RETURN QUERY
    SELECT
        d.id,
        d.profile_id,
        d.full_name,
        d.phone,
        d.specialization,
        d.status,
        d.created_at,
        d.updated_at
    FROM public.doctors AS d
    ORDER BY d.created_at DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_admin_doctors() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_admin_doctors() TO authenticated;

COMMIT;
