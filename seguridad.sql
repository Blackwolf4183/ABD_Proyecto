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

-- COPIAR Y PEGAR PARA EL RESTO DE TABLAS EN LAS QUE HAGA FALTA CREAR USUARIO