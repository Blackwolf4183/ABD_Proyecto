-- Generado por Oracle SQL Developer Data Modeler 22.2.0.165.1149
--   en:        2023-02-19 10:38:30 CET
--   sitio:      Oracle Database 11g
--   tipo:      Oracle Database 11g



-- predefined type, no DDL - MDSYS.SDO_GEOMETRY

-- predefined type, no DDL - XMLTYPE

CREATE TABLE ane (
    dni        VARCHAR2(9) NOT NULL,
    descabezar CHAR(1),
    aulaaparte CHAR(1)
);

ALTER TABLE ane ADD CONSTRAINT ane_pk PRIMARY KEY ( dni ) USING INDEX TABLESPACE TS_INDICES;

CREATE TABLE asistencia (
    asiste              CHAR(1),
    entrega             CHAR(1),
    estudiante_dni      VARCHAR2(9) NOT NULL,
    materia_codigo      VARCHAR2(50) NOT NULL,
    examen_fechayhora   DATE NOT NULL,
    examen_aula_codigo  VARCHAR2(50) NOT NULL,
    examen_sede_codigo VARCHAR2(50) NOT NULL
);

ALTER TABLE asistencia
    ADD CONSTRAINT asistencia_pk PRIMARY KEY ( estudiante_dni,
                                               materia_codigo,
                                               examen_fechayhora,
                                               examen_aula_codigo,
                                               examen_sede_codigo ) USING INDEX TABLESPACE TS_INDICES;

CREATE TABLE aula (
    codigo           VARCHAR2(50) NOT NULL,
    capacidad        INTEGER NOT NULL,
    capacidad_examen INTEGER NOT NULL,
    descripcion      VARCHAR2(200),
    sede_codigo      VARCHAR2(50) NOT NULL
);

ALTER TABLE aula ADD CONSTRAINT aula_pk PRIMARY KEY ( codigo,
                                                      sede_codigo ) USING INDEX TABLESPACE TS_INDICES;

CREATE TABLE centro (
    codigo      VARCHAR2(50) NOT NULL,
    nombre      VARCHAR2(150) NOT NULL,
    direccion   VARCHAR2(50),
    poblacion   VARCHAR2(25),
    sede_codigo VARCHAR2(50) NOT NULL
);

ALTER TABLE centro ADD CONSTRAINT centro_pk PRIMARY KEY ( codigo ) USING INDEX TABLESPACE TS_INDICES;

CREATE TABLE estudiante (
    dni           VARCHAR2(9) NOT NULL,
    nombre        VARCHAR2(20) NOT NULL,
    apellidos     VARCHAR2(25) NOT NULL,
    telefono      VARCHAR2(15) NOT NULL,
    correo        VARCHAR2(50),
    centro_codigo VARCHAR2(50) NOT NULL
);

ALTER TABLE estudiante ADD CONSTRAINT estudiante_pk PRIMARY KEY ( dni ) USING INDEX TABLESPACE TS_INDICES;

CREATE TABLE examen (
    fechayhora       DATE NOT NULL,
    aula_codigo      VARCHAR2(50) NOT NULL,
    aula_sede_codigo VARCHAR2(50) NOT NULL
);

ALTER TABLE examen
    ADD CONSTRAINT examen_pk PRIMARY KEY ( fechayhora,
                                           aula_codigo,
                                           aula_sede_codigo ) USING INDEX TABLESPACE TS_INDICES;

CREATE TABLE materia (
    codigo VARCHAR2(50) NOT NULL,
    nombre VARCHAR2(50) NOT NULL
);

ALTER TABLE materia ADD CONSTRAINT materia_pk PRIMARY KEY ( codigo ) USING INDEX TABLESPACE TS_INDICES;


-- TODO: esto hay que cambiarlo a MATRICULA
CREATE TABLE matricula (
    estudiante_dni VARCHAR2(9) NOT NULL,
    materia_codigo VARCHAR2(50) NOT NULL
);

ALTER TABLE matricula ADD CONSTRAINT matricula_pk PRIMARY KEY ( estudiante_dni,
                                                                    materia_codigo ) USING INDEX TABLESPACE TS_INDICES;

CREATE TABLE vigilancia (
    vocal_dni           VARCHAR2(9) NOT NULL,
    examen_fechayhora   DATE NOT NULL,
    examen_aula_codigo  VARCHAR2(50) NOT NULL,
    examen_sede_codigo VARCHAR2(50) NOT NULL
);

ALTER TABLE vigilancia
    ADD CONSTRAINT vigilancia_pk PRIMARY KEY ( vocal_dni,
                                                examen_fechayhora,
                                                examen_aula_codigo,
                                                examen_sede_codigo ) USING INDEX TABLESPACE TS_INDICES;

CREATE TABLE materia_examen (
    examen_fechayhora   DATE NOT NULL,
    examen_aula_codigo  VARCHAR2(50) NOT NULL,
    examen_sede_codigo VARCHAR2(50) NOT NULL,
    materia_codigo      VARCHAR2(50) NOT NULL
);

ALTER TABLE materia_examen
    ADD CONSTRAINT materia_examen_pk PRIMARY KEY ( examen_fechayhora,
                                                examen_aula_codigo,
                                                examen_sede_codigo,
                                                materia_codigo ) USING INDEX TABLESPACE TS_INDICES;

CREATE TABLE sede (
    codigo     VARCHAR2(50) NOT NULL,
    nombre     VARCHAR2(150) NOT NULL,
    tipo       VARCHAR2(25),
    vocal_dni  VARCHAR2(9) NOT NULL,
    vocal_dni1 VARCHAR2(9) NOT NULL
);

CREATE UNIQUE INDEX sede__idx ON
    sede (
        vocal_dni
    ASC ) TABLESPACE TS_INDICES;

CREATE UNIQUE INDEX sede__idxv1 ON
    sede (
        vocal_dni1
    ASC ) TABLESPACE TS_INDICES;

ALTER TABLE sede ADD CONSTRAINT sede_pk PRIMARY KEY ( codigo ) USING INDEX TABLESPACE TS_INDICES;

CREATE TABLE vocal (
    dni            VARCHAR2(9) NOT NULL,
    nombre         VARCHAR2(20) NOT NULL,
    apellidos      VARCHAR2(25) NOT NULL,
    tipo           VARCHAR2(20),
    cargo          VARCHAR2(20),
    materia_codigo VARCHAR2(50)
);

ALTER TABLE vocal ADD CONSTRAINT vocal_pk PRIMARY KEY ( dni ) USING INDEX TABLESPACE TS_INDICES;

ALTER TABLE ane
    ADD CONSTRAINT ane_estudiante_fk FOREIGN KEY ( dni )
        REFERENCES estudiante ( dni );

ALTER TABLE asistencia
    ADD CONSTRAINT asistencia_estudiante_fk FOREIGN KEY ( estudiante_dni )
        REFERENCES estudiante ( dni );

ALTER TABLE asistencia
    ADD CONSTRAINT asistencia_examen_fk FOREIGN KEY ( examen_fechayhora,
                                                      examen_aula_codigo,
                                                      examen_sede_codigo )
        REFERENCES examen ( fechayhora,
                            aula_codigo,
                            aula_sede_codigo );

ALTER TABLE asistencia
    ADD CONSTRAINT asistencia_materia_fk FOREIGN KEY ( materia_codigo )
        REFERENCES materia ( codigo );

ALTER TABLE aula
    ADD CONSTRAINT aula_sede_fk FOREIGN KEY ( sede_codigo )
        REFERENCES sede ( codigo );

ALTER TABLE centro
    ADD CONSTRAINT centro_sede_fk FOREIGN KEY ( sede_codigo )
        REFERENCES sede ( codigo );

ALTER TABLE estudiante
    ADD CONSTRAINT estudiante_centro_fk FOREIGN KEY ( centro_codigo )
        REFERENCES centro ( codigo );

ALTER TABLE examen
    ADD CONSTRAINT examen_aula_fk FOREIGN KEY ( aula_codigo,
                                                aula_sede_codigo )
        REFERENCES aula ( codigo,
                          sede_codigo );

ALTER TABLE matricula
    ADD CONSTRAINT matricula_estudiante_fk FOREIGN KEY ( estudiante_dni )
        REFERENCES estudiante ( dni );

ALTER TABLE matricula
    ADD CONSTRAINT matricula_materia_fk FOREIGN KEY ( materia_codigo )
        REFERENCES materia ( codigo );

ALTER TABLE vigilancia
    ADD CONSTRAINT vigilancia_examen_fk FOREIGN KEY ( examen_fechayhora,
                                                       examen_aula_codigo,
                                                       examen_sede_codigo )
        REFERENCES examen ( fechayhora,
                            aula_codigo,
                            aula_sede_codigo );

ALTER TABLE vigilancia
    ADD CONSTRAINT vigilancia_vocal_fk FOREIGN KEY ( vocal_dni )
        REFERENCES vocal ( dni );

ALTER TABLE materia_examen
    ADD CONSTRAINT materia_examen_examen_fk FOREIGN KEY ( examen_fechayhora,
                                                       examen_aula_codigo,
                                                       examen_sede_codigo )
        REFERENCES examen ( fechayhora,
                            aula_codigo,
                            aula_sede_codigo );

ALTER TABLE materia_examen
    ADD CONSTRAINT materia_examen_materia_fk FOREIGN KEY ( materia_codigo )
        REFERENCES materia ( codigo );

ALTER TABLE sede
    ADD CONSTRAINT sede_vocal_fk FOREIGN KEY ( vocal_dni )
        REFERENCES vocal ( dni );

ALTER TABLE sede
    ADD CONSTRAINT sede_vocal_fkv1 FOREIGN KEY ( vocal_dni1 )
        REFERENCES vocal ( dni );

ALTER TABLE vocal
    ADD CONSTRAINT vocal_materia_fk FOREIGN KEY ( materia_codigo )
        REFERENCES materia ( codigo );
