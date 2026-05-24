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
        
        # Search for 'calendar'
        pos = 0
        while True:
            pos = html.find('calendar', pos)
            if pos == -1:
                break
            snippet = html[max(0, pos-50):min(len(html), pos+50)].replace('\r', ' ').replace('\n', ' ')
            print(f"Found 'calendar' at index {pos}: {snippet}")
            pos += 8
            
        # Search for 'fa-calendar-days'
        pos = 0
        while True:
            pos = html.find('fa-calendar-days', pos)
            if pos == -1:
                break
            snippet = html[max(0, pos-50):min(len(html), pos+50)].replace('\r', ' ').replace('\n', ' ')
            print(f"Found 'fa-calendar-days' at index {pos}: {snippet}")
            pos += 16
    else:
        print("No rows returned.")
    conn.close()
except Exception as e:
    print("Error:", e)
