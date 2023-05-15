-- Procedimiento para crear examenes en ciertas horas
CREATE OR REPLACE PROCEDURE RELLENA_EXAMEN 
AS 
    CURSOR materias_alumnos IS 
    SELECT MATERIA_CODIGO,COUNT(*) AS N FROM MATRICULA 
    WHERE MATERIA_CODIGO IN ('HisE','IngAcc','Len') GROUP BY MATERIA_CODIGO;
    
    CURSOR codigos_aulas IS
    SELECT ROWNUM,CODIGO, SEDE_CODIGO FROM AULA;
    
    TYPE FechaArray IS TABLE OF DATE INDEX BY BINARY_INTEGER;
    Fechas FechaArray;
    
    capacidad_aulas NUMBER;
    
    n_aulas_hist NUMBER;
    n_aulas_len NUMBER;
    n_aulas_ing NUMBER;
    
    n_aulas_iteracion NUMBER;
 
BEGIN
    
    SELECT MIN(CAPACIDAD_EXAMEN) INTO capacidad_aulas FROM AULA;

    
    Fechas(1) := TO_DATE('2023/05/01 08:00:00', 'yyyy/mm/dd hh24:mi:ss');
    Fechas(2) := TO_DATE('2023/05/02 11:30:00', 'yyyy/mm/dd hh24:mi:ss');
    Fechas(3) := TO_DATE('2023/05/03 13:00:00', 'yyyy/mm/dd hh24:mi:ss');
    
    -- calculamos cuantas aulas necesitamos por cada materia
    SELECT COUNT(*) INTO n_aulas_hist FROM MATRICULA 
    WHERE MATERIA_CODIGO = 'HisE' GROUP BY MATERIA_CODIGO;
    n_aulas_hist := ROUND(n_aulas_hist/capacidad_aulas);
    
    SELECT COUNT(*) INTO n_aulas_len FROM MATRICULA 
    WHERE MATERIA_CODIGO = 'Len' GROUP BY MATERIA_CODIGO;
    n_aulas_len := ROUND(n_aulas_len/capacidad_aulas);
    
    SELECT COUNT(*) INTO n_aulas_ing FROM MATRICULA 
    WHERE MATERIA_CODIGO = 'IngAcc' GROUP BY MATERIA_CODIGO;
    n_aulas_ing := ROUND(n_aulas_ing/capacidad_aulas);
    
    DBMS_OUTPUT.PUT_LINE('hist: ' ||n_aulas_hist  || 'len: ' ||n_aulas_len || 'ing: ' || n_aulas_ing);
    
    -- iteramos entre las fechas
    FOR i IN 1..Fechas.COUNT LOOP
        
        -- ponemos el numero de aulas que hay que asignar por asignatura
        IF i = 1 THEN
            n_aulas_iteracion := n_aulas_hist;
        ELSIF i = 2 THEN
            n_aulas_iteracion := n_aulas_ing;
        ELSE 
            n_aulas_iteracion := n_aulas_len;
        END IF;
    
        -- vamos a ir cogiendo las aulas que necesitemos
        FOR codigos IN codigos_aulas LOOP
                                
            if codigos.rownum < n_aulas_iteracion THEN
                --DBMS_OUTPUT.PUT_LINE('rownum: ' || codigos.rownum);
                --DBMS_OUTPUT.PUT_LINE('codigo_aula: ' || codigos.codigo || ' codigo_sede: ' || codigos.sede_codigo);
                INSERT INTO EXAMEN VALUES(Fechas(i),codigos.codigo,codigos.sede_codigo);
                -- AÃ±adimos al mismo tiempo los registros de materia_examen
                IF i = 1 THEN
                    INSERT INTO MATERIA_EXAMEN VALUES(Fechas(i),codigos.codigo,codigos.sede_codigo,'HisE');
                ELSIF i = 2 THEN
                    INSERT INTO MATERIA_EXAMEN VALUES(Fechas(i),codigos.codigo,codigos.sede_codigo,'IngAcc');
                ELSE 
                    INSERT INTO MATERIA_EXAMEN VALUES(Fechas(i),codigos.codigo,codigos.sede_codigo,'Len');
                END IF;
            END IF;
        END LOOP;
    END LOOP;
END;
/

select count(*), MATERIA_CODIGO FROM MATERIA_EXAMEN GROUP BY MATERIA_CODIGO;
DELETE FROM MATERIA_EXAMEN;
DELETE FROM EXAMEN;

BEGIN
   RELLENA_EXAMEN;  
END;
/

-- Rellenar tabla de vigilancia
-- Tabla vigilancia
CREATE OR REPLACE PROCEDURE RELLENA_VIGILANCIA 
AS
    CURSOR examenes IS 
    SELECT * FROM EXAMEN
    WHERE FECHAYHORA IN (TO_DATE('2023/05/01 08:00:00', 'yyyy/mm/dd hh24:mi:ss'), 
                        TO_DATE('2023/05/02 11:30:00', 'yyyy/mm/dd hh24:mi:ss'),
                        TO_DATE('2023/05/03 13:00:00', 'yyyy/mm/dd hh24:mi:ss'));
    
    VOCAL_DNI VARCHAR(9);
BEGIN
   FOR examen IN examenes LOOP
        SELECT DISTINCT DNI INTO VOCAL_DNI
        FROM VOCAL
        WHERE DNI NOT IN (SELECT VOCAL_DNI FROM VIGILANCIA WHERE EXAMEN_FECHAYHORA = examen.FECHAYHORA )
        FETCH FIRST 1 ROW ONLY;
   
        INSERT INTO VIGILANCIA VALUES(VOCAL_DNI, examen.FECHAYHORA, examen.AULA_CODIGO, examen.AULA_SEDE_CODIGO);
           
    END LOOP;
END;
/



DELETE FROM VIGILANCIA;


BEGIN
    RELLENA_VIGILANCIA;
END;
/

-- Rellena asistencia
-- Rellenar tabla asistencia
-- Rellenar tabla asistencia
create or replace PROCEDURE RELLENAR_ASISTENCIA 
AS
    CURSOR ALUMNOS IS 
    SELECT * FROM MATRICULA;


    -- capacidad de las aulas para el examen
    capacidad_aulas NUMBER;
    asiste_aleatorio CHAR(1);

    aula_codigo VARCHAR(50);
    aula_sede_codigo VARCHAR(50);
    fechayhora DATE;

BEGIN
    SELECT MIN(CAPACIDAD_EXAMEN) INTO capacidad_aulas FROM AULA;

    FOR asignatura IN (SELECT 'HisE' str FROM dual
            UNION ALL
            SELECT 'Len' str FROM dual
            UNION ALL
            SELECT 'IngAcc' str FROM dual)
    LOOP
        FOR alumno IN ALUMNOS LOOP

            IF alumno.MATERIA_CODIGO = asignatura.str THEN
                asiste_aleatorio := CASE DBMS_RANDOM.value(1, 4)
                         WHEN 1 THEN 'N'
                         ELSE 'S'
                         END;

                -- aÃ±adimos a la asistencia cada alumno
                -- tenemos que seleccionar de examen una, donde la suma de los alumnos que 
                -- asisten ya ahÃ­ no sea ya igual a la capacidad de examen

                SELECT EXAMEN_AULA_CODIGO, EXAMEN_SEDE_CODIGO, EXAMEN_FECHAYHORA INTO aula_codigo,aula_sede_codigo, fechayhora
                FROM 
                (
                    SELECT e.*, COALESCE(COUNT(a.examen_aula_codigo), 0) AS N 
                    FROM MATERIA_EXAMEN e
                    LEFT JOIN ASISTENCIA a ON a.EXAMEN_FECHAYHORA = e.EXAMEN_FECHAYHORA AND a.EXAMEN_AULA_CODIGO = e.EXAMEN_AULA_CODIGO
                    WHERE e.MATERIA_CODIGO=asignatura.str
                    GROUP BY e.EXAMEN_FECHAYHORA, e.EXAMEN_AULA_CODIGO, e.EXAMEN_SEDE_CODIGO, e.MATERIA_CODIGO
                )

                WHERE N < 1000  FETCH FIRST 1 ROW ONLY;


                --DBMS_OUTPUT.PUT_LINE('alumno.ESTUDIANTE_DNI: ' || alumno.ESTUDIANTE_DNI || 'aula_codigo: ' || aula_codigo);

                INSERT INTO ASISTENCIA VALUES(asiste_aleatorio, asiste_aleatorio, alumno.ESTUDIANTE_DNI,
                                              asignatura.str,fechayhora,aula_codigo,aula_sede_codigo );

            END IF; 

        END LOOP;
    END LOOP;


END;
/


DELETE FROM ASISTENCIA;
BEGIN
    RELLENAR_ASISTENCIA;
END;
/


-- 1.Vistas de OcupaciÃ³n
/*
1. Crear una vista V_OCUPACION_ASIGNADA que reÃºna las tablas de sedes, examen y
asistencia y devuelva el cÃ³digo de sede, su nombre, cÃ³digo de aula, fecha de examen y
nÃºmero de estudiantes asignados a un examen, agrupando por dicha sede, su nombre,
cÃ³digo de aula y fecha de examen.
*/

CREATE OR REPLACE VIEW V_OCUPACION_ASIGNADA AS
SELECT s.codigo AS codigo_sede, s.nombre AS nombre_sede, e.aula_codigo AS codigo_aula, e.fechayhora AS fecha_examen, COUNT(a.estudiante_dni) AS num_estudiantes
FROM sede s
INNER JOIN examen e ON s.codigo = e.aula_sede_codigo
INNER JOIN asistencia a ON e.aula_codigo = a.examen_aula_codigo
GROUP BY s.codigo, s.nombre, e.aula_codigo, e.fechayhora;

/*
2. Crear una vista V_OCUPACION que reï¿½na las tablas de sedes, examen y asistencia y
devuelva el cï¿½digo de sede, su nombre, cï¿½digo de aula, fecha de examen y nï¿½mero de
estudiantes que han asistido a un examen (atributo ASISTE = ï¿½SIï¿½), agrupando por dicha
sede, su nombre, cï¿½digo de aula y fecha de examen.
*/

CREATE OR REPLACE VIEW V_OCUPACION AS
SELECT s.codigo AS codigo_sede, s.nombre AS nombre_sede, e.aula_codigo AS codigo_aula, e.fechayhora AS fecha_examen, COUNT(a.estudiante_dni) AS num_estudiantes
FROM sede s
INNER JOIN examen e ON s.codigo = e.aula_sede_codigo
INNER JOIN asistencia a ON e.aula_codigo = a.examen_aula_codigo
WHERE a.asiste = 'S'
GROUP BY s.codigo, s.nombre, e.aula_codigo, e.fechayhora;

/*
3. Crear una vista V_VIGILANTES que reï¿½na las tablas de sedes, examen y vigilancia y
devuelva el cï¿½digo de sede, su nombre, cï¿½digo de aula, fecha de examen y nï¿½mero de
vigilantes que han vigilado un examen, agrupando por dicha sede, su nombre, cï¿½digo de
aula y fecha de examen.
*/

CREATE OR REPLACE VIEW V_VIGILANTES AS
SELECT s.codigo AS codigo_sede, s.nombre AS nombre_sede, e.aula_codigo AS codigo_aula, e.fechayhora AS fecha_examen, COUNT(v.VOCAL_DNI) AS num_vigilantes
FROM sede s
INNER JOIN examen e ON s.codigo = e.aula_sede_codigo
INNER JOIN vigilancia v ON e.aula_codigo = v.examen_aula_codigo
GROUP BY s.codigo, s.nombre, e.aula_codigo, e.fechayhora;


--2.Paquete PK_OCUPACION

CREATE OR REPLACE PACKAGE PK_OCUPACION AS
  FUNCTION OCUPACION_MAXIMA(p_cod_sede IN sede.codigo%TYPE, p_cod_aula IN aula.codigo%TYPE) RETURN NUMBER;
  FUNCTION OCUPACION_OK RETURN BOOLEAN;
  FUNCTION VOCAL_DUPLICADO(p_cod_vocal IN vocal.dni%TYPE) RETURN BOOLEAN;
  FUNCTION VOCALES_DUPLICADOS RETURN BOOLEAN;
  FUNCTION VOCAL_RATIO(p_ratio IN NUMBER) RETURN BOOLEAN;
END PK_OCUPACION;
/


/*
1. Implementar una funciï¿½n denominada OCUPACION_MAXIMA que reciba como
argumento el cï¿½digo de sede y de aula y devuelva el nï¿½mero mï¿½ximo simultï¿½neo de
personas que han estado presente en ella. Hay que tener en cuenta los diferentes
exï¿½menes y ademï¿½s que el nï¿½mero de personas es igual al nï¿½mero de estudiantes, mï¿½s
los vocales presentes en ella.
2. Implementar una funciï¿½n denominada OCUPACION_OK que devuelva un booleano a
TRUE si todos los exï¿½menes aï¿½n no realizados tienen un nï¿½mero de estudiantes
asignados a un aula inferior o igual al atributo Capacidad_Examen y el nï¿½mero total
de personas (alumnos + vocales) no supera al atributo Capacidad.
3. Implementar una funciï¿½n denominada VOCAL_DUPLICADO que reciba como
argumento el identificador de un vocal y devuelva TRUE si dicho vocal estï¿½ asignado a
mï¿½s de un examen en la misma franja horaria. Como es de esperar esto es algo que no
deberï¿½a ocurrir.
4. Implementar una funciï¿½n denominada VOCALES_DUPLICADOS que devuelva TRUE
si alguno de los vocales estï¿½ asignado a mï¿½s de un examen en la misma franja.
5. Implementar una funciï¿½n denominada VOCAL_RATIO que recibe un nï¿½mero entero y
que devuelva un booleano a TRUE si en todos los exï¿½menes aï¿½n no realizados hay el
nï¿½mero indicado (o menos) de alumnos por cada vigilante.

*/

CREATE OR REPLACE PACKAGE BODY PK_OCUPACION AS

--1
  FUNCTION OCUPACION_MAXIMA(p_cod_sede IN sede.codigo%TYPE, p_cod_aula IN aula.codigo%TYPE) RETURN NUMBER IS
  v_ocupacion_maxima NUMBER;
  BEGIN
  SELECT MAX(num_asistentes) INTO v_ocupacion_maxima
    FROM (
      SELECT COUNT(*) AS num_asistentes
      FROM examen e
      JOIN asistencia a ON e.FECHAYHORA = a.EXAMEN_FECHAYHORA --la fecha y hora del examen lo identifican
      JOIN aula au ON e.aula_codigo = au.codigo
      WHERE e.aula_sede_codigo = p_cod_sede AND e.aula_codigo = p_cod_aula
      GROUP BY e.fechayhora
      UNION ALL
      SELECT COUNT(*) + 1 AS num_asistentes
      FROM examen e
      JOIN vigilancia v ON e.FECHAYHORA = v.EXAMEN_FECHAYHORA
      JOIN aula au ON e.aula_codigo = au.codigo
      WHERE e.AULA_SEDE_CODIGO = p_cod_sede AND e.AULA_CODIGO = p_cod_aula
      GROUP BY e.FECHAYHORA
    ) t;
  RETURN v_ocupacion_maxima;
  END OCUPACION_MAXIMA;
  
  --2
  FUNCTION OCUPACION_OK RETURN BOOLEAN IS 
  v_ocupacion NUMBER;
  BEGIN
    -- Comprobar que para todos los exámenes aún no realizados,
    -- el número de estudiantes asignados a un aula es inferior o igual a Capacidad_Examen
    FOR examen IN (SELECT *
                   FROM examen
                   WHERE fechayhora > SYSDATE)
    LOOP
        SELECT COUNT(*) INTO v_ocupacion
        FROM asistencia a
        JOIN examen e ON a.examen_fechayhora = e.fechayhora
        JOIN aula au ON e.aula_codigo = au.codigo;
        
        IF v_ocupacion > au.capacidad_examen THEN
            RETURN FALSE;
        END IF;
    END LOOP;
    
    -- Comprobar que el número total de personas no supera Capacidad
    SELECT COUNT(*) INTO v_ocupacion
    FROM asistencia a
    JOIN examen e ON a.examen_fechayhora = e.fechayhora
    JOIN aula au ON e.aula_codigo = au.codigo
    JOIN sede s ON au.sede_codigo = s.codigo;
    
    IF v_ocupacion > au.capacidad THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;
    END OCUPACION_OK;
    
    --3
    FUNCTION VOCAL_DUPLICADO(p_cod_vocal IN vocal.dni%TYPE) RETURN BOOLEAN IS
    vocal_duplicado BOOLEAN :=FALSE;
    BEGIN
        SELECT COUNT(*) INTO vocal_duplicado
        FROM (
            SELECT DISTINCT e1.fechayhora, e2.fechayhora
            FROM examen e1
            JOIN examen e2 ON e1.fechayhora <> e2.fechayhora -- <> == diferente
            JOIN vigilancia ve1 ON e1.fechayhora = ve1.examen_fechayhora
            JOIN vigilancia ve2 ON e2.fechayhora = ve2.examen_fechayhora
            JOIN vocal v ON ve1.vocal_dni = v.dni AND ve2.vocal_dni = v.dni
            WHERE e1.fecha_examen = e2.fecha_examen
            AND v.dni = p_cod_vocal
    );
    RETURN (vocal_duplicado>0);
    END VOCAL_DUPLICADO;
    
    --4
    FUNCTION VOCALES_DUPLICADOS RETURN BOOLEAN IS
        vocales_duplicados BOOLEAN :=FALSE;
        BEGIN
            SELECT COUNT(*) INTO vocales_duplicados
        FROM (
            SELECT DISTINCT e1.fechayhora, e2.fechayhora
            FROM examen e1
            JOIN examen e2 ON e1.fechayhora <> e2.fechayhora -- <> == diferente
            JOIN vigilancia ve1 ON e1.fechayhora = ve1.examen_fechayhora
            JOIN vigilancia ve2 ON e2.fechayhora = ve2.examen_fechayhora
            JOIN vocal v ON ve1.vocal_dni = v.dni AND ve2.vocal_dni = v.dni
            WHERE e1.fecha_examen = e2.fecha_examen
    );
        RETURN (vocales_duplicados>0);
     END;
    END VOCALES_DUPLICADOS;

END PK_OCUPACION;
/


--3
/*
1. Crear un paquete con 2 procedimientos PR_CREA_ESTUDIANTE y
PR_CREA_VOCAL que reciban el identificador del individuo y que tenga dos
argumentos de salida que corresponderán el primero al nombre del usuario creado en
Oracle y el segundo a la contraseña generada (puedes utilizar la función STRING del
paquete DBMS_RANDOM). Estos procedimientos además deberán asignar todos los
roles, permisos que sean necesarios. No dudes en modificar el esquema de la base de
datos si fuera necesario.
*/

CREATE OR REPLACE PACKAGE PK_CREACION_USUARIOS AS
  PROCEDURE PR_CREA_ESTUDIANTE(p_identificador IN VARCHAR2, p_nombre_usuario OUT VARCHAR2, p_contrasena OUT VARCHAR2);
  PROCEDURE PR_CREA_VOCAL(p_identificador IN VARCHAR2, p_nombre_usuario OUT VARCHAR2, p_contrasena OUT VARCHAR2);
END PK_CREACION_USUARIOS;
/

CREATE OR REPLACE PACKAGE BODY PK_CREACION_USUARIOS AS

  PROCEDURE PR_CREA_ESTUDIANTE(p_identificador IN VARCHAR2, p_nombre_usuario OUT VARCHAR2, p_contrasena OUT VARCHAR2) IS
    v_usuario VARCHAR2(50);
    v_contrasena VARCHAR2(50);
  BEGIN
    -- Generar nombre de usuario y contraseña utilizando DBMS_RANDOM.STRING
    v_usuario := 'E' || p_identificador;
    v_contrasena := 'A' || DBMS_RANDOM.STRING('x', 8);
    
    --DBMS_OUTPUT.PUT_LINE(v_usuario || ' --- ' || v_contrasena);
    -- Insertar el usuario y contraseña en la tabla usuarios
    UPDATE estudiante SET user_name = v_usuario, user_password = v_contrasena
    WHERE DNI = p_identificador;
    
    -- Asignar roles y permisos al usuario creado
    EXECUTE IMMEDIATE 'CREATE USER ' || v_usuario || ' IDENTIFIED BY ' || v_contrasena;
    --TODO: dar roles
    --EXECUTE IMMEDIATE 'GRANT SELECT ON ASIGNACION_AULA_ESTUDIANTE TO ' || v_usuario || ' WHERE ESTUDIANTE_DNI =' || p_identificador;
    
    -- Asignar los valores generados a los argumentos de salida
    p_nombre_usuario := v_usuario;
    p_contrasena := v_contrasena;
  END PR_CREA_ESTUDIANTE;
  
  PROCEDURE PR_CREA_VOCAL(p_identificador IN VARCHAR2, p_nombre_usuario OUT VARCHAR2, p_contrasena OUT VARCHAR2) IS
    v_usuario VARCHAR2(50);
    v_contrasena VARCHAR2(50);
  BEGIN
    -- Generar nombre de usuario y contraseña utilizando DBMS_RANDOM.STRING
    v_usuario := 'V' || p_identificador;
    v_contrasena := 'A' || DBMS_RANDOM.STRING('x', 8);
    
    UPDATE vocal SET user_name =v_usuario , user_password = v_contrasena
    WHERE DNI = p_identificador;
    
    -- Asignar roles y permisos al usuario creado
    EXECUTE IMMEDIATE 'CREATE USER ' || v_usuario || ' IDENTIFIED BY ' || v_contrasena;
   
    
    -- Asignar los valores generados a los argumentos de salida
    p_nombre_usuario := v_usuario;
    p_contrasena := v_contrasena;
  END PR_CREA_VOCAL;
END PK_CREACION_USUARIOS;
/


DECLARE
  v_nombre_usuario VARCHAR2(50);
  v_contrasena VARCHAR2(50);
BEGIN
  PK_CREACION_USUARIOS.PR_CREA_VOCAL('95115697E', v_nombre_usuario, v_contrasena);
  -- Puedes reemplazar 'identificador_estudiante' con el valor deseado para el parámetro p_identificador.
  
  -- Imprime los valores generados para el nombre de usuario y la contraseña
  DBMS_OUTPUT.PUT_LINE('Nombre de usuario: ' || v_nombre_usuario);
  DBMS_OUTPUT.PUT_LINE('Contraseña: ' || v_contrasena);
END;
/

--4.
--Queremos implementar (mediante un trigger denominado TR_BORRA_AULA) el
--borrado de un aula (mediante una sentencia DELETE sobre la tabla AULA) que cumpla
--las siguientes condiciones:
--a. El borrado de un aula no es posible si ya se ha realizado un examen, o bien si
--hay planificado un examen antes de las prÃ³ximas 48 horas.
--b. Si no se ha realizado examen ni hay planificado uno en las prÃ³ximas 48 horas el
--borrado del aula implica el borrado de los exÃ¡menes planificados en la misma.



CREATE OR REPLACE TRIGGER TR_BORRA_AULA
BEFORE DELETE ON AULA
FOR EACH ROW
DECLARE
    --Declaramos una variable para poder comprobar el numero de examenes que hay en el aula
    v_num_examenes INTEGER;
BEGIN
    -- Comprobamos si ya se ha realizado algun examen en el aula
    SELECT COUNT(*) INTO v_num_examenes
    FROM EXAMEN
    WHERE AULA_CODIGO = :OLD.CODIGO AND FECHAYHORA IS NOT NULL;
    
    IF v_num_examenes > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'No se puede borrar el aula porque ya se han realizado exÃ¡menes en la misma.');
    END IF;
    
    -- Comprobamos si se va a realizar algun examen en el aula en las proximas 48 horas
    SELECT COUNT(*) INTO v_num_examenes
    FROM EXAMEN
    WHERE AULA_CODIGO = :OLD.CODIGO AND FECHAYHORA BETWEEN SYSDATE AND SYSDATE + 2;
    
    IF v_num_examenes > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'No se puede borrar el aula porque hay exÃ¡menes planificados en las prÃ³ximas 48 horas.');
    END IF;
    
    -- Como resultado, todos los examenes que esten planificados para dicha aula se eliminan de la tabla "EXAMEN"
    DELETE FROM EXAMEN
    WHERE AULA_CODIGO = :OLD.CODIGO AND FECHAYHORA >= SYSDATE;
END;
/

--5
--1.Implementar un procedimiento denominado DESPISTE que reubique a un estudiante
--que por error se ha presentado a un examen en una sede que no es la que le
--corresponde por su Centro. El procedimiento recibe como argumento un identificador
--de estudiante (DNI) y un identificador de examen (los atributos necesarios, por ejemplo,
--Fecha y hora, Aula y sede).
--a. Este procedimiento únicamente funcionará si queda menos de una hora para el
--comienzo del primer examen al que el alumno se tenga que presentar. Para ello
--se obtiene la primera hora de la tabla ASISTE que corresponda con el DNI del
--alumno y se comprueba la diferencia entre la fecha programada y la hora del
--sistema. Se comprueba si falta menos de una hora. Si no es así, el procedimiento
--devolverá una excepción. Recuerda que el tipo DATE almacena tanto la fecha
--como la hora. Probar con ASISTE.FechayHora between SYSDATE AND
--SYSDATE + 1/24
--b. Si el apartado anterior no ha dado error, el procedimiento debe permitir la
--asistencia del alumno en la sede nueva. Es decir, debe modificar la fila de la tabla
--ASISTE con el identificador del estudiante, la fecha, el código de la nueva sede
--y el código del aula pasada como parámetro.
--c. El procedimiento hará lo mismo con el resto de los exámenes de la fecha del
--sistema, para que el estudiante no tenga que moverse de sede. Para ello hay
--que recorrer el resto de los exámenes a los que el alumno tiene que presentarse
--ese día y buscarle un aula libre. Para cada examen se modifica la tabla asiste con
--los nuevos datos (aula y sede). La diferencia con el apartado anterior es que en
--el anterior el aula nos la pasan como parámetro, pero en este hay que buscarle
--un aula disponible. Los exámenes de otras fechas no se modifican.

CREATE OR REPLACE PROCEDURE DESPISTE (dni IN VARCHAR2, examen_id IN NUMBER, nueva_sede_cod IN VARCHAR2, nueva_aula_cod IN VARCHAR2)
AS
  fecha_hora DATE;
  fecha_actual DATE;
  examen_fecha_hora DATE;
  examen_aula_cod VARCHAR2(50);
  examen_sede_cod VARCHAR2(50);
  examenes_curso SYS_REFCURSOR;
BEGIN
  -- Comprobar que falta menos de una hora para el primer examen del estudiante
  SELECT MIN(EXAMEN_FECHAYHORA)
  INTO fecha_hora
  FROM ASISTENCIA
  WHERE ESTUDIANTE_DNI = dni;
  
  IF fecha_hora IS NULL THEN
    RAISE_APPLICATION_ERROR(-20001, 'El estudiante no está programado para ningún examen');
  END IF;
  
  fecha_actual := SYSDATE;
  
  IF fecha_hora - fecha_actual > 1/24 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Falta más de una hora para el primer examen del estudiante');
  END IF;
  
  -- Cambiar el aula y la sede del primer examen del estudiante
  UPDATE ASISTENCIA
  SET EXAMEN_AULA_CODIGO = nueva_aula_cod,
      EXAMEN_SEDE_CODIGO = nueva_sede_cod
  WHERE ESTUDIANTE_DNI = dni
  AND EXAMEN_FECHAYHORA = fecha_hora;
  
  -- Obtener los demás exámenes del estudiante para el día actual
  OPEN examenes_curso FOR
    SELECT EXAMEN_FECHAYHORA, EXAMEN_AULA_CODIGO, EXAMEN_SEDE_CODIGO
    FROM ASISTENCIA
    WHERE ESTUDIANTE_DNI = dni
    AND TRUNC(EXAMEN_FECHAYHORA) = TRUNC(fecha_actual)
    AND EXAMEN_FECHAYHORA > fecha_hora
    ORDER BY EXAMEN_FECHAYHORA ASC;
  
  LOOP
    -- Salir del bucle si no hay más exámenes para el día actual
    FETCH examenes_curso INTO examen_fecha_hora, examen_aula_cod, examen_sede_cod;
    EXIT WHEN examenes_curso%NOTFOUND;
    
    -- Buscar un aula disponible para el examen
    SELECT CODIGO
    INTO examen_aula_cod
    FROM AULA
    WHERE Codigo NOT IN (SELECT EXAMEN_AULA_CODIGO FROM ASISTENCIA WHERE EXAMEN_FECHAYHORA = examen_fecha_hora AND EXAMEN_SEDE_CODIGO = examen_sede_cod)
    AND SEDE_CODIGO = nueva_sede_cod
    AND ROWNUM = 1;
    
    -- Cambiar el aula y la sede del examen
    UPDATE ASISTENCIA
    SET EXAMEN_AULA_CODIGO = examen_aula_cod,
        EXAMEN_SEDE_CODIGO = nueva_sede_cod
    WHERE ESTUDIANTE_DNI = dni
    AND EXAMEN_FECHAYHORA = examen_fecha_hora;
  END LOOP;
  
  CLOSE examenes_curso;
  
  COMMIT;
END;
/

--2. Implementar un procedimiento denominado MIGRAR_CENTRO, que recibe el
--identificador de un centro y el identificador de una sede origen y destino.
--a. El procedimiento migrará todos sus alumnos de exámenes de la sede origen a
--la sede destino.
--b. El procedimiento repartirá a los alumnos en las aulas disponibles del nuevo
--centro sin superar nunca la Capacidad_Examen de cada aula.
--c. Si no es posible realizar dicha asignación el procedimiento deberá lanzar una
--excepción.
--d. En la implementación de este procedimiento el alumno recibirá tres posibles
--calificaciones según cómo se implemente (de menos puntuación a más
--puntuación):
--i. Más baja: Como procedimiento y si la asignación falla deja todo a medio
--hacer.
--ii. Media: Como procedimiento y si la asignación no es posible deja todo
--como estaba originalmente.
--iii. Más alta: Como trigger al hacer un UPDATE del campo de la sede de un
--centro (si el trigger falla todo debe quedar como estaba originalmente).

CREATE OR REPLACE PROCEDURE MIGRAR_CENTRO (centro_id_origen IN NUMBER, sede_id_origen IN NUMBER, sede_id_destino IN NUMBER)
AS
  capacidad_examen_max NUMBER;
  aula_codigo VARCHAR2(50);
  alumno_dni VARCHAR2(9);
  num_alumnos NUMBER;
  capacidad_aula NUMBER;
BEGIN
  -- Obtener la capacidad máxima de examen de las aulas en la sede destino
  SELECT CAPACIDAD_EXAMEN INTO capacidad_examen_max
  FROM AULA
  WHERE SEDE_CODIGO = sede_id_destino
  AND ROWNUM = 1;
  
  IF capacidad_examen_max IS NULL THEN
    RAISE_APPLICATION_ERROR(-20001, 'No se encontraron aulas disponibles en la sede destino');
  END IF;
  
  -- Migrar los alumnos de exámenes de la sede origen a la sede destino
  UPDATE ASISTENCIA
  SET EXAMEN_SEDE_CODIGO = sede_id_destino
  WHERE EXAMEN_SEDE_CODIGO = sede_id_origen;
  
  -- Repartir a los alumnos en las aulas disponibles del nuevo centro sin superar la capacidad de examen de cada aula
  FOR aula IN (SELECT CODIGO, CAPACIDAD_EXAMEN FROM AULA WHERE SEDE_CODIGO = sede_id_destino)
  LOOP
    aula_codigo := aula.CODIGO;
    capacidad_aula := aula.CAPACIDAD_EXAMEN;
    
    -- Contar el número de alumnos asignados al aula
    SELECT COUNT(*) INTO num_alumnos
    FROM ASISTENCIA
    WHERE EXAMEN_SEDE_CODIGO = sede_id_destino
    AND EXAMEN_AULA_CODIGO = aula_codigo;
    
    -- Asignar alumnos al aula si hay capacidad disponible
    IF num_alumnos < capacidad_aula THEN
      UPDATE ASISTENCIA
      SET EXAMEN_AULA_CODIGO = aula_codigo
      WHERE EXAMEN_SEDE_CODIGO = sede_id_destino
      AND EXAMEN_AULA_CODIGO IS NULL
      AND ROWNUM <= capacidad_aula - num_alumnos;
    ELSE
      RAISE_APPLICATION_ERROR(-20002, 'No hay capacidad suficiente en las aulas disponibles del nuevo centro');
    END IF;
  END LOOP;
  
  COMMIT;
END;
/
