BEGIN;

CREATE OR REPLACE FUNCTION public.enforce_booking_ambulance_subtype()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_required_subtype text;
    v_ambulance_subtype text;
BEGIN
    IF NEW.assigned_ambulance_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT subtype
    INTO v_ambulance_subtype
    FROM public.ambulances
    WHERE id = NEW.assigned_ambulance_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Selected ambulance was not found';
    END IF;

    v_required_subtype := regexp_replace(
        upper(trim(coalesce(NEW.service_subtype, ''))),
        '[^A-Z0-9]+',
        '_',
        'g'
    );
    v_ambulance_subtype := regexp_replace(
        upper(trim(coalesce(v_ambulance_subtype, ''))),
        '[^A-Z0-9]+',
        '_',
        'g'
    );

    IF v_required_subtype <> ''
       AND v_ambulance_subtype <> v_required_subtype THEN
        RAISE EXCEPTION
            'Ambulance subtype % does not match required booking subtype %',
            coalesce(nullif(v_ambulance_subtype, ''), 'UNSPECIFIED'),
            v_required_subtype;
    END IF;

    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.enforce_booking_ambulance_subtype() FROM PUBLIC;

DROP TRIGGER IF EXISTS bookings_require_compatible_ambulance_subtype
    ON public.bookings;

CREATE TRIGGER bookings_require_compatible_ambulance_subtype
    BEFORE INSERT OR UPDATE OF assigned_ambulance_id, service_subtype
    ON public.bookings
    FOR EACH ROW
    EXECUTE FUNCTION public.enforce_booking_ambulance_subtype();

CREATE OR REPLACE FUNCTION public.allocate_booking(
    p_booking_id text,
    p_ambulance_id text,
    p_driver_id uuid,
    p_doctor_id uuid DEFAULT NULL,
    p_emt_id uuid DEFAULT NULL
)
RETURNS public.bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    b public.bookings;
    a public.ambulances;
    d public.drivers;
    paired_driver public.drivers;
    doc public.doctors;
    v_emt_name text;
    v_tl_name text;
    v_pair_count integer;
    v_required_subtype text;
    v_ambulance_subtype text;
BEGIN
    IF auth.uid() IS NULL OR public.app_role() NOT IN ('ADMIN', 'TEAM_LEAD') THEN
        RAISE EXCEPTION 'Only ADMIN or TEAM_LEAD may allocate';
    END IF;

    SELECT *
    INTO b
    FROM public.bookings
    WHERE id = p_booking_id
    FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Booking not found';
    END IF;

    IF b.status::text <> 'CUSTOMER_ACCEPTED' THEN
        RAISE EXCEPTION
            'Customer must accept the quotation before allocation. Current status: %',
            b.status;
    END IF;

    SELECT *
    INTO a
    FROM public.ambulances
    WHERE id = p_ambulance_id
    FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Ambulance not found';
    END IF;

    IF a.status::text <> 'AVAILABLE' OR a.assigned_booking_id IS NOT NULL THEN
        RAISE EXCEPTION 'Ambulance is not available';
    END IF;

    IF a.category <> b.service_category THEN
        RAISE EXCEPTION 'Ambulance category does not match booking';
    END IF;

    v_required_subtype := regexp_replace(
        upper(trim(coalesce(b.service_subtype, ''))),
        '[^A-Z0-9]+',
        '_',
        'g'
    );
    v_ambulance_subtype := regexp_replace(
        upper(trim(coalesce(a.subtype, ''))),
        '[^A-Z0-9]+',
        '_',
        'g'
    );
    IF v_required_subtype <> ''
       AND v_ambulance_subtype <> v_required_subtype THEN
        RAISE EXCEPTION
            'Ambulance subtype % does not match required booking subtype %',
            coalesce(nullif(v_ambulance_subtype, ''), 'UNSPECIFIED'),
            v_required_subtype;
    END IF;

    IF b.req_oxygen AND NOT a.has_oxygen THEN
        RAISE EXCEPTION 'Selected ambulance lacks oxygen';
    END IF;
    IF b.req_icu AND NOT a.has_icu THEN
        RAISE EXCEPTION 'Selected ambulance lacks ICU capability';
    END IF;
    IF b.req_ventilator AND NOT a.has_ventilator THEN
        RAISE EXCEPTION 'Selected ambulance lacks ventilator capability';
    END IF;
    IF b.req_pediatric AND NOT a.has_pediatric_icu THEN
        RAISE EXCEPTION 'Selected ambulance lacks pediatric ICU capability';
    END IF;
    IF b.req_cardiac_monitor AND NOT a.has_cardiac_monitor THEN
        RAISE EXCEPTION 'Selected ambulance lacks cardiac monitor';
    END IF;
    IF b.req_stretcher AND NOT a.has_stretcher THEN
        RAISE EXCEPTION 'Selected ambulance lacks stretcher';
    END IF;
    IF b.req_wheelchair AND NOT a.has_wheelchair THEN
        RAISE EXCEPTION 'Selected ambulance lacks wheelchair';
    END IF;
    IF b.service_category = 'DEAD_BODY' AND NOT a.has_freezer THEN
        RAISE EXCEPTION 'Selected ambulance lacks mortuary freezer';
    END IF;

    SELECT count(*)
    INTO v_pair_count
    FROM public.drivers
    WHERE lower(trim(coalesce(assigned_ambulance_number, ''))) =
        lower(trim(coalesce(a.vehicle_number, '')));

    IF v_pair_count > 1 THEN
        RAISE EXCEPTION
            'Ambulance % has multiple primary drivers configured; resolve the driver pairing before allocation',
            a.vehicle_number;
    END IF;

    SELECT *
    INTO paired_driver
    FROM public.drivers
    WHERE lower(trim(coalesce(assigned_ambulance_number, ''))) =
        lower(trim(coalesce(a.vehicle_number, '')))
    FOR UPDATE;

    IF paired_driver.id IS NOT NULL AND paired_driver.id <> p_driver_id THEN
        RAISE EXCEPTION
            'Ambulance % is paired with driver %. Team Lead cannot replace the primary driver during booking allocation.',
            a.vehicle_number,
            paired_driver.name;
    END IF;

    SELECT *
    INTO d
    FROM public.drivers
    WHERE id = p_driver_id
    FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Driver not found';
    END IF;

    IF upper(coalesce(d.status::text, '')) NOT IN ('AVAILABLE', 'ON_DUTY')
       OR d.assigned_booking_id IS NOT NULL THEN
        RAISE EXCEPTION
            'Driver is not available. Current status: %',
            d.status;
    END IF;

    IF nullif(trim(coalesce(d.assigned_ambulance_number, '')), '') IS NOT NULL
       AND lower(trim(d.assigned_ambulance_number)) <>
           lower(trim(a.vehicle_number)) THEN
        RAISE EXCEPTION
            'Driver % is already paired to ambulance %',
            d.name,
            d.assigned_ambulance_number;
    END IF;

    IF NOT (
        b.service_category = ANY(
            coalesce(d.supported_categories, ARRAY[]::text[])
        )
    ) THEN
        RAISE EXCEPTION
            'Driver does not support booking category %',
            b.service_category;
    END IF;

    IF p_doctor_id IS NOT NULL THEN
        SELECT *
        INTO doc
        FROM public.doctors
        WHERE id = p_doctor_id
        FOR UPDATE;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Doctor not found';
        END IF;
        IF doc.status::text <> 'AVAILABLE'
           OR doc.assigned_booking_id IS NOT NULL THEN
            RAISE EXCEPTION 'Doctor is not available';
        END IF;
        IF b.req_pediatric AND NOT doc.is_pediatric_capable THEN
            RAISE EXCEPTION 'Doctor is not pediatric capable';
        END IF;
        IF b.req_doctor
           AND b.req_doctor_specialization IS NOT NULL
           AND lower(doc.specialization) <>
               lower(b.req_doctor_specialization) THEN
            RAISE EXCEPTION 'Doctor specialization does not match booking';
        END IF;
    ELSIF b.req_doctor THEN
        RAISE EXCEPTION 'Doctor is required for this booking';
    END IF;

    IF p_emt_id IS NOT NULL THEN
        SELECT full_name
        INTO v_emt_name
        FROM public.medical_crew
        WHERE id = p_emt_id
          AND upper(status::text) IN ('AVAILABLE', 'READY', 'ON_DUTY', 'ONLINE')
        FOR UPDATE;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Selected medical crew member is not available';
        END IF;
    ELSIF b.req_emt THEN
        RAISE EXCEPTION 'Medical crew is required for this booking';
    END IF;

    SELECT coalesce(full_name, email, '')
    INTO v_tl_name
    FROM public.profiles
    WHERE id = auth.uid();

    UPDATE public.ambulances
    SET status = 'ASSIGNED',
        assigned_booking_id = p_booking_id
    WHERE id = a.id;

    UPDATE public.drivers
    SET status = 'ASSIGNED',
        assigned_booking_id = p_booking_id,
        assigned_ambulance_number = a.vehicle_number
    WHERE id = d.id;

    IF p_doctor_id IS NOT NULL THEN
        UPDATE public.doctors
        SET status = 'ASSIGNED',
            assigned_booking_id = p_booking_id
        WHERE id = doc.id;
    END IF;

    UPDATE public.bookings
    SET assigned_ambulance_id = a.id,
        assigned_driver_id = d.id,
        assigned_doctor_id = p_doctor_id,
        assigned_emt_id = p_emt_id,
        assigned_by_tl_id = auth.uid(),
        assigned_by_tl_name = v_tl_name,
        assigned_at = now(),
        driver_name = d.name,
        driver_phone = d.phone,
        ambulance_vehicle_number = a.vehicle_number,
        ambulance_name = a.name,
        doctor_name = CASE WHEN p_doctor_id IS NULL THEN NULL ELSE doc.name END,
        emt_name = v_emt_name,
        status = 'ASSIGNED',
        updated_at = now()
    WHERE id = p_booking_id
    RETURNING * INTO b;

    INSERT INTO public.audit_logs (
        user_id,
        user_name,
        user_role,
        action,
        booking_id,
        entity_type,
        previous_value,
        new_value
    )
    VALUES (
        auth.uid(),
        v_tl_name,
        public.app_role(),
        'Booking allocated',
        p_booking_id,
        'BOOKING',
        'CUSTOMER_ACCEPTED',
        jsonb_build_object(
            'ambulance_id', a.id,
            'ambulance_vehicle_number', a.vehicle_number,
            'driver_id', d.id,
            'driver_name', d.name,
            'driver_pairing_enforced', paired_driver.id IS NOT NULL
        )::text
    );

    RETURN b;
END;
$$;

REVOKE ALL ON FUNCTION public.allocate_booking(text, text, uuid, uuid, uuid)
    FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.allocate_booking(text, text, uuid, uuid, uuid)
    TO authenticated;

CREATE OR REPLACE FUNCTION public.sync_booking_medical_crew_status()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_identity text;
    v_assignment_guard text;
    v_set_clause text;
    v_updated integer;
BEGIN
    IF NEW.assigned_emt_id IS NOT DISTINCT FROM OLD.assigned_emt_id THEN
        RETURN NEW;
    END IF;

    IF to_regclass('public.medical_crew') IS NULL
       OR NOT EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'medical_crew'
             AND column_name = 'status'
       ) THEN
        IF NEW.assigned_emt_id IS NOT NULL THEN
            RAISE EXCEPTION 'Medical crew roster is unavailable for allocation';
        END IF;
        RETURN NEW;
    END IF;

    v_identity := '';
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'medical_crew'
          AND column_name = 'id'
    ) THEN
        v_identity := 'id = $1';
    END IF;
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'medical_crew'
          AND column_name = 'profile_id'
    ) THEN
        v_identity := concat_ws(
            ' OR ',
            nullif(v_identity, ''),
            'profile_id = $1'
        );
    END IF;
    IF v_identity = '' THEN
        RAISE EXCEPTION 'Medical crew roster has no supported identifier';
    END IF;

    v_assignment_guard := '';
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'medical_crew'
          AND column_name = 'assigned_booking_id'
    ) THEN
        v_assignment_guard :=
            ' AND (assigned_booking_id IS NULL OR assigned_booking_id = $2)';
    END IF;

    IF OLD.assigned_emt_id IS NOT NULL THEN
        v_set_clause := 'status = ''AVAILABLE''';
        IF v_assignment_guard <> '' THEN
            v_set_clause := v_set_clause || ', assigned_booking_id = NULL';
            EXECUTE format(
                'UPDATE public.medical_crew SET %s WHERE (%s)%s',
                v_set_clause,
                v_identity,
                v_assignment_guard
            )
            USING OLD.assigned_emt_id, OLD.id;
        ELSE
            EXECUTE format(
                'UPDATE public.medical_crew SET %s WHERE (%s)',
                v_set_clause,
                v_identity
            )
            USING OLD.assigned_emt_id;
        END IF;
    END IF;

    IF NEW.assigned_emt_id IS NOT NULL THEN
        v_set_clause := 'status = ''ASSIGNED''';
        IF v_assignment_guard <> '' THEN
            v_set_clause := v_set_clause || ', assigned_booking_id = $2';
        END IF;

        IF v_assignment_guard <> '' THEN
            EXECUTE format(
                'UPDATE public.medical_crew SET %s WHERE (%s) '
                'AND upper(status::text) IN (''AVAILABLE'', ''READY'', ''ON_DUTY'', ''ONLINE'')%s',
                v_set_clause,
                v_identity,
                v_assignment_guard
            )
            USING NEW.assigned_emt_id, NEW.id;
        ELSE
            EXECUTE format(
                'UPDATE public.medical_crew SET %s WHERE (%s) '
                'AND upper(status::text) IN (''AVAILABLE'', ''READY'', ''ON_DUTY'', ''ONLINE'')',
                v_set_clause,
                v_identity
            )
            USING NEW.assigned_emt_id;
        END IF;
        GET DIAGNOSTICS v_updated = ROW_COUNT;

        IF v_updated <> 1 THEN
            RAISE EXCEPTION
                'Selected medical crew member is not available or is already assigned';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.sync_booking_medical_crew_status() FROM PUBLIC;

DROP TRIGGER IF EXISTS bookings_sync_medical_crew_status
    ON public.bookings;

CREATE TRIGGER bookings_sync_medical_crew_status
    AFTER UPDATE OF assigned_emt_id ON public.bookings
    FOR EACH ROW
    EXECUTE FUNCTION public.sync_booking_medical_crew_status();

CREATE OR REPLACE FUNCTION public.release_booking_resources_after_completion(
    p_booking_id text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    b public.bookings;
    v_crew_set text;
    v_crew_predicate text;
    v_crew_has_assignment boolean;
BEGIN
    SELECT *
    INTO b
    FROM public.bookings
    WHERE id = p_booking_id
      AND status::text = 'SERVICE_COMPLETED';

    IF NOT FOUND THEN
        RETURN;
    END IF;

    IF b.assigned_driver_id IS NOT NULL THEN
        UPDATE public.drivers AS d
        SET status = 'AVAILABLE',
            assigned_booking_id = NULL,
            assigned_ambulance_number = COALESCE(
                (
                    SELECT NULLIF(trim(a.vehicle_number), '')
                    FROM public.ambulances AS a
                    WHERE a.id = b.assigned_ambulance_id
                ),
                d.assigned_ambulance_number
            )
        WHERE d.id = b.assigned_driver_id
          AND (
              d.assigned_booking_id IS NULL
              OR d.assigned_booking_id = b.id
          );
    END IF;

    IF b.assigned_ambulance_id IS NOT NULL THEN
        UPDATE public.ambulances AS a
        SET status = 'AVAILABLE',
            assigned_booking_id = NULL
        WHERE a.id = b.assigned_ambulance_id
          AND (
              a.assigned_booking_id IS NULL
              OR a.assigned_booking_id = b.id
          );
    END IF;

    IF b.assigned_doctor_id IS NOT NULL THEN
        UPDATE public.doctors AS d
        SET status = 'AVAILABLE',
            assigned_booking_id = NULL
        WHERE d.id = b.assigned_doctor_id
          AND (
              d.assigned_booking_id IS NULL
              OR d.assigned_booking_id = b.id
          );
    END IF;

    IF b.assigned_emt_id IS NULL THEN
        RETURN;
    END IF;

    IF to_regclass('public.medical_crew') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'medical_crew'
             AND column_name = 'status'
       ) THEN
        v_crew_set := 'status = ''AVAILABLE''';
        v_crew_predicate := '';

        IF EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = 'medical_crew'
              AND column_name = 'id'
        ) THEN
            v_crew_predicate := 'id = $1';
        END IF;

        IF EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = 'medical_crew'
              AND column_name = 'profile_id'
        ) THEN
            v_crew_predicate := concat_ws(
                ' OR ',
                nullif(v_crew_predicate, ''),
                'profile_id = $1'
            );
        END IF;

        v_crew_has_assignment := EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = 'medical_crew'
              AND column_name = 'assigned_booking_id'
        );

        IF v_crew_has_assignment AND v_crew_predicate <> '' THEN
            v_crew_set := v_crew_set || ', assigned_booking_id = NULL';
            v_crew_predicate :=
                '(' || v_crew_predicate || ') AND '
                '(assigned_booking_id IS NULL OR assigned_booking_id = $2)';
        END IF;

        IF v_crew_predicate <> '' THEN
            IF v_crew_has_assignment THEN
                EXECUTE format(
                    'UPDATE public.medical_crew SET %s WHERE %s',
                    v_crew_set,
                    v_crew_predicate
                )
                USING b.assigned_emt_id, b.id;
            ELSE
                EXECUTE format(
                    'UPDATE public.medical_crew SET %s WHERE %s',
                    v_crew_set,
                    v_crew_predicate
                )
                USING b.assigned_emt_id;
            END IF;
        END IF;
    END IF;

END;
$$;

REVOKE ALL ON FUNCTION public.release_booking_resources_after_completion(text)
    FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.release_resources_on_booking_completion()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    PERFORM public.release_booking_resources_after_completion(NEW.id);
    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.release_resources_on_booking_completion()
    FROM PUBLIC;

DROP TRIGGER IF EXISTS bookings_release_resources_after_completion
    ON public.bookings;

CREATE TRIGGER bookings_release_resources_after_completion
    AFTER UPDATE OF status ON public.bookings
    FOR EACH ROW
    WHEN (
        OLD.status::text IS DISTINCT FROM NEW.status::text
        AND NEW.status::text = 'SERVICE_COMPLETED'
    )
    EXECUTE FUNCTION public.release_resources_on_booking_completion();

COMMIT;
