-- ### FUNCION DE POLITICA VPD ###

CREATE OR REPLACE FUNCTION es_usuario_estudiante (
  PEVAU IN VARCHAR2,
  ESTUDIANTE IN VARCHAR2
) RETURN VARCHAR2 IS
BEGIN
  -- Compara el nombre de usuario con el DNI, truncar la cadena para que pille el DNI
  RETURN 'DNI = SUBSTR(SYS_CONTEXT(''USERENV'', ''SESSION_USER''), 2)';

END;
/





-- ### TDE ###

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


-- ### AUDIT ###

-- AUDIT SOBRE UPDATE, INSERT Y DELETE EN LA TABLA ASISTENCIA PARA TODOS LOS USUARIOS -> no especifica nada en concreto la rubrica
AUDIT UPDATE, INSERT, DELETE ON asistencia BY ACCESS;

