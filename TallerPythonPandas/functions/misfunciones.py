#misfunciones.py
import os
import pandas as pd
import mysql.connector
import numpy as np
def unir_excel_en_csv(path):
   
    
    archivos = os.listdir(path)
    lista_dataframes = []
    try:
        for archivo in archivos:
            archivo_path = os.path.join(path,archivo)
            if archivo.endswith(".XLSX"):
                data = pd.read_excel(archivo_path)
                lista_dataframes.append(data)
        
        df_final = pd.concat(lista_dataframes)
        path_salida = os.path.join(path,"temporal.csv")
        df_final.to_csv(path_salida,index=False)
        return "Todo unido a csv yay jejej"
    except Exception as e:
        return f"bloody error: {e}"




def alterar_columnas(path, new_columns:list):
    new_data_path = os.path.join(path,"temporal.csv")
    try:
        df = pd.read_csv(new_data_path)
        df.columns = new_columns
        df.dropna(axis=1, how="all", inplace=True)
        df.dropna(subset=["modificado"], inplace=True)
        path_salida = os.path.join(path,"temporal.csv")
        df.to_csv(path_salida)
        return "Columnas alteradas yay jeje"
    except Exception as e:
        return f"bloody error: {e}"

def establecer_conexion(nombre_bd):
    config = {
        'user': 'root',
        'password': 'root',
        'host': '127.0.0.1',
        'database': nombre_bd,
        'port':'9090',
        'raise_on_warnings': True
    }
    conn = mysql.connector.connect(**config)
    return conn

def cargar_datos(conn, path, cols,query_sql):
    try:
        cursor = conn.cursor()
        df = pd.read_csv(path)
        df_final = df[list(cols)]
        df_final = df_final.replace({pd.NA: None, np.nan: None})
        data_to_insert = [tuple(x) for x in df_final.values]
      
        cursor.executemany(query_sql, data_to_insert)
        
        conn.commit()
        cursor.close()
        return "Success yay"
    except Exception as e:
        return f"Error: {e}"


def cantidad_por_producto(conn):
    try:
        cursor = conn.cursor()

        query = "SELECT fabricante, COUNT(*) as cantidad FROM producto GROUP BY fabricante"

        df = pd.read_sql(query,conn)

        return df
    except Exception as e:
        print( f"Error: {e}")
        return None
    

def obtener_datos_tiempo(conn):
    try:
     
        query = "SELECT modificado, COUNT(*) as conteo FROM producto GROUP BY modificado ORDER BY modificado"
        df = pd.read_sql(query, conn)
        return df
    except Exception as e:
        print(f"Error: {e}")
        return None

