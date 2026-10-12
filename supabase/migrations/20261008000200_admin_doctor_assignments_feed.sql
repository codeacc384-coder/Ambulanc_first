BEGIN;

DROP FUNCTION IF EXISTS public.get_admin_doctors();

CREATE FUNCTION public.get_admin_doctors()
RETURNS TABLE (
    id uuid,
    profile_id uuid,
    full_name text,
    phone text,
    specialization text,
    status text,
    created_at timestamptz,
    updated_at timestamptz,
    assigned_booking_id text,
    assigned_booking_status text
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
        CASE
            WHEN active_booking.assigned_booking_id IS NOT NULL THEN 'ASSIGNED'
            ELSE d.status
        END,
        d.created_at,
        d.updated_at,
        active_booking.assigned_booking_id,
        active_booking.assigned_booking_status
    FROM public.doctors AS d
    LEFT JOIN LATERAL (
        SELECT
            b.id::text AS assigned_booking_id,
            b.status::text AS assigned_booking_status
        FROM public.bookings AS b
        WHERE b.assigned_doctor_id = d.id
          AND b.status::text IN (
              'ASSIGNED',
              'DRIVER_ASSIGNED',
              'PICKUP_STARTED',
              'PATIENT_PICKED_UP',
              'IN_TRANSIT',
              'ARRIVED'
          )
        ORDER BY b.updated_at DESC NULLS LAST
        LIMIT 1
    ) AS active_booking ON true
    ORDER BY d.created_at DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_admin_doctors() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_admin_doctors() TO authenticated;

COMMIT;
