import pyodbc
from pathlib import Path
import sys

sys.stdout.reconfigure(encoding='utf-8')

# Load the SQL script
sql_file = Path(r"d:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\sp_MainStyleCSSParadise_v3.sql")
sql_content = sql_file.read_text(encoding="utf-8")

# Connection details for Vietinsoft_ForTest
conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Vietinsoft_ForTest;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

try:
    print("Connecting to Vietinsoft_ForTest...")
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    # We will modify the ALTER statement to CREATE OR ALTER to make it safe
    print("Modifying SQL script to use CREATE OR ALTER PROCEDURE...")
    modified_sql = sql_content.replace("ALTER   PROCEDURE [dbo].sp_MainStyleCSSParadise", "CREATE OR ALTER PROCEDURE [dbo].[sp_MainStyleCSSParadise]")
    modified_sql = modified_sql.replace("ALTER PROCEDURE [dbo].sp_MainStyleCSSParadise", "CREATE OR ALTER PROCEDURE [dbo].[sp_MainStyleCSSParadise]")
    
    print("Deploying sp_MainStyleCSSParadise...")
    cursor.execute(modified_sql)
    conn.commit()
    print("Deployment completed successfully on Vietinsoft_ForTest!")
    
    conn.close()
except Exception as e:
    print("Error:", e)
