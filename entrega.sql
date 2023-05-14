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
                -- Añadimos al mismo tiempo los registros de materia_examen
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
CREATE OR REPLACE PROCEDURE RELLENAR_ASISTENCIA 
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
    
                -- añadimos a la asistencia cada alumno
                -- tenemos que seleccionar de examen una, donde la suma de los alumnos que 
                -- asisten ya ahí no sea ya igual a la capacidad de examen
                
                SELECT EXAMEN_AULA_CODIGO, EXAMEN_AULA_CODIGO1, EXAMEN_FECHAYHORA INTO aula_codigo,aula_sede_codigo, fechayhora
                FROM 
                (
                    SELECT e.*, COALESCE(COUNT(a.examen_aula_codigo), 0) AS N 
                    FROM MATERIA_EXAMEN e
                    LEFT JOIN ASISTENCIA a ON a.EXAMEN_FECHAYHORA = e.EXAMEN_FECHAYHORA AND a.EXAMEN_AULA_CODIGO = e.EXAMEN_AULA_CODIGO
                    WHERE e.MATERIA_CODIGO=asignatura.str
                    GROUP BY e.EXAMEN_FECHAYHORA, e.EXAMEN_AULA_CODIGO,e.EXAMEN_AULA_CODIGO1,e.MATERIA_CODIGO
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


-- 1.Vistas de Ocupación
/*
1. Crear una vista V_OCUPACION_ASIGNADA que reúna las tablas de sedes, examen y
asistencia y devuelva el código de sede, su nombre, código de aula, fecha de examen y
número de estudiantes asignados a un examen, agrupando por dicha sede, su nombre,
código de aula y fecha de examen.
*/

CREATE OR REPLACE VIEW V_OCUPACION_ASIGNADA AS
SELECT s.codigo AS codigo_sede, s.nombre AS nombre_sede, e.aula_codigo AS codigo_aula, e.fechayhora AS fecha_examen, COUNT(a.asiste) AS num_estudiantes
FROM sede s
INNER JOIN examen e ON s.codigo = e.aula_sede_codigo
INNER JOIN asistencia a ON e.aula_codigo = a.examen_aula_codigo
GROUP BY s.codigo, s.nombre, e.aula_codigo, e.fechayhora;

/*
2. Crear una vista V_OCUPACION que re�na las tablas de sedes, examen y asistencia y
devuelva el c�digo de sede, su nombre, c�digo de aula, fecha de examen y n�mero de
estudiantes que han asistido a un examen (atributo ASISTE = �SI�), agrupando por dicha
sede, su nombre, c�digo de aula y fecha de examen.
*/

CREATE OR REPLACE VIEW V_OCUPACION AS
SELECT s.codigo AS codigo_sede, s.nombre AS nombre_sede, e.aula_codigo AS codigo_aula, e.fechayhora AS fecha_examen, COUNT(a.asiste) AS num_estudiantes
FROM sede s
INNER JOIN examen e ON s.codigo = e.aula_sede_codigo
INNER JOIN asistencia a ON e.aula_codigo = a.examen_aula_codigo
WHERE a.asiste = 'S'
GROUP BY s.codigo, s.nombre, e.aula_codigo, e.fechayhora;

/*
3. Crear una vista V_VIGILANTES que re�na las tablas de sedes, examen y vigilancia y
devuelva el c�digo de sede, su nombre, c�digo de aula, fecha de examen y n�mero de
vigilantes que han vigilado un examen, agrupando por dicha sede, su nombre, c�digo de
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
1. Implementar una funci�n denominada OCUPACION_MAXIMA que reciba como
argumento el c�digo de sede y de aula y devuelva el n�mero m�ximo simult�neo de
personas que han estado presente en ella. Hay que tener en cuenta los diferentes
ex�menes y adem�s que el n�mero de personas es igual al n�mero de estudiantes, m�s
los vocales presentes en ella.
2. Implementar una funci�n denominada OCUPACION_OK que devuelva un booleano a
TRUE si todos los ex�menes a�n no realizados tienen un n�mero de estudiantes
asignados a un aula inferior o igual al atributo Capacidad_Examen y el n�mero total
de personas (alumnos + vocales) no supera al atributo Capacidad.
3. Implementar una funci�n denominada VOCAL_DUPLICADO que reciba como
argumento el identificador de un vocal y devuelva TRUE si dicho vocal est� asignado a
m�s de un examen en la misma franja horaria. Como es de esperar esto es algo que no
deber�a ocurrir.
4. Implementar una funci�n denominada VOCALES_DUPLICADOS que devuelva TRUE
si alguno de los vocales est� asignado a m�s de un examen en la misma franja.
5. Implementar una funci�n denominada VOCAL_RATIO que recibe un n�mero entero y
que devuelva un booleano a TRUE si en todos los ex�menes a�n no realizados hay el
n�mero indicado (o menos) de alumnos por cada vigilante.

*/

CREATE OR REPLACE PACKAGE BODY PK_OCUPACION AS
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
END PK_OCUPACION;
/

--4.
--Queremos implementar (mediante un trigger denominado TR_BORRA_AULA) el
--borrado de un aula (mediante una sentencia DELETE sobre la tabla AULA) que cumpla
--las siguientes condiciones:
--a. El borrado de un aula no es posible si ya se ha realizado un examen, o bien si
--hay planificado un examen antes de las próximas 48 horas.
--b. Si no se ha realizado examen ni hay planificado uno en las próximas 48 horas el
--borrado del aula implica el borrado de los exámenes planificados en la misma.



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
        RAISE_APPLICATION_ERROR(-20001, 'No se puede borrar el aula porque ya se han realizado exámenes en la misma.');
    END IF;
    
    -- Comprobamos si se va a realizar algun examen en el aula en las proximas 48 horas
    SELECT COUNT(*) INTO v_num_examenes
    FROM EXAMEN
    WHERE AULA_CODIGO = :OLD.CODIGO AND FECHAYHORA BETWEEN SYSDATE AND SYSDATE + 2;
    
    IF v_num_examenes > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'No se puede borrar el aula porque hay exámenes planificados en las próximas 48 horas.');
    END IF;
    
    -- Como resultado, todos los examenes que esten planificados para dicha aula se eliminan de la tabla "EXAMEN"
    DELETE FROM EXAMEN
    WHERE AULA_CODIGO = :OLD.CODIGO AND FECHAYHORA >= SYSDATE;
END;
/
