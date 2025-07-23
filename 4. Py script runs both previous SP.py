#SCRIPT PARA CORRER AMBOS SP PARA CORTES SEMANALES
#NO HAY NECESIDAD DE INSTALAR LIBRERIA PYODBC DESDE EL PIPYA QUE SE INSTALO DESDE QUE SE ECHO A
#ANDAR CORREOS AUTOMATICOS DIARIOS E INCIDENCIAS(2023)
import pyodbc

# CREDENCIALES BD
server = 'Localhost'  
username = 'private'
password = 'private'

# Stored procedures and databases
stored_procs = [
    {'database': 'HIS_WEB', 'procedure': 'SP_CORTE_SEMANAL'},
    {'database': 'HIS_CORTES', 'procedure': 'SP_EliminarPacientesPruebaSemanal'}
]

# CONECTANDO A LA INSTANCIA DE SQL SERVER (SIN ESPECIFICAR LA BD)
for item in stored_procs:
    database = item['database']
    procedure = item['procedure']

    try:
        conn_str = (
            f'DRIVER={{ODBC Driver 17 for SQL Server}};'
            f'SERVER={server};DATABASE={database};'
            f'UID={username};PWD={password}'
        )
        with pyodbc.connect(conn_str) as conn:
            with conn.cursor() as cursor:
                print(f"EJECUTANDO {procedure} EN {database}...")
                cursor.execute(f"EXEC {procedure}")
                conn.commit()
                print(f"{procedure} EJECUTADO EXITOSAMENTE.")
    except Exception as e:
        print(f"ERROR EJECUTANDO {procedure} EN {database}: {e}")