import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Paradise_Dev;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

try:
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    # Check what tasks exist in general
    print("--- General Task Counts by Date ---")
    cursor.execute("""
        SELECT TOP 10 COALESCE(ActualFinishDate, ActualStartDate) AS TaskDate, COUNT(*)
        FROM tblTask_Tasks
        WHERE StatusID = 4
        GROUP BY COALESCE(ActualFinishDate, ActualStartDate)
        ORDER BY TaskDate DESC
    """)
    for row in cursor.fetchall():
        print(f"Date: {row[0]} | Count: {row[1]}")
        
    # Check if there are any approved task assignments for PointType=2
    print("\n--- Approved Tasks in 2026 ---")
    cursor.execute("""
        SELECT TOP 10 AssigneeID, COALESCE(ActualFinishDate, ActualStartDate) AS TaskDate, StandardTime, StatusID
        FROM tblTask_Tasks
        WHERE StatusID = 4 AND COALESCE(ActualFinishDate, ActualStartDate) >= '2026-01-01'
        ORDER BY TaskDate DESC
    """)
    for row in cursor.fetchall():
        print(f"AssigneeID: {row[0]} | Date: {row[1]} | StandardTime: {row[2]} | Status: {row[3]}")
        
    conn.close()
except Exception as e:
    print(f"Error: {e}")
