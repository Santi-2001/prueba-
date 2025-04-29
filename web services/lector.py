import pymssql
import pandas as pd
from flask import Flask, request, jsonify

app = Flask(__name__)

# Función para obtener la conexión a la base de datos
def obtener_conexion():
    try:
        # Conexión a la base de datos
        conexion = pymssql.connect(
            server='scaling-broccoli-97wggq99ww972pxw6-5000.app.github.dev',  # Usando el servidor que proporcionaste
            user='sa',  # Reemplaza con el usuario correcto
            password='YourPassword123!',  # Reemplaza con la contraseña correcta
            database='Data'  # Nombre de la base de datos
        )
        return conexion
    except Exception as e:
        print(f"Error al conectar a la base de datos: {e}")
        return None

# Ruta para subir la encuesta
@app.route('/subir_encuesta', methods=['POST'])
def subir_encuesta():
    if 'file' not in request.files:
        return jsonify({'error': 'No se encontró el archivo'}), 400
    
    file = request.files['file']

    if file.filename == '':
        return jsonify({'error': 'No se seleccionó un archivo'}), 400

    if file and file.filename.endswith('.xlsx'):
        df = pd.read_excel(file, engine='openpyxl')
        data_json = df.to_dict(orient='records')

        # Obtener la conexión a la base de datos
        conexion = obtener_conexion()
        if conexion is None:
            return jsonify({'error': 'No se pudo conectar a la base de datos'}), 500
        
        cursor = conexion.cursor()

        for row in data_json:
            matricula = str(row['Matricula']).strip()
            grupo_nombre = str(row['Grupo']).strip()
            comentario = row['Comentarios']
            profesor_nombre = row['Profesor']
            clase_nombre = row['Clase']
            respuestas = {k: v for k, v in row.items() if k not in ['Matricula', 'Grupo', 'Comentarios', 'Profesor', 'Clase']}

            # 1. Insertar o verificar Alumno
            cursor.execute("SELECT matricula FROM Alumno WHERE matricula = %s", (matricula,))
            if not cursor.fetchone():
                cursor.execute("INSERT INTO Alumno (matricula, nombre, apellidoPaterno, apellidoMaterno) VALUES (%s, %s, %s, %s)", (matricula, 'Pendiente', 'Pendiente', 'Pendiente'))

            # 2. Verificar o crear Materia
            cursor.execute("SELECT clave FROM Materia WHERE nombre = %s", (clase_nombre,))
            materia = cursor.fetchone()
            if materia:
                clave_materia = materia[0]
            else:
                cursor.execute("INSERT INTO Materia (clave, nombre, idDepartamento) VALUES ((SELECT ISNULL(MAX(clave),100) + 1 FROM Materia), %s, 1)", (clase_nombre,))
                conexion.commit()
                cursor.execute("SELECT clave FROM Materia WHERE nombre = %s", (clase_nombre,))
                clave_materia = cursor.fetchone()[0]

            # 3. Verificar o crear Grupo
            cursor.execute("SELECT CRN FROM Grupo WHERE grupo = %s AND clave = %s", (grupo_nombre, clave_materia))
            grupo = cursor.fetchone()
            if grupo:
                crn = grupo[0]
            else:
                cursor.execute("INSERT INTO Grupo (idPeriodo, clave, grupo) VALUES (1, %s, %s)", (clave_materia, grupo_nombre))
                conexion.commit()
                cursor.execute("SELECT CRN FROM Grupo WHERE grupo = %s AND clave = %s", (grupo_nombre, clave_materia))
                crn = cursor.fetchone()[0]

            # 4. Verificar o crear Profesor
            apellido_paterno, nombre_profesor = profesor_nombre.split(",")
            apellido_paterno = apellido_paterno.strip()
            nombre_profesor = nombre_profesor.strip()

            cursor.execute("SELECT matricula FROM Profesor WHERE nombre = %s AND apellidoPaterno = %s", (nombre_profesor, apellido_paterno))
            profesor = cursor.fetchone()
            if profesor:
                matricula_profesor = profesor[0]
            else:
                nueva_matricula_profesor = f"P{clave_materia}{grupo_nombre}"
                cursor.execute("INSERT INTO Profesor (matricula, nombre, apellidoPaterno, apellidoMaterno, rol, idDepartamento) VALUES (%s, %s, %s, %s, %s, %s)",
                               (nueva_matricula_profesor, nombre_profesor, apellido_paterno, 'Pendiente', 'Profesor', 1))
                conexion.commit()
                matricula_profesor = nueva_matricula_profesor

            # 5. Relacionar Profesor con Grupo
            cursor.execute("SELECT * FROM ProfesorGrupo WHERE CRN = %s AND matricula = %s", (crn, matricula_profesor))
            if not cursor.fetchone():
                cursor.execute("INSERT INTO ProfesorGrupo (CRN, matricula) VALUES (%s, %s)", (crn, matricula_profesor))

            # 6. Insertar Comentario
            if comentario and not pd.isna(comentario):
                cursor.execute("""
                    IF NOT EXISTS (SELECT * FROM Comenta WHERE idPregunta = 1 AND matricula = %s AND CRN = %s)
                    BEGIN
                        INSERT INTO Comenta (idPregunta, matricula, CRN, comentario)
                        VALUES (1, %s, %s, %s)
                    END
                """, (matricula, crn, matricula, crn, comentario))

            # 7. Insertar Respuestas
            for idx, (pregunta, valor) in enumerate(respuestas.items(), start=1):
                if not pd.isna(valor):
                    cursor.execute("""
                        IF NOT EXISTS (SELECT * FROM Responde WHERE matricula = %s AND idPregunta = %s AND CRN = %s)
                        BEGIN
                            INSERT INTO Responde (matricula, idPregunta, CRN, respuesta)
                            VALUES (%s, %s, %s, %s)
                        END
                    """, (matricula, idx, crn, matricula, idx, crn, str(valor)))

        conexion.commit()
        cursor.close()
        conexion.close()

        return jsonify({'mensaje': 'Archivo procesado con éxito y registros creados si no existían'}), 200

    return jsonify({'error': 'Formato de archivo no soportado. Por favor sube un archivo .xlsx'}), 400

if __name__ == '__main__':
    app.run(debug=True)
