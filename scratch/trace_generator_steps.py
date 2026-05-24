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
    
    # 1. Get query
    cursor.execute("exec sp_Task_ComplaintForm_html")
    row = cursor.fetchone()
    html_query = row[0]
    print(f"Step 1: HTML Query length: {len(html_query) if html_query else 0}")
    
    # 2. Split string to find tokens
    cursor.execute("""
        select *
        into #temptable
        from dbo.SplitString(?, '%')
        where Items not like '% %'
    """, html_query)
    
    cursor.execute("select count(*) from #temptable")
    count_temp = cursor.fetchone()[0]
    print(f"Step 2: Split items count: {count_temp}")
    
    # Let's see some split items
    cursor.execute("select top 10 Items from #temptable")
    print("Some split items:")
    for r in cursor.fetchall():
        print(f"  {r[0]}")
        
    # 3. Message table
    cursor.execute("""
        select MessageID, Content
        into #tblMD_Message
        from dbo.tblMD_Message md
        where Language='VN' and exists (select 1 from #temptable t where md.MessageID=t.Items)
    """)
    cursor.execute("select count(*) from #tblMD_Message")
    count_msg = cursor.fetchone()[0]
    print(f"Step 3: Message items count: {count_msg}")
    
    # 4. Generate dynamic SQL
    cursor.execute("""
        select stuff((select '  UPDATE t SET html = REPLACE(html,''%''+m.MessageID+''%'',ISNULL(m.Content, m.MessageID+'':VN'')) FROM #Results t INNER JOIN #tblMD_Message m ON m.MessageID = '''+m.MessageID+''''
                      from #tblMD_Message m
                      for xml path('')), 1, 1, '')
    """)
    sql = cursor.fetchone()[0]
    print(f"Step 4: Dynamic update SQL length: {len(sql) if sql else 0}")
    if sql:
        print("Dynamic SQL preview:")
        print(sql[:300])
        
    # 5. Let's try running the update on #Results
    cursor.execute("create table #Results (html nvarchar(max))")
    cursor.execute("insert into #Results(html) values (?)", html_query)
    
    if sql:
        print("Executing dynamic SQL...")
        cursor.execute(sql)
        print("Dynamic SQL executed successfully!")
        
    cursor.execute("select html from #Results")
    final_html = cursor.fetchone()[0]
    print(f"Final HTML length: {len(final_html) if final_html else 0}")
    
    conn.close()
except Exception as e:
    print("Error:", e)
