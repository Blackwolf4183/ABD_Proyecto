 -- Creación de indices
CREATE BITMAP INDEX idx_centro ON ESTUDIANTE(CENTRO_CODIGO) TABLESPACE TS_INDICES;

CREATE INDEX CORREO
ON ESTUDIANTE (CORREO)
TABLESPACE TS_INDICES;

SELECT ui.index_name, ui.table_name, ui.tablespace_name,
       DECODE(ui.index_type, 'BITMAP', 'Bitmap',
                             'FUNCTION-BASED', 'Function-based',
                             'NORMAL', '-B+ Tree') as index_type
FROM user_indexes ui
LEFT JOIN user_ind_partitions uip ON ui.index_name = uip.index_name
LEFT JOIN user_ind_subpartitions uis ON ui.index_name = uis.index_name
ORDER BY ui.index_name;


-- IMPORTANCIÓN DE LOS DATOS
-- MANUALMENTE CON IMPORTS DESDE LOS ARCHIVOS QUE NOS DAN

--ESTUDIANTES -> TABLA EXTERNA
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

--VOCALES

-- Aprovechamos y rellenamos los campos de la tabla de vocales que nos quedan de forma aleatoria ya que no nos dan datos para ello
-- PROCEDIMIENTO PARA RELLENAR DE FORMA ALEATORIA LOS CARGOS DE UN VOCAL
CREATE OR REPLACE PROCEDURE RELLENA_CARGOS_VOCAL AS
    CURSOR vocales IS 
    SELECT * FROM VOCAL;
BEGIN
    FOR vocal_actual IN vocales LOOP
        DECLARE
            cargo_vocal VARCHAR(20);
            materia_codigo_vocal VARCHAR(50);
        BEGIN
            -- Generar valores aleatorios para cargo
            CASE ROUND(DBMS_RANDOM.VALUE(1, 3))
                WHEN 1 THEN cargo_vocal := 'R_SEDE';
                WHEN 2 THEN cargo_vocal := 'R_AULA';
                WHEN 3 THEN cargo_vocal := 'VIGILANTE';
            END CASE;

            -- Generar valores aleatorios para materia_codigo
            CASE ROUND(DBMS_RANDOM.VALUE(1, 3))
                WHEN 1 THEN materia_codigo_vocal := 'HisE';
                WHEN 2 THEN materia_codigo_vocal := 'Len';
                WHEN 3 THEN materia_codigo_vocal := 'IngAcc';
            END CASE;

            -- Actualizar el registro del vocal con los valores generados
            UPDATE VOCAL
            SET cargo = cargo_vocal,
                materia_codigo =  materia_codigo_vocal
            WHERE DNI = vocal_actual.DNI;

            --DBMS_OUTPUT.PUT_LINE(materia_codigo_vocal);
        END;
    END LOOP;

    COMMIT;
END;
/


BEGIN
    RELLENA_CARGOS_VOCAL();
END;
/

SELECT * FROM VOCAL;

--MATERIAS
SELECT * FROM MATERIA;

-- SEDES
SELECT * FROM SEDE;

-- CENTROS

--crearemos primero la vista V_ESTUDIANTES de la que tomaremos los datos para popular la tabla CENTRO
create or replace view v_estudiantes as
SELECT dni, nombre, apellido1 ||' '||apellido2 apellidos,
 telefono,
 substr(nombre,1,1)||apellido1||substr(dni,6,3) ||'@uncorreo.es' correo,
 centro, detalle
FROM estudiantes_ext
 where dni is not null;




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

-- Insertamos los centros:
ALTER TABLE CENTRO MODIFY "SEDE_CODIGO" NULL; -- Para que nos deje comenzar las inserciones

insert into centro (nombre) select distinct centro from -- ahora si insertamos los centros
v_estudiantes;
-- Si todo ha ido bien, confirmamos:
Commit;

SELECT * FROM CENTRO; -- observamos que se han añadido los datos correctamente


-- VISTAS

-- primero antes de nada nos aseguramos de rellenar la tabla estudiantes
insert into estudiante
SELECT
 DNI, V_ESTUDIANTES.NOMBRE, APELLIDOS, TELEFONO, CORREO, CODIGO
FROM V_ESTUDIANTES
JOIN CENTRO ON V_ESTUDIANTES.CENTRO = CENTRO.NOMBRE;


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
-- Y sinónimo publico
CREATE PUBLIC SYNONYM S_ESTUDIANTES FOR VM_ESTUDIANTES;


-- VISTAS

-- VISTA ESTUDIANTE PARA VER SU ASIGNACIÓN DE AULA
CREATE OR REPLACE VIEW ASIGNACION_AULA_ESTUDIANTE AS 
SELECT ESTUDIANTE_DNI, MATERIA_CODIGO, EXAMEN_FECHAYHORA, EXAMEN_AULA_CODIGO, EXAMEN_SEDE_CODIGO
FROM ASISTENCIA;
-- PARA LOS DATOS DEL ESTUDIANTE PODEMOS USAR V_ESTUDIANTE

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

-- ASIGNACION DE VOCALES A EXAMENES
CREATE OR REPLACE VIEW V_ASIGNACION_VIGILANTES AS
SELECT vi.*, vo.DNI, vo.NOMBRE, vo.APELLIDOS, vo.MATERIA_CODIGO FROM VIGILANCIA vi
JOIN VOCAL vo ON VOCAL_DNI = DNI
WHERE CARGO = 'VIGILANTE' OR CARGO = 'R_AULA';


--RESPONSABLE DE AULA
-- ACTUALIZACIÓN DE ESTUDIANTES EN EL AULA
CREATE OR REPLACE VIEW V_CONTADOR_ESTUDIANTES_EXAMEN AS
SELECT * FROM EXAMEN;


-- 5.PROCEDIMIENTOS


-- PR_INSERTA_MATERIAS
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

-- PR_RELLENA_AULAS
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

--PR_BORRA_AULA_SEDE
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

--PR_BORRA_AULAS
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

-- RELLENAMOS LAS AULAS

BEGIN
    --PONER 20_500
    PR_RELLENA_AULAS(10,500);
END;
/

-- SI QUISIERAMOS BORRAR LAS AULAS
BEGIN
    PR_BORRA_AULAS();
END;
/

-- MATRICULAMOS A LOS ESTUDIANTES

DELETE FROM MATRICULA;
BEGIN
    PR_MATRICULA_ESTUDIANTES();
END;
/


-- PAQUETE PARA CREACION DE USUARIOS DE ESTUDIANTES Y VOCALES

--primero debemos modificar las tablas
--Añadimos los campos necesarios a estudiante
ALTER TABLE ESTUDIANTE
ADD user_name VARCHAR2(50)
ADD user_password VARCHAR2(50);

-- Añado las columnas necesarias
ALTER TABLE vocal
ADD user_name VARCHAR2(50)
ADD user_password VARCHAR2(50);


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
    EXCEPTION
    WHEN OTHERS THEN
    -- Manejo de excepción para errores generales
    DBMS_OUTPUT.PUT_LINE('Ocurrió un error general en el procedimiento.');
    ROLLBACK; -- Deshacer todos los cambios realizados en caso de un error general
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
    EXCEPTION
  WHEN OTHERS THEN
    -- Manejo de excepción para errores generales
    DBMS_OUTPUT.PUT_LINE('Ocurrió un error general en el procedimiento.');
    ROLLBACK; -- Deshacer todos los cambios realizados en caso de un error general
  END PR_CREA_VOCAL;
  
END PK_CREACION_USUARIOS;
/

-- HACEMOS UNA PRUEBA PARA GENERAR EL NOMBRE DE USUARIO Y CONTRASEÑA DE UN VOCAL
-- cuidado de que esté ya en la base de datos dicho usuario si no , no funcionará.
DECLARE
  v_nombre_usuario VARCHAR2(50);
  v_contrasena VARCHAR2(50);
BEGIN
  PK_CREACION_USUARIOS.PR_CREA_VOCAL('87104368Z', v_nombre_usuario, v_contrasena);
  -- Puedes reemplazar 'identificador_estudiante' con el valor deseado para el parámetro p_identificador.
  
  -- Imprime los valores generados para el nombre de usuario y la contraseña
  DBMS_OUTPUT.PUT_LINE('Nombre de usuario: ' || v_nombre_usuario);
  DBMS_OUTPUT.PUT_LINE('Contraseña: ' || v_contrasena);
END;
/

-- 4. PAQUETES PL/SQL

-- PQ_ASIGNA
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

-- PK OCUPACION TODO: FALTA POR HACER

CREATE OR REPLACE PACKAGE PK_OCUPACION AS
  FUNCTION OCUPACION_MAXIMA(p_cod_sede IN sede.codigo%TYPE, p_cod_aula IN aula.codigo%TYPE) RETURN NUMBER;
  FUNCTION OCUPACION_OK RETURN BOOLEAN;
  FUNCTION VOCAL_DUPLICADO(p_cod_vocal IN vocal.dni%TYPE) RETURN BOOLEAN;
  FUNCTION VOCALES_DUPLICADOS RETURN BOOLEAN;
  FUNCTION VOCAL_RATIO(p_ratio IN NUMBER) RETURN BOOLEAN;
END PK_OCUPACION;
/

CREATE OR REPLACE PACKAGE BODY PK_OCUPACION AS

--1
  FUNCTION OCUPACION_MAXIMA(p_cod_sede IN sede.codigo%TYPE, p_cod_aula IN aula.codigo%TYPE) 
  RETURN NUMBER 
  IS
    v_ocupacion_maxima NUMBER;
    n_vocales NUMBER;
  BEGIN
  
  -- Buscas por examen, y dado el codigo de aula y sede el maximo numero de alumnos que hace ese examen de entre las fechas
  SELECT MAX(N) INTO v_ocupacion_maxima
  FROM (
  SELECT COUNT(*) AS N, MATERIA_CODIGO, EXAMEN_FECHAYHORA, EXAMEN_AULA_CODIGO, EXAMEN_SEDE_CODIGO 
    FROM ASISTENCIA 
    WHERE EXAMEN_AULA_CODIGO =p_cod_sede AND EXAMEN_SEDE_CODIGO = p_cod_aula
    GROUP BY MATERIA_CODIGO, EXAMEN_FECHAYHORA, EXAMEN_AULA_CODIGO, EXAMEN_SEDE_CODIGO
  );
  
  -- buscas el máximo numero de vocales asignados a esa aula
  SELECT MAX(N) INTO n_vocales
  FROM (
  SELECT COUNT(*) AS N, MATERIA_CODIGO, EXAMEN_FECHAYHORA, EXAMEN_AULA_CODIGO, EXAMEN_SEDE_CODIGO 
    FROM V_ASIGNACION_VIGILANTES 
    WHERE EXAMEN_AULA_CODIGO =p_cod_sede AND EXAMEN_SEDE_CODIGO = p_cod_aula
    GROUP BY MATERIA_CODIGO, EXAMEN_FECHAYHORA, EXAMEN_AULA_CODIGO, EXAMEN_SEDE_CODIGO
  );
  
  v_ocupacion_maxima := v_ocupacion_maxima + n_vocales;
  
  RETURN v_ocupacion_maxima;
  END OCUPACION_MAXIMA;
  
  --2
  FUNCTION OCUPACION_OK RETURN BOOLEAN IS 
      capacidad_examen NUMBER;
      n_alumnos_aula NUMBER;
    BEGIN
    
        
        FOR examen IN (SELECT * FROM MATERIA_EXAMEN) LOOP
            
            --tomamos la capacidad de la aula en la que se hace el examen
            SELECT CAPACIDAD_EXAMEN INTO capacidad_examen
            FROM MATERIA_EXAMEN 
            JOIN AULA ON EXAMEN_AULA_CODIGO= CODIGO AND EXAMEN_SEDE_CODIGO = SEDE_CODIGO
            WHERE CODIGO = examen.EXAMEN_AULA_CODIGO AND SEDE_CODIGO = examen.EXAMEN_SEDE_CODIGO
            AND MATERIA_CODIGO = examen.MATERIA_CODIGO;
            
            SELECT COUNT(*) INTO n_alumnos_aula FROM
            ASISTENCIA 
            WHERE EXAMEN_FECHAYHORA = examen.EXAMEN_FECHAYHORA AND EXAMEN_AULA_CODIGO = examen.EXAMEN_AULA_CODIGO
            AND EXAMEN_SEDE_CODIGO = examen.EXAMEN_SEDE_CODIGO;
            
            
            IF n_alumnos_aula > capacidad_examen+1 THEN
                return FALSE;
            END IF;
        END LOOP;

        RETURN TRUE;
    END OCUPACION_OK;
    
    --3
    FUNCTION VOCAL_DUPLICADO(p_cod_vocal IN vocal.dni%TYPE) RETURN BOOLEAN IS
    vocal_duplicado NUMBER;
    BEGIN
        SELECT COUNT(*) INTO vocal_duplicado
        FROM (
            SELECT DISTINCT e1.fechayhora, e2.fechayhora
            FROM examen e1
            JOIN examen e2 ON e1.fechayhora <> e2.fechayhora -- <> == diferente
            JOIN vigilancia ve1 ON e1.fechayhora = ve1.examen_fechayhora
            JOIN vigilancia ve2 ON e2.fechayhora = ve2.examen_fechayhora
            JOIN vocal v ON ve1.vocal_dni = v.dni AND ve2.vocal_dni = v.dni
            WHERE e1.fechayhora = e2.fechayhora
            AND v.dni = p_cod_vocal
    );
    RETURN (vocal_duplicado>1);
    END VOCAL_DUPLICADO;
    
    --4
    FUNCTION VOCALES_DUPLICADOS RETURN BOOLEAN IS
        vocales_duplicados NUMBER;
        BEGIN
            SELECT COUNT(*) INTO vocales_duplicados
        FROM (
            SELECT DISTINCT e1.fechayhora, e2.fechayhora
            FROM examen e1
            JOIN examen e2 ON e1.fechayhora <> e2.fechayhora -- <> == diferente
            JOIN vigilancia ve1 ON e1.fechayhora = ve1.examen_fechayhora
            JOIN vigilancia ve2 ON e2.fechayhora = ve2.examen_fechayhora
            JOIN vocal v ON ve1.vocal_dni = v.dni AND ve2.vocal_dni = v.dni
            WHERE e1.FECHAYHORA = e2.FECHAYHORA
    );
        RETURN (vocales_duplicados>1);
    END VOCALES_DUPLICADOS;
    
  FUNCTION VOCAL_RATIO(p_ratio IN NUMBER) RETURN BOOLEAN IS
    v_examen_no_realizado NUMBER;
    v_total_alumnos NUMBER;
    v_total_vigilantes NUMBER;
    v_ratio NUMBER;
  BEGIN
    -- Obtener la cantidad de exámenes aún no realizados
    SELECT COUNT(*)
    INTO v_examen_no_realizado
    FROM examen
    WHERE FECHAYHORA>sysdate;
    
    -- Verificar si existen exámenes no realizados
    IF v_examen_no_realizado > 0 THEN
        -- for por cada examen
        -- suma alumnos
        -- suma vigilantes
        --  1/ENTRADA <= VILANTES/ALUMNOS
        
        FOR examen IN (SELECT * FROM MATERIA_EXAMEN ) LOOP
        
                SELECT COUNT(*) INTO v_total_alumnos
                FROM ASISTENCIA 
                WHERE MATERIA_CODIGO = examen.MATERIA_CODIGO AND 
                EXAMEN_FECHAYHORA = examen.EXAMEN_FECHAYHORA AND
                EXAMEN_AULA_CODIGO = examen.EXAMEN_AULA_CODIGO;
                
                SELECT COUNT(*) INTO v_total_vigilantes
                FROM ASISTENCIA 
                WHERE 
                EXAMEN_FECHAYHORA = examen.EXAMEN_FECHAYHORA AND
                EXAMEN_AULA_CODIGO = examen.EXAMEN_AULA_CODIGO;
                
                IF (1/p_ratio) > (v_total_vigilantes/v_total_alumnos) THEN
                    RETURN FALSE;
                END IF;
        END LOOP;
    END IF;
    
    RETURN TRUE;
  END VOCAL_RATIO;
  
END PK_OCUPACION;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE(PK_OCUPACION.OCUPACION_MAXIMA('SEDE11AULA7','11'));
END;
/



DECLARE
    v_result BOOLEAN;
BEGIN
    v_result := PK_OCUPACION.OCUPACION_OK();
    DBMS_OUTPUT.PUT_LINE('La asignación es correcta: ' || CASE WHEN v_result THEN 'TRUE' ELSE 'FALSE' END);
END;
/


DECLARE
    v_result BOOLEAN;
BEGIN
    v_result := PK_OCUPACION.VOCAL_DUPLICADO('86382068I');
    DBMS_OUTPUT.PUT_LINE('Hay vocal duplicado: ' || CASE WHEN v_result THEN 'TRUE' ELSE 'FALSE' END);
END;
/

DECLARE
    v_result BOOLEAN;
BEGIN
    v_result := PK_OCUPACION.VOCALES_DUPLICADOS();
    DBMS_OUTPUT.PUT_LINE('Hay vocal duplicado: ' || CASE WHEN v_result THEN 'TRUE' ELSE 'FALSE' END);
END;
/


DECLARE
    v_result BOOLEAN;
BEGIN
    v_result := PK_OCUPACION.VOCAL_RATIO(200);
    DBMS_OUTPUT.PUT_LINE('Se cumple el ratio de vocales: ' || CASE WHEN v_result THEN 'TRUE' ELSE 'FALSE' END);
END;
/

-- TRIGGERS TR_BORRA_AULA


-- POLITICA DE AUTORIZACION VPD PARA ESTUDIANTES


































--###############################################################################################
-- ##############################COMIENZO EXTRA##################################################
--###############################################################################################

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
    n_aulas_hist := CEIL(n_aulas_hist/capacidad_aulas);
    
    SELECT COUNT(*) INTO n_aulas_len FROM MATRICULA 
    WHERE MATERIA_CODIGO = 'Len' GROUP BY MATERIA_CODIGO;
    n_aulas_len := CEIL(n_aulas_len/capacidad_aulas);
    
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

--select count(*), MATERIA_CODIGO FROM MATERIA_EXAMEN GROUP BY MATERIA_CODIGO;
--DELETE FROM MATERIA_EXAMEN;
--DELETE FROM EXAMEN;

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



--DELETE FROM VIGILANCIA;


BEGIN
    RELLENA_VIGILANCIA;
END;
/


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

                WHERE N < capacidad_aulas  FETCH FIRST 1 ROW ONLY;


                --DBMS_OUTPUT.PUT_LINE('alumno.ESTUDIANTE_DNI: ' || alumno.ESTUDIANTE_DNI || 'aula_codigo: ' || aula_codigo);

                INSERT INTO ASISTENCIA VALUES(asiste_aleatorio, asiste_aleatorio, alumno.ESTUDIANTE_DNI,
                                              asignatura.str,fechayhora,aula_codigo,aula_sede_codigo );

            END IF; 

        END LOOP;
    END LOOP;


END;
/


--DELETE FROM ASISTENCIA;
BEGIN
    RELLENAR_ASISTENCIA;
END;
/



-- ########### VISTAS PRACTICA 3 ###########

CREATE OR REPLACE VIEW V_OCUPACION_ASIGNADA AS
SELECT s.codigo AS codigo_sede, s.nombre AS nombre_sede, e.aula_codigo AS codigo_aula, e.fechayhora AS fecha_examen, COUNT(a.estudiante_dni) AS num_estudiantes
FROM sede s
INNER JOIN examen e ON s.codigo = e.aula_sede_codigo
INNER JOIN asistencia a ON e.aula_codigo = a.examen_aula_codigo
GROUP BY s.codigo, s.nombre, e.aula_codigo, e.fechayhora;


CREATE OR REPLACE VIEW V_OCUPACION AS
SELECT s.codigo AS codigo_sede, s.nombre AS nombre_sede, e.aula_codigo AS codigo_aula, e.fechayhora AS fecha_examen, COUNT(a.estudiante_dni) AS num_estudiantes
FROM sede s
INNER JOIN examen e ON s.codigo = e.aula_sede_codigo
INNER JOIN asistencia a ON e.aula_codigo = a.examen_aula_codigo
WHERE a.asiste = 'S'
GROUP BY s.codigo, s.nombre, e.aula_codigo, e.fechayhora;

CREATE OR REPLACE VIEW V_VIGILANTES AS
SELECT s.codigo AS codigo_sede, s.nombre AS nombre_sede, e.aula_codigo AS codigo_aula, e.fechayhora AS fecha_examen, COUNT(v.VOCAL_DNI) AS num_vigilantes
FROM sede s
INNER JOIN examen e ON s.codigo = e.aula_sede_codigo
INNER JOIN vigilancia v ON e.aula_codigo = v.examen_aula_codigo
GROUP BY s.codigo, s.nombre, e.aula_codigo, e.fechayhora;
