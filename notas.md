- Añadir excepciones a todos los procedimientos y funciones
- Arreglar asistencia aleatoria en rellena_asistencia no funciona

- Falta poner los procedimientos y la entrega.sql todo bien en el archivo PEVAU.sql para la entrega y en el que reune todo.



DUDAS

- COMO DAR ROLES A USUARIOS SEGUN SU DNI


# TODO
- hay que darle create session a cada usuario y vocal que creamos para que se puedan conectar


# Presentacion

1) system.sql

- Tener ejecutado system con todo y en la presentacion mostrar solo los selects con usuarios, tablespaces ...
    - Aqui mostramos con los selects que se han creado los dos tablespaces

2) ddl.sql
- Mostrar script de creación con campos encriptados (telefono)

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


    - PARTE EXTRA
        - Rellenar materia, asistencia, vigilancia -> ejecutar

    - MAS COSAS DE LA PRIMERA PARTE QUE DECIR
        - se han ido haciendo commits en cada procedimiento y otras partes donde insertabamos datos
        - También se han manejado las excepciones y se ha hecho rollback si algo ha salido mal.

4) seguridad.sql

