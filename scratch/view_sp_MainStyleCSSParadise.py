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

try:
    conn_dev = pyodbc.connect(conn_str_dev)
    cursor_dev = conn_dev.cursor()
    cursor_dev.execute("SELECT OBJECT_DEFINITION(OBJECT_ID('sp_MainStyleCSSParadise'))")
    defn_dev = cursor_dev.fetchone()[0]
    
    conn_test = pyodbc.connect(conn_str_test)
    cursor_test = conn_test.cursor()
    cursor_test.execute("SELECT OBJECT_DEFINITION(OBJECT_ID('sp_MainStyleCSSParadise'))")
    defn_test = cursor_test.fetchone()[0]
    
    print("=== Paradise_Dev sp_MainStyleCSSParadise ===")
    print(defn_dev[:1000])
    print("... [TRUNCATED] ...")
    
    print("\n=== Vietinsoft_ForTest sp_MainStyleCSSParadise ===")
    print(defn_test[:1000])
    print("... [TRUNCATED] ...")
    
    conn_dev.close()
    conn_test.close()
except Exception as e:
    print("Error:", e)
