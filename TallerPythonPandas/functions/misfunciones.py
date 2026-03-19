#misfunciones.py
import os
import pandas as pd
import mysql.connector
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
        path_salida = os.path.join(path,"temporal_transformado.csv")
        df.to_csv(path_salida)
        return "Columnas alteradas yay jeje"
    except Exception as e:
        return f"bloody error: {e}"

def establecer_conexion():
    config = {
        'user': 'root',
        'password': 'root',
        'host': '127.0.0.1',
        'database': 'parcialDB',
        'port':'9090',
        'raise_on_warnings': True
    }
    conn = mysql.connector.connect(**config)
    return conn

        
        