import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Vietinsoft_ForTest;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

try:
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    print("Executing sp_Task_ComplaintForm_html 'VN'...")
    cursor.execute("EXEC dbo.sp_Task_ComplaintForm_html 'VN'")
    row = cursor.fetchone()
    if row:
        html = row[0]
        print("Success! HTML length:", len(html) if html else 0)
        if html:
            print("Snippet (first 500 chars):")
            print(html[:500])
            print("Snippet (last 500 chars):")
            print(html[-500:])
            # Search for fa- in returned html
            pos = 0
            while True:
                pos = html.find('fa-', pos)
                if pos == -1:
                    break
                print(f"Found 'fa-' at index {pos}: {html[max(0, pos-40):min(len(html), pos+40)]}")
                pos += 3
    else:
        print("No rows returned.")
    conn.close()
except Exception as e:
    print("Error:", e)
