-- system --
-- PRACTICA 1 --


-- Creación de tablespace TS_PEVAU
CREATE TABLESPACE TS_PEVAU DATAFILE 'C:\USERS\APP\ALUMNOS\ORADATA\ORCL\TS_PEVAU.DBF' SIZE 50M;

-- Creación de usuario PEVAU.
CREATE USER PEVAU IDENTIFIED BY pevau_contrasena DEFAULT TABLESPACE TS_PEVAU QUOTA 50M ON TS_PEVAU;

-- Damos los permisos necesarios a PEVAU;
GRANT ADMINISTRADOR TO PEVAU;

-- Creación tablespace TS_INDICES
CREATE TABLESPACE TS_INDICES DATAFILE 'C:\USERS\APP\ALUMNOS\ORADATA\ORCL\TS_INDICES.DBF' SIZE 50M;

ALTER USER PEVAU QUOTA 50M ON TS_INDICES;

GRANT CREATE TABLE, CREATE VIEW, CREATE MATERIALIZED VIEW, 
CREATE SEQUENCE, CREATE PROCEDURE, CREATE SESSION, CREATE ROLE,
DROP USER, GRANT ANY PRIVILEGE, CREATE USER,GRANT ANY ROLE, AUDIT_ADMIN,
CREATE TRIGGER, CREATE PUBLIC SYNONYM,CREATE ANY DIRECTORY,  ALTER USER TO PEVAU;

--Comprobar consultando el diccionario de datos que existen los tablespace TS_PEVAU y TS_INDICES.
SELECT TABLESPACE_NAME FROM DBA_TABLESPACES;

-- Tablespace default
SELECT USERNAME, DEFAULT_TABLESPACE FROM DBA_USERS WHERE USERNAME = 'PEVAU';
--  Comprobar consultando el diccionario de datos los datafiles que tienen asociado TS_PEVAU y TS_INDICES.
SELECT TABLESPACE_NAME, FILE_NAME, BYTES/1024/1024 SIZE_MB FROM DBA_DATA_FILES ;

-- Directorio para la tabla externa
create or replace directory directorio_ext as 'C:\Users\app\alumnos\admin\orcl\dpdump';

grant read, write on directory directorio_ext to PEVAU;

-- Más persmisos para PEVAU
GRANT CREATE TRIGGER TO PEVAU;

GRANT CREATE PUBLIC SYNONYM TO PEVAU;


--############# Para borrar las tablas de PEVAU si es necesario ###########

BEGIN
  FOR cur_rec IN (SELECT table_name FROM all_tables WHERE owner = 'PEVAU') LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || cur_rec.table_name || ' CASCADE CONSTRAINTS';
  END LOOP;
END;
/





-- ######### Politica VPD ##########
-- los estudiantes solo pueden ver 
BEGIN
  DBMS_RLS.ADD_POLICY(
    object_schema   => 'PEVAU',
    object_name     => 'V_ESTUDIANTES',
    policy_name     => 'politica_estudiantes',
    function_schema => 'PEVAU',
    policy_function => 'es_usuario_estudiante',
    statement_types => 'SELECT',
    update_check    => FALSE,
    enable          => TRUE
  );
END;
/

-- SI HAY QUE DESACTIVAR LA POLITICA
BEGIN
  DBMS_RLS.DROP_POLICY(
    object_schema   => 'PEVAU',
    object_name     => 'V_ESTUDIANTES',
    policy_name     => 'politica_estudiantes'
  );
END;
/
