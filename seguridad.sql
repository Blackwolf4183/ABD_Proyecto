-- ######################### USUARIO PARA TODOS LOS ESTUDIANTES

ALTER TABLE ESTUDIANTE
ADD user_name VARCHAR2(50)
ADD user_password VARCHAR2(50);

create user E88126719U identified by AGOUO6Z0F;

CREATE OR REPLACE PROCEDURE RELLENA_USUARIO_ESTUDIANTES
AS
    CURSOR estudiantes IS
    SELECT * FROM ESTUDIANTE
    WHERE ROWNUM <= 100;
    
BEGIN
    FOR estudiante IN estudiantes LOOP

        UPDATE ESTUDIANTE
        SET user_name = 'E' || estudiante.DNI,
        user_password = 'A' || DBMS_RANDOM.STRING('x', 8)
        WHERE DNI =estudiante.DNI;
            
    END LOOP;
    
    
END;
/

BEGIN
    RELLENA_USUARIO_ESTUDIANTES;
END;
/

DECLARE 
    CURSOR estudiantes IS
    SELECT * FROM ESTUDIANTE
    WHERE ROWNUM <= 100;
BEGIN
    FOR estudiante IN estudiantes LOOP
        EXECUTE IMMEDIATE 'CREATE USER ' || estudiante.user_name || ' IDENTIFIED BY ' || estudiante.user_password;
    END LOOP;
END;
/

-- TODO: DAR ROLES

-- VISTA ESTUDIANTE PARA VER SU ASIGNACIÓN DE AULA

CREATE OR REPLACE VIEW ASIGNACION_AULA_ESTUDIANTE AS 
SELECT ESTUDIANTE_DNI, MATERIA_CODIGO, EXAMEN_FECHAYHORA, EXAMEN_AULA_CODIGO, EXAMEN_SEDE_CODIGO
FROM ASISTENCIA;

-- ######################### USUARIO ADMINISTRADOR SE LLAMA PEVAU

-- ######################### USUARIO PARA PERSONAL DE ACCESO

CREATE USER VICERRECTORADO IDENTIFIED BY vice_password;

-- TODO: DAR ROLES

-- ######################### USUARIO PARA VIGILANTE DE AULA

-- Añado las columnas necesarias
ALTER TABLE vocal
ADD user_name VARCHAR2(50)
ADD user_password VARCHAR2(50);

-- Meto los nombres de usuario y la contraseña que tendrán
CREATE OR REPLACE PROCEDURE RELLENA_USUARIO_VIGILANTES
AS
    CURSOR vigilantes IS
    SELECT * FROM VOCAL;
    
BEGIN
    FOR vigilante IN vigilantes LOOP

        UPDATE VOCAL
        SET user_name = 'V' || vigilante.DNI,
        user_password = 'A' || DBMS_RANDOM.STRING('x', 8)
        WHERE DNI =vigilante.DNI;
            
    END LOOP;
    
    
END;
/

BEGIN
    RELLENA_USUARIO_VIGILANTES;
END;
/

-- Creo los usuarios correspondientes con los usuarios y contraseñas ya guardados

DECLARE 
    CURSOR vigilantes IS
    SELECT * FROM VOCAL;
BEGIN
    FOR vigilante IN vigilantes LOOP
        EXECUTE IMMEDIATE 'CREATE USER ' || vigilante.user_name || ' IDENTIFIED BY ' || vigilante.user_password;
    END LOOP;
END;
/

-- TODO: DAR ROLES 

-- VISTA VIGILANTE PARA VER SU ASIGNACIÓN DE AULA

CREATE OR REPLACE VIEW ASIGNACION_AULA_VIGILANTE AS 
SELECT *
FROM VIGILANCIA;

-- ######################### USUARIO RESPONSABLE DE AULA?????
-- ######################### USUARIO RESPONSABLE DE SEDE?????

-- TODO: Eliminar indice sobre telefono y cifrar la columna al crear la tabla, ya tendremos
-- la columna cifrada requerida

-- TODO: Aplicar VPD que me pasó Pere por discord lo último de todo para no tener
-- problemas al crear los usuarios que me faltan por crear.


-


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

--

--RESPONSABLE DE AULA
-- ACTUALIZACIÓN DE ESTUDIANTES EN EL AULA
CREATE OR REPLACE VIEW V_CONTADOR_ESTUDIANTES_EXAMEN AS
SELECT * FROM EXAMEN;