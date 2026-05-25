import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

# Connection details for Paradise_Dev
conn_paradise = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Paradise_Dev;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

cursor = conn_paradise.cursor()
cursor.execute("EXEC sp_decentralization @LoginID = 3, @LanguageID = 'VN', @LoginAccount = 'cuong.vu'")
row = cursor.fetchone()
if row:
    html_content = row[0]
    with open("d:\\VTS User\\Cuong.vu\\Agent work\\VietinsoftWork\\scratch\\output.html", "w", encoding="utf-8") as f:
        f.write(html_content)
    print("HTML content written to scratch/output.html successfully.")
else:
    print("No content returned.")

cursor.close()
conn_paradise.close()
