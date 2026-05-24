import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

conn_str_dev = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Paradise_Dev;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

conn_str_test = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Vietinsoft_ForTest;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

def get_css_procs(conn_str, db_name):
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM sys.objects WHERE type = 'P' AND name LIKE '%MainStyle%'")
    procs = [r[0] for r in cursor.fetchall()]
    conn.close()
    return procs

try:
    print("CSS Procs in Paradise_Dev:", get_css_procs(conn_str_dev, "Paradise_Dev"))
    print("CSS Procs in Vietinsoft_ForTest:", get_css_procs(conn_str_test, "Vietinsoft_ForTest"))
    
    # Check if sp_MainStyleCSSParadise exists in Vietinsoft_ForTest
    conn_test = pyodbc.connect(conn_str_test)
    cursor_test = conn_test.cursor()
    cursor_test.execute("SELECT OBJECT_DEFINITION(OBJECT_ID('sp_MainStyleCSSParadise'))")
    defn_test = cursor_test.fetchone()[0]
    
    conn_dev = pyodbc.connect(conn_str_dev)
    cursor_dev = conn_dev.cursor()
    cursor_dev.execute("SELECT OBJECT_DEFINITION(OBJECT_ID('sp_MainStyleCSSParadise'))")
    defn_dev = cursor_dev.fetchone()[0]
    
    print("\nLength in Dev:", len(defn_dev) if defn_dev else "None")
    print("Length in Test:", len(defn_test) if defn_test else "None")
    
    # Check for another common procedure sp_MainStyleCSSParadise_v3
    cursor_test.execute("SELECT OBJECT_DEFINITION(OBJECT_ID('sp_MainStyleCSSParadise_v3'))")
    row_v3_test = cursor_test.fetchone()
    print("sp_MainStyleCSSParadise_v3 exists in Test:", row_v3_test is not None and row_v3_test[0] is not None)
    
    cursor_dev.execute("SELECT OBJECT_DEFINITION(OBJECT_ID('sp_MainStyleCSSParadise_v3'))")
    row_v3_dev = cursor_dev.fetchone()
    print("sp_MainStyleCSSParadise_v3 exists in Dev:", row_v3_dev is not None and row_v3_dev[0] is not None)
    
    conn_test.close()
    conn_dev.close()
except Exception as e:
    print("Error:", e)
