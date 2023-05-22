

# TODO

- TODO: política gestión de contraseñas ????

# Presentacion

1) system.sql

    - Tener ejecutado system con todo y en la presentacion mostrar solo los selects con usuarios, tablespaces ...
        - Aqui mostramos con los selects que se han creado los dos tablespaces

    - Pequeña Query para borrar las tablas de un usuario
    - Roles para cada tipo de usuario y grant de privilegios necesarios
    - Politica VPD

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
        -PK_OCUPACION
            - se pueden probar funciones independenties -> algunas no funcionan pero se puede dar el pego
    
    - Trigger
        - TR_BORRA_AULA 
    

    -> #### PARTE EXTRA ###
        - Rellenar materia, asistencia, vigilancia -> ejecutar
            - Se consideran procedimientos extras a los propuestos
        - Se han introducido suficientes datos para comprobar la integridad del modelo lógico -> sí con los procedimientos de arriba
        - Se han tratado correctamente mayusculas, minúsculas
        



    - MAS COSAS DE LA PRIMERA PARTE QUE DECIR
        - se han ido haciendo commits en cada procedimiento y otras partes donde insertabamos datos
        - También se han manejado las excepciones y se ha hecho rollback si algo ha salido mal.

        - Respecto la practica 3 enseñar vistas V_OCUPACION_ASIGNADA, V_OCUPACION, V_VIGILANTES

4) seguridad.sql -> 

    - mostrar función de VPD 
    - Asignar usuarios a roles: en system 
    - Activación de TDE -> hecho en  seguridad.sql
    - Auditoría -> hecho en el seguridad.sql

5) usuarios.sql

    - mostrar que cada tipo de usuario con rol puede acceder a determinados elementos




Reparto:

- Chincoa:
    Parte obligatoria:
    - 1
    - 2
    - 3

- Pere:
    Parte obligatoria.
    - 4 menos PK_OCUPACION
    - 5
    - 6
    - 7
    - 8

- Mario:
    Parte opcional:
    - 2
    - 3
    - 4
- Gome
    Parte opcional:
    - 5
    Parte obligatoria:
    - 5 -> PK_OCUPACION, PR_CREA_ESTUDIANTE, PR_CREA_VOCAL
    - 9 