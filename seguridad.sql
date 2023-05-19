-- ######################### USUARIO PARA TODOS LOS ESTUDIANTES

-- AUDIT SOBRE TABLA ASISTENCIA
AUDIT UPDATE, INSERT, DELETE ON asistencia BY ACCESS;


-- ENCRIPTACION TDE

-- EN SYSTEM
alter system set "WALLET_ROOT"='C:\Users\app\alumnos\Oracle_instalacion\wallet' scope=SPFILE;
ALTER SYSTEM SET TDE_CONFIGURATION="KEYSTORE_CONFIGURATION=FILE" scope=both;
select * from v$encryption_wallet;

-- Sqlplus / as syskm
ADMINISTER KEY MANAGEMENT CREATE KEYSTORE IDENTIFIED BY password;
ADMINISTER KEY MANAGEMENT CREATE AUTO_LOGIN KEYSTORE FROM KEYSTORE IDENTIFIED BY password;
ADMINISTER KEY MANAGEMENT SET KEY force keystore identified by password with backup;


SELECT * FROM V$ENCRYPTION_WALLET; -- para ver información del keystore
SELECT * FROM DBA_ENCRYPTED_COLUMNS; -- para ver que está encriptada la columna te telefono








-- ##VISTAS##

-- VISTA ESTUDIANTE PARA VER SU ASIGNACIÓN DE AULA
CREATE OR REPLACE VIEW ASIGNACION_AULA_ESTUDIANTE AS 
SELECT ESTUDIANTE_DNI, MATERIA_CODIGO, EXAMEN_FECHAYHORA, EXAMEN_AULA_CODIGO, EXAMEN_SEDE_CODIGO
FROM ASISTENCIA;

-- VISTA VIGILANTE PARA VER SU ASIGNACIÓN DE AULA

CREATE OR REPLACE VIEW ASIGNACION_AULA_VIGILANTE AS 
SELECT *
FROM VIGILANCIA;

--VISTAS PARA ROLES
CREATE VIEW V_RESPONSABLE_SEDE_AULAS AS
SELECT * FROM AULA;

CREATE VIEW V_RESPONSABLE_SEDE_SEDES AS
SELECT * FROM SEDE;

CREATE VIEW V_RESPONSABLE_SEDE_ASISTENCIA AS
SELECT * FROM ASISTENCIA;

CREATE VIEW V_RESPONSABLE_SEDE_ASIGNACION_EXAMENES AS
SELECT * FROM MATERIA_EXAMEN;
-- 

CREATE OR REPLACE VIEW V_ASIGNACION_VIGILANTES AS
SELECT vi.*, vo.DNI, vo.NOMBRE, vo.APELLIDOS, vo.MATERIA_CODIGO FROM VIGILANCIA vi
JOIN VOCAL vo ON VOCAL_DNI = DNI
WHERE CARGO = 'VIGILANTE' OR CARGO = 'R_AULA';


--RESPONSABLE DE AULA
-- ACTUALIZACIÓN DE ESTUDIANTES EN EL AULA
CREATE OR REPLACE VIEW V_CONTADOR_ESTUDIANTES_EXAMEN AS
SELECT * FROM EXAMEN;






-- creación de usuario para vicerrectorado
CREATE USER VICERRECTORADO IDENTIFIED BY vice_password;






-- POLITICAS VPD
-- TODO: quedar por hacer bien
-- La funcion de add_policy esta en el system, aqui solo se crea la funcion que comprueba
CREATE OR REPLACE FUNCTION es_usuario_estudiante (
  PEVAU IN VARCHAR2,
  ESTUDIANTE IN VARCHAR2
) RETURN VARCHAR2 IS
BEGIN
  -- Compara el nombre de usuario con el DNI, voy a intentar truncar la cadena para que pille el DNI
  -- RETURN 'DNI = SYS_CONTEXT(''USERENV'', ''SESSION_USER'')';
  RETURN 'DNI = SUBSTR(SYS_CONTEXT(''USERENV'', ''SESSION_USER''), 2)';

END;
/



