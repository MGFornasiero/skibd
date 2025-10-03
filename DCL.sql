-- =============================================================
-- Cleanup existing roles (if any)
-- This section removes existing roles and their owned objects
-- to ensure a clean slate before creating new objects.
-- =============================================================

DO $Clean$
BEGIN
   -- Check if the 'student' role exists before trying to clean it up.
   IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'student') THEN
      RAISE NOTICE 'Role "student" exists. Cleaning up...';
      -- Terminate any active connections for the 'student' role to allow dropping it.
      PERFORM pg_terminate_backend(pid)
      FROM pg_stat_activity
      WHERE usename = 'student';

      -- Temporarily grant 'student' role to the current user ('postgres')
      -- to gain permissions for REASSIGN OWNED. This is required even for superusers.
      EXECUTE 'GRANT student TO ' || quote_ident(current_user);

      -- Drop objects owned by 'student' and, crucially, revoke any privileges
      -- granted to 'student' on other objects. This removes all dependencies.
      EXECUTE 'DROP OWNED BY student CASCADE';

      -- Revoke the temporary membership.
      EXECUTE 'REVOKE student FROM ' || quote_ident(current_user);

      -- Now that the role owns nothing, it can be dropped.
      EXECUTE 'DROP ROLE student';
   END IF;
END $Clean$;

-- =============================================================
-- Read-only user setup
-- This section creates a read-only role `student` and grants
-- appropriate permissions for accessing the database.
-- =============================================================
CREATE ROLE student WITH LOGIN PASSWORD 'Password'; -- Cambiare password in produzione

REVOKE ALL ON DATABASE postgres FROM student;

GRANT CONNECT ON DATABASE postgres TO student;

GRANT USAGE ON SCHEMA public TO student;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO student;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON TABLES TO student;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO student;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT EXECUTE ON FUNCTIONS TO student;

--valutare se servono anche le sequenze non credo perchè non fa insert
--GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO student;
--ALTER DEFAULT PRIVILEGES IN SCHEMA public
--GRANT SELECT ON SEQUENCES TO student;