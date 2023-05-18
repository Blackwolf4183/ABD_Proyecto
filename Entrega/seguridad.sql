-- ### FUNCION DE POLITICA VPD ###

CREATE OR REPLACE FUNCTION es_usuario_estudiante (
  PEVAU IN VARCHAR2,
  ESTUDIANTE IN VARCHAR2
) RETURN VARCHAR2 IS
BEGIN
  -- Compara el nombre de usuario con el DNI, voy a intentar truncar la cadena para que pille el DNI
  RETURN 'DNI = SUBSTR(SYS_CONTEXT(''USERENV'', ''SESSION_USER''), 2)';

END;
/