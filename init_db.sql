-- Crear base de datos si no existe
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'Data')
BEGIN
    CREATE DATABASE Data;
END;
GO

-- Cambiar al contexto de la base de datos 'Data'
USE Data;
GO

-- Eliminar las tablas dependientes primero
DROP TABLE IF EXISTS Responde;
DROP TABLE IF EXISTS Comenta;
DROP TABLE IF EXISTS ProfesorGrupo;
DROP TABLE IF EXISTS GrupoMateria;
DROP TABLE IF EXISTS GrupoClasifClase;
DROP TABLE IF EXISTS Usuario;
DROP TABLE IF EXISTS Grupo;
DROP TABLE IF EXISTS Permisos;
DROP TABLE IF EXISTS Materia;
DROP TABLE IF EXISTS Profesor;
DROP TABLE IF EXISTS Departamento;
DROP TABLE IF EXISTS PeriodoEscolar;
DROP TABLE IF EXISTS Pregunta;
DROP TABLE IF EXISTS Alumno;
GO

-- Crear tablas

CREATE TABLE Departamento (
  idDepartamento INT NOT NULL IDENTITY(1,1),
  nombreDepartamento VARCHAR(50) NOT NULL,
  PRIMARY KEY (idDepartamento)
);

CREATE TABLE PeriodoEscolar (
  idPeriodo INT NOT NULL IDENTITY(1,1),
  fecha DATE NOT NULL,
  PRIMARY KEY (idPeriodo)
);

CREATE TABLE Materia (
  clave INT NOT NULL,
  nombre VARCHAR(50) NOT NULL,
  idDepartamento INT NOT NULL,
  PRIMARY KEY (clave),
  FOREIGN KEY (idDepartamento) REFERENCES Departamento(idDepartamento)
);

CREATE TABLE Profesor (
  matricula VARCHAR(10) NOT NULL,  
  nombre VARCHAR(20) NOT NULL,
  apellidoPaterno VARCHAR(30) NOT NULL,
  apellidoMaterno VARCHAR(30) NOT NULL,
  rol VARCHAR(20) NOT NULL,
  idDepartamento INT NOT NULL,
  PRIMARY KEY (matricula),
  FOREIGN KEY (idDepartamento) REFERENCES Departamento(idDepartamento)
);

CREATE TABLE Alumno (
  matricula VARCHAR(7) NOT NULL,
  nombre VARCHAR(30) NOT NULL,
  apellidoPaterno VARCHAR(30) NOT NULL,
  apellidoMaterno VARCHAR(30) NOT NULL,
  matricula_Responde INT NULL,
  PRIMARY KEY (matricula)
);

CREATE TABLE Pregunta (
  idPregunta INT NOT NULL IDENTITY(1,1),
  pregunta VARCHAR(60) NOT NULL,
  PRIMARY KEY (idPregunta)
);

CREATE TABLE Grupo (
  CRN INT NOT NULL, 
  idPeriodo INT NOT NULL,
  clave INT NOT NULL,
  grupo VARCHAR(10) NULL,
  PRIMARY KEY (CRN),
  FOREIGN KEY (idPeriodo) REFERENCES PeriodoEscolar(idPeriodo),
  FOREIGN KEY (clave) REFERENCES Materia(clave)
);

CREATE TABLE Responde (
  matricula VARCHAR(7) NOT NULL,
  idPregunta INT NOT NULL,
  CRN INT NOT NULL,
  respuesta VARCHAR(MAX) NULL,
  PRIMARY KEY (matricula, idPregunta, CRN),
  FOREIGN KEY (matricula) REFERENCES Alumno(matricula),
  FOREIGN KEY (idPregunta) REFERENCES Pregunta(idPregunta),
  FOREIGN KEY (CRN) REFERENCES Grupo(CRN)
);

CREATE TABLE Comenta (
  idPregunta INT NOT NULL,
  matricula VARCHAR(7) NOT NULL,
  CRN INT NOT NULL,
  comentario VARCHAR(MAX) NULL,
  PRIMARY KEY (idPregunta, matricula, CRN),
  FOREIGN KEY (idPregunta) REFERENCES Pregunta(idPregunta),
  FOREIGN KEY (matricula) REFERENCES Alumno(matricula),
  FOREIGN KEY (CRN) REFERENCES Grupo(CRN)
);

CREATE TABLE ProfesorGrupo (
  CRN INT NOT NULL,
  matricula VARCHAR(10) NOT NULL,
  PRIMARY KEY (CRN, matricula),
  FOREIGN KEY (CRN) REFERENCES Grupo(CRN),
  FOREIGN KEY (matricula) REFERENCES Profesor(matricula)
);

CREATE TABLE Permisos (
  idPermisos INT NOT NULL IDENTITY(1,1),
  rol VARCHAR(20) NOT NULL,
  PRIMARY KEY (idPermisos)
);

CREATE TABLE GrupoClasifClase (
  CRN INT NOT NULL,
  clasifClase VARCHAR(30) NOT NULL,
  PRIMARY KEY (CRN, clasifClase),
  FOREIGN KEY (CRN) REFERENCES Grupo(CRN)
);

CREATE TABLE Usuario (
  matricula VARCHAR(10) NOT NULL PRIMARY KEY,
  passwordHash VARBINARY(64) NOT NULL,
  FOREIGN KEY (matricula) REFERENCES Profesor(matricula)
);
GO

-- Insertar datos de prueba

INSERT INTO Departamento (nombreDepartamento) VALUES
('Ciencias Comp.'),
('Matemáticas'),
('Física');

INSERT INTO Materia (clave, nombre, idDepartamento) VALUES
(101, 'Álgebra', 2),
(202, 'Estructuras de Datos', 1),
(303, 'Mecánica', 3);

INSERT INTO Profesor (matricula, nombre, apellidoPaterno, apellidoMaterno, rol, idDepartamento) VALUES
('A01', 'Carlos', 'López', 'Martínez', 'Administrador', 1),
('A02', 'Ana', 'González', 'Ruiz', 'Coordinador', 2),
('A03', 'Luis', 'Fernández', 'Soto', 'Director', 3);

INSERT INTO PeriodoEscolar (fecha) VALUES
('2024-01-01'),
('2024-08-01');

INSERT INTO Grupo (CRN, idPeriodo, clave, grupo) VALUES
(1001, 1, 101, '1A'),
(1002, 1, 202, '2A'),
(1003, 2, 303, '1B');

INSERT INTO Alumno (matricula, nombre, apellidoPaterno, apellidoMaterno, matricula_Responde) VALUES
('A001', 'Juan', 'Pérez', 'Sánchez', NULL),
('A002', 'María', 'Ramírez', 'López', NULL),
('A003', 'Pedro', 'Díaz', 'Torres', NULL);

INSERT INTO Pregunta (pregunta) VALUES
('¿Te gusta la materia?'),
('¿Cómo calificarías al profesor?');

INSERT INTO ProfesorGrupo (CRN, matricula) VALUES
(1001, 'A01'),
(1002, 'A02'),
(1003, 'A03');

INSERT INTO Responde (matricula, idPregunta, CRN, respuesta) VALUES
('A001', 1, 1001, 'Sí'),
('A002', 2, 1002, 'Regular');

INSERT INTO Comenta (idPregunta, matricula, CRN, comentario) VALUES
(1, 'A001', 1001, 'Me gusta la materia'),
(2, 'A002', 1002, 'El profesor explica bien');

INSERT INTO Permisos (rol) VALUES
('Administrador'),
('Director'),
('Coordinador'),
('Profesor');

INSERT INTO GrupoClasifClase (CRN, clasifClase) VALUES
(1001, 'Teoría'),
(1002, 'Laboratorio'),
(1003, 'Teoría');

INSERT INTO Usuario (matricula, passwordHash) VALUES
('A01', HASHBYTES('SHA2_256', CONVERT(VARCHAR, 'Renata'))),
('A02', HASHBYTES('SHA2_256', CONVERT(VARCHAR, 'Renlo'))),
('A03', HASHBYTES('SHA2_256', CONVERT(VARCHAR, 'Dania')));