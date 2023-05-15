-- PEVAU --
-- PRACTICA 1 --


-- Creación de la tabla externa
--Importante quitar la primera fila del archivo .csv (eliminar con un editor de texto las cabeceras, de otra forma no deja importarlo)
create table estudiantes_ext(
    centro              VARCHAR2(550),
    nombre              VARCHAR2(550), 
    apellido1           VARCHAR2(550), 
    apellido2           VARCHAR2(550), 
    dni                 VARCHAR2(515), 
    telefono            VARCHAR2(515), 
    detalle             VARCHAR2(550)
    
 )
ORGANIZATION EXTERNAL (
 TYPE ORACLE_LOADER
 DEFAULT DIRECTORY directorio_ext
 ACCESS PARAMETERS (
 RECORDS DELIMITED BY NEWLINE
 CHARACTERSET UTF8
 FIELDS TERMINATED BY ';'
 OPTIONALLY ENCLOSED BY '"'
 MISSING FIELD VALUES ARE NULL
 (centro, nombre, apellido1, apellido2, dni, telefono, detalle)
 )
 LOCATION ('datos-estudiantes-pevau.csv')
 );

-- Vemos los datos importados en la tabla
SELECT * FROM estudiantes_ext;

--Action: Don't do that! --> Vemos que no se posible modificar los valores de dicha tabla
UPDATE estudiantes_ext SET APELLIDO1='Gomez' WHERE ESTUDIANTES_EXT.NOMBRE = 'Carlos';


--Vista V_ESTUDIANTES
create or replace view v_estudiantes as
SELECT dni, nombre, apellido1 ||' '||apellido2 apellidos,
 telefono,
 substr(nombre,1,1)||apellido1||substr(dni,6,3) ||'@uncorreo.es' correo,
 centro, detalle
FROM estudiantes_ext
 where dni is not null;

-- Los centros diferentes de la vista v_estudiantes
select DISTINCT centro from v_estudiantes;

--5)
/*
CREATE INDEX TELEFONO
ON ESTUDIANTE (TELEFONO)
TABLESPACE TS_INDICES;
*/

CREATE INDEX CENTRO_CODIGO
ON ESTUDIANTE (CENTRO_CODIGO)
TABLESPACE TS_INDICES;

CREATE INDEX CORREO
ON ESTUDIANTE (CORREO)
TABLESPACE TS_INDICES;

SELECT * FROM USER_INDEXES;

-- QUERY para ver los indices en la base de datos con su tipo y de que tabla vienen
SELECT ui.index_name, ui.table_name, ui.tablespace_name,
       DECODE(ui.index_type, 'BITMAP', 'Bitmap',
                             'FUNCTION-BASED', 'Function-based',
                             'NORMAL', '-B+ Tree') as index_type
FROM user_indexes ui
LEFT JOIN user_ind_partitions uip ON ui.index_name = uip.index_name
LEFT JOIN user_ind_subpartitions uis ON ui.index_name = uis.index_name
ORDER BY ui.index_name;

-- ¿En qué tablespace reside la tabla ESTUDIANTE? ¿Y los índices? (compruébelo consultando el diccionario de datos) --> EN TS_PEVAU / EN TS_INDICES
SELECT table_name, tablespace_name
FROM user_tables
WHERE table_name = 'ESTUDIANTE';

SELECT index_name, tablespace_name
FROM user_indexes
WHERE table_name = 'ESTUDIANTE';

/*Aunque aún no hemos cargado los datos de los ESTUDIANTE, crea un índice de tipo BITMAP sobre el atributo que
indica el código del centro. Este índice también deberá residir en TS_INDICES.*/

DROP INDEX CENTRO_CODIGO;
CREATE BITMAP INDEX idx_centro ON ESTUDIANTE(CENTRO_CODIGO) TABLESPACE TS_INDICES;

-- Verificar en el diccionario de datos que este último índice es de tipo BITMAP.
SELECT * FROM USER_INDEXES WHERE INDEX_NAME='IDX_CENTRO';

--6)
-- Crear la vista materializada
CREATE MATERIALIZED VIEW VM_ESTUDIANTES
BUILD IMMEDIATE
REFRESH FORCE ON DEMAND
NEXT sysdate + 1
START WITH TRUNC(sysdate+1) + 0/24
AS
SELECT *
FROM ESTUDIANTES_EXT;

-- Crear el índice de la vista materializada
CREATE UNIQUE INDEX idx_vm_estudiantes ON VM_ESTUDIANTES(dni);

--7)
-- sinonimo publico
CREATE PUBLIC SYNONYM S_ESTUDIANTES FOR VM_ESTUDIANTES;

--8)
-- ya tiene permisos desde el principio para crear secuencias

-- crear secuencia seq_centro
CREATE SEQUENCE SEQ_CENTROS
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

create or replace trigger tr_centros
before insert on centro for each row
begin
if :new.codigo is null then
 :new.codigo := SEQ_CENTROS.NEXTVAL;
end if;
END tr_centros;
/


-- Prueba a insertar un centro cualquier con:
-- parace que los algunos campos tendrian que ser nullables para que esta parte de la practica funcione
ALTER TABLE CENTRO MODIFY "SEDE_CODIGO" NULL;

insert into centro (nombre) values ('Prueba');
select * from Centro;
rollback; -- para borrarlo

-- Insertamos los centros:
insert into centro (nombre) select distinct centro from
v_estudiantes;
select * from centro;
-- Si todo ha ido bien, confirmamos:
Commit;

--9 )
/*Hay que obtener los datos de la tabla ESTUDIANTE haciendo el join de la vista V_ESTUDIANTE y CENTRO, obteniendo
el código del centro en lugar de su nombre e insertar en la tabla ESTUDIANTE los datos: */
insert into estudiante
SELECT
 DNI, V_ESTUDIANTES.NOMBRE, APELLIDOS, TELEFONO, CORREO, CODIGO
FROM V_ESTUDIANTES
JOIN CENTRO ON V_ESTUDIANTES.CENTRO = CENTRO.NOMBRE;

--PRACTICA 2 --
-- 1) MATRICULA

/* 
Hay que crear un procedimiento que lea las materias de la vista V_ESTUDIANTES(detalle en nuestro caso) y las vaya 
insertando en la tabla de MATRICULA, buscando el código de la materia.
Para ello crearemos un procedimiento que dado un alumno y la lista de materias que viene en el 
campo DETALLE_MATERIA (lista de materias separadas por comas), inserte en la tabla de 
MATRICULA las filas correspondientes.
 */


CREATE OR REPLACE PROCEDURE PR_INSERTA_MATERIAS (
  PESTDNI VARCHAR2,
  PDETALLE_MATERIAS VARCHAR2
) AS
  CURSOR c_materias IS
    SELECT TRIM(REGEXP_SUBSTR(PDETALLE_MATERIAS, '[^,]+', 1, LEVEL)) materia
    FROM DUAL
    CONNECT BY REGEXP_SUBSTR(PDETALLE_MATERIAS, '[^,]+', 1, LEVEL) IS NOT NULL;

  v_codigo_materia VARCHAR2(100);
BEGIN

  FOR nombre_materia IN c_materias LOOP
    BEGIN
      SELECT CODIGO
      INTO v_codigo_materia
      FROM MATERIA
      WHERE NOMBRE = nombre_materia.materia;

      -- DBMS_OUTPUT.PUT_LINE('PESTDNI: ' || PESTDNI || ', v_codigo_materia: ' || v_codigo_materia);

      INSERT INTO MATRICULA (ESTUDIANTE_DNI, MATERIA_CODIGO)
      SELECT PESTDNI, v_codigo_materia FROM DUAL; 

      COMMIT;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- Manejo de excepción cuando no se encuentra el código de materia
        DBMS_OUTPUT.PUT_LINE('No se encontró el código de materia para: ' || nombre_materia.materia);
        ROLLBACK;
      WHEN OTHERS THEN
        -- Manejo de excepción para otros errores
        DBMS_OUTPUT.PUT_LINE('Ocurrió un error al procesar la materia: ' || nombre_materia.materia);
        ROLLBACK;
    END;
  END LOOP;
  
  EXCEPTION
    WHEN OTHERS THEN
      -- Manejo de excepción para errores generales
      DBMS_OUTPUT.PUT_LINE('Ocurrió un error general en el procedimiento.');
      ROLLBACK;
END;
/


CREATE OR REPLACE PROCEDURE PR_MATRICULA_ESTUDIANTES AS
    CURSOR c_estudiantes IS
        SELECT DNI,DETALLE FROM V_ESTUDIANTES;
BEGIN
    FOR estudiante IN c_estudiantes LOOP
        BEGIN
            PR_INSERTA_MATERIAS(estudiante.DNI, estudiante.DETALLE);
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                -- Manejo de excepción para errores generales
                DBMS_OUTPUT.PUT_LINE('Ocurrió un error al procesar el estudiante con DNI: ' || estudiante.DNI);
                ROLLBACK;
        END;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        -- Manejo de excepción para errores generales
        DBMS_OUTPUT.PUT_LINE('Ocurrió un error general en el procedimiento.');
        ROLLBACK;
END;
/


--2)
CREATE OR REPLACE PROCEDURE PR_RELLENA_AULAS (PNUMAULAS NUMBER,
                                              PCAPACIDAD NUMBER) AS
    
BEGIN
  FOR i IN (SELECT DISTINCT CODIGO FROM SEDE) LOOP
    BEGIN
      FOR j IN 1..PNUMAULAS LOOP
        --DBMS_OUTPUT.PUT_LINE('PCAPACIDAD: ' || PCAPACIDAD || ', PNUMAULAS: ' || PNUMAULAS || 'i: '||i.CODIGO||'j: '||j);
        INSERT INTO AULA (CODIGO, SEDE_CODIGO, CAPACIDAD, CAPACIDAD_EXAMEN)
        VALUES ('SEDE'||i.CODIGO||'AULA'||j, i.CODIGO, PCAPACIDAD, (PCAPACIDAD/2));
      END LOOP;
      
      COMMIT; -- Commit después de cada iteración del bucle interno
    EXCEPTION
      WHEN OTHERS THEN
        -- Manejo de excepción para errores generales
        DBMS_OUTPUT.PUT_LINE('Ocurrió un error al crear aulas para la sede: ' || i.CODIGO);
        ROLLBACK;
    END;
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    -- Manejo de excepción para errores generales
    DBMS_OUTPUT.PUT_LINE('Ocurrió un error general en el procedimiento.');
    ROLLBACK;
END;
/


CREATE OR REPLACE PROCEDURE PR_BORRA_AULA_SEDE (PCODIGOSEDE SEDE.CODIGO%TYPE) AS
BEGIN
  DELETE FROM AULA
  WHERE SEDE_CODIGO = PCODIGOSEDE;
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    -- Manejo de excepción para errores generales
    DBMS_OUTPUT.PUT_LINE('Ocurrió un error al borrar las aulas de la sede: ' || PCODIGOSEDE);
    ROLLBACK;
END;
/


CREATE OR REPLACE PROCEDURE PR_BORRA_AULAS AS
BEGIN 
  FOR i IN (SELECT DISTINCT SEDE_CODIGO FROM AULA) LOOP
    BEGIN
      PR_BORRA_AULA_SEDE(i.SEDE_CODIGO);
    EXCEPTION
      WHEN OTHERS THEN
        -- Manejo de excepción para errores generales
        DBMS_OUTPUT.PUT_LINE('Ocurrió un error al borrar las aulas de la sede: ' || i.SEDE_CODIGO);
        ROLLBACK;
    END;
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    -- Manejo de excepción para errores generales
    DBMS_OUTPUT.PUT_LINE('Ocurrió un error general en el procedimiento.');
    ROLLBACK;
END;
/



-- Para borrar aulas
BEGIN
PR_BORRA_AULAS();
END;
/

-- Para rellenar aulas 
BEGIN
PR_RELLENA_AULAS(10,500);
END;
/

-- 3) ASIGNACION DE SEDE A CENTRO


CREATE OR REPLACE PACKAGE PK_ASIGNA AS

    FUNCTION F_PLAZAS(codigo_sede VARCHAR2) RETURN NUMBER;
    
    PROCEDURE PR_ASIGNA_SEDE;
    
END PK_ASIGNA;
/

-- Especificacion del paquete
CREATE OR REPLACE PACKAGE BODY PK_ASIGNA AS

    -- ####### FUNCION ########
  FUNCTION F_PLAZAS(codigo_sede VARCHAR2) RETURN NUMBER IS
    v_capacidad_aulas NUMBER;
    v_estudiantes NUMBER := 0;
    v_plazas_libres NUMBER ;
    v_aux NUMBER;
  BEGIN
    -- recibe codigo de sede y devuelve numero de plazas libres en esa sede
    
    -- capacidad_examen de aulas de la sede
    SELECT SUM(CAPACIDAD_EXAMEN) 
    INTO v_capacidad_aulas
    FROM AULA
    WHERE SEDE_CODIGO = codigo_sede;
    

    
    --iteramos entre todos los posibles centros asignados con la sede asignada con el codigo codigo_sede
    FOR r_centro  IN   (SELECT NOMBRE
                        FROM CENTRO 
                        WHERE SEDE_CODIGO = codigo_sede) 
    LOOP
            
    
            SELECT COUNT(*) 
            INTO v_aux
            FROM V_ESTUDIANTES
            WHERE V_ESTUDIANTES.CENTRO = r_centro.NOMBRE;
            
            v_estudiantes := v_estudiantes + v_aux;
            --DBMS_OUTPUT.PUT_LINE('v_estudiantes: ' || v_estudiantes);
            
    END LOOP;

    -- sumamos capacidad examen de aulas de la sede - numero estudiantes de los centros que la tienen como sede
    v_plazas_libres := v_capacidad_aulas - v_estudiantes;
    
    RETURN v_plazas_libres;
  END F_PLAZAS;
  
    
    --################### PROCEDIMIENTO ###################
    
    PROCEDURE PR_ASIGNA_SEDE IS
        CURSOR c_sedes IS
        SELECT CODIGO, NOMBRE
        FROM SEDE
        WHERE TIPO = 'INSTITUTO';
        
        v_plazas_libres NUMBER;
        v_sede_mas_plazas VARCHAR2(50);
    BEGIN
        -- Asignar sedes a los centros que sean sede
          FOR r_sede IN c_sedes LOOP
            UPDATE CENTRO SET SEDE_CODIGO = r_sede.CODIGO
            WHERE UPPER(NOMBRE) = UPPER(r_sede.NOMBRE);
            
          END LOOP;
        
        -- recorrer los centros por orden descendente del numero de estudiantes del instituto
        FOR r_centro  IN   (SELECT c.NOMBRE AS NOMBRE_CENTRO, COUNT(a.DNI) AS NUM_ESTUDIANTES
                            FROM CENTRO c
                            LEFT JOIN V_ESTUDIANTES a ON c.NOMBRE = a.CENTRO
                            WHERE c.SEDE_CODIGO IS NULL
                            GROUP BY c.NOMBRE
                            ORDER BY COUNT(a.DNI) DESC) 
        LOOP
                
            -- Para cada centro, busca la sede con más plazas libres que todavía no ha sido asignada a ningún centro.
            SELECT MAX(F_PLAZAS(s.CODIGO))
            INTO v_plazas_libres
            FROM SEDE s;
            
            
            
            -- Cogemos la primera sede si es que hay varias con el mismo numero de plazas
            SELECT CODIGO INTO v_sede_mas_plazas FROM SEDE WHERE F_PLAZAS(CODIGO) = v_plazas_libres AND ROWNUM = 1;
            DBMS_OUTPUT.PUT_LINE('Sede con mas plazas: ' || v_sede_mas_plazas || ' , NUMERO PLAZAS: ' || v_plazas_libres || ' Centro a asignar: ' || r_centro.NOMBRE_CENTRO);
            
            
            IF v_plazas_libres <= r_centro.NUM_ESTUDIANTES THEN
                RAISE_APPLICATION_ERROR(-20001, 'Numero de plazas insuficiente.');
            END IF;
            
            -- Asignar a la sede con más plazas libres al centro
            UPDATE CENTRO SET SEDE_CODIGO = v_sede_mas_plazas
            WHERE UPPER(NOMBRE) = UPPER(r_centro.NOMBRE_CENTRO);
            
        END LOOP;
        
        -- Commit y gestion de errores
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Asignación de sedes completada.');
        EXCEPTION
          WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLCODE || ' - ' || SQLERRM);
            RAISE;
            
    END;
    
END PK_ASIGNA;
/

BEGIN
  PK_ASIGNA.PR_ASIGNA_SEDE;
END;
/




-- ULTIMA PRACTICA


-- Trigger TS_BORRA_AULA
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
