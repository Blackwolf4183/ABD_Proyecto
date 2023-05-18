- Añadir excepciones a todos los procedimientos y funciones
- Arreglar asistencia aleatoria en rellena_asistencia no funciona

- Falta poner los procedimientos y la entrega.sql todo bien en el archivo PEVAU.sql para la entrega y en el que reune todo.



DUDAS

- COMO DAR ROLES A USUARIOS SEGUN SU DNI


# TODO
- hay que darle create session a cada usuario y vocal que creamos para que se puedan conectar
- TODO: hay que mirar V_CONTADOR_ESTUDIANTES_EXAMEN no tiene mucho sentido
- TODO: hay que ver si aumentando numero de aulas caben todos los estudiantes, hay algo raro en la asignacion, con menos de 500 alumnos capacidad aula da problemas

# Presentacion

1) system.sql

    - Tener ejecutado system con todo y en la presentacion mostrar solo los selects con usuarios, tablespaces ...
        - Aqui mostramos con los selects que se han creado los dos tablespaces

2) ddl.sql
    - Mostrar script de creación con campos encriptados (telefono)

    -> Parte extra
        - Diseño E/R
            - Restricciones semánticas  -> mostrar que se ha hecho en el ddl
            - NOT NULL/UNIQUE


3) Entrega.sql
    - Mostrar creación de índices (+ los de clave primaria que se crean en el ddl) y los selects de los indices
    - Mostrar relleno de las tablas
        - relleno aleatorio de los campos que faltan de vocal
        - tabla externa 
        - trigger y vista para relleno de CENTRO
    - VM_estudiantes
    
    - Vistas
        - Explicar distintas vistas (vienen en rubrica cada una)
    -Procedimientos
        - Vienen todos los que vienen en la rubrica tal cual 
    -Paquetes
        -PA_ASIGNA 
            - ESTA FUNCION TARDA BASTANTE (POR LO MENOS 5 MIN) -> TENERLA YA EJECUTADA Y MOSTRAR SELECT DE CENTRO
        -TODO: falta PK_OCUPACION
    
    - Trigger
        - TODO: falta comprobar TR_BORRA_AULA 
    
    - Politica VPD
        - TODO: POLITICA DE AUTORIZACION VPD PARA ESTUDIANTES

    -> #### PARTE EXTRA ###
        - Rellenar materia, asistencia, vigilancia -> ejecutar
            - Se consideran procedimientos extras a los propuestos
        - Se han introducido suficientes datos para comprobar la integridad del modelo lógico -> sí con los procedimientos de arriba
        - Se han tratado correctamente mayusculas, minúsculas -> sí REVIEW: mirar a ver si se refiere a algo mas
        
        - TODO: DESPISTE
        - TODO: MIGRAR s


    - MAS COSAS DE LA PRIMERA PARTE QUE DECIR
        - se han ido haciendo commits en cada procedimiento y otras partes donde insertabamos datos
        - También se han manejado las excepciones y se ha hecho rollback si algo ha salido mal.

        - Respecto la practica 3 enseñar vistas V_OCUPACION_ASIGNADA, V_OCUPACION, V_VIGILANTES

4) seguridad.sql -> TODO: falta pasar a limpio en entrega con sus partes ordenadas de la rubrica

    - Roles : TODO: falta por hacer
    - Asignar usuarios a roles: TODO: 
    - Asignado permisos de forma restrictiva: TODO: 
    - Operaciones a realizar por los usuarios: TODO: no se bien a que se refiere
    - Política de gestión de contraseñas: TODO: introducir creo mediante triggers -> preguntar chatgpt
    - Activación de TDE -> hecho en  seguridad.sql
    - Auditoría -> hecho en el seguridad.sql