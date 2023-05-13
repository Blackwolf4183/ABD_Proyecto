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
    
    n_estudiantes NUMBER;
    n_aulas_necesarias_por_hora NUMBER;
    capacidad_aulas NUMBER;
    
    n_aulas_hist NUMBER;
    n_aulas_len NUMBER;
    n_aulas_ing NUMBER;
    
    n_aulas_iteracion NUMBER;
 
BEGIN
    
    SELECT MIN(CAPACIDAD_EXAMEN) INTO capacidad_aulas FROM AULA;
    
    n_estudiantes := 0; -- Initialize the variable
  
      FOR materia IN materias_alumnos LOOP
        n_estudiantes := n_estudiantes + materia.N;
      END LOOP;
    
    n_aulas_necesarias_por_hora := ROUND(n_estudiantes/capacidad_aulas);

  
    DBMS_OUTPUT.PUT_LINE('ALUMNOS TOTALES: ' || n_estudiantes || ' aulas necesarias: ' || n_aulas_necesarias_por_hora);
    
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


-- 1.Vistas de Ocupación
/*
1. Crear una vista V_OCUPACION_ASIGNADA que reúna las tablas de sedes, examen y
asistencia y devuelva el código de sede, su nombre, código de aula, fecha de examen y
número de estudiantes asignados a un examen, agrupando por dicha sede, su nombre,
código de aula y fecha de examen.
*/