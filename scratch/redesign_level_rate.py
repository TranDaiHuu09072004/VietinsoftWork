import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

# Connection details for Paradise_Dev
conn = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Paradise_Dev;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

cursor = conn.cursor()

try:
    print("=== Step 1: Checking if LevelRate column exists ===")
    cursor.execute("""
        SELECT COUNT(*) 
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'tbllevel' AND COLUMN_NAME = 'LevelRate'
    """)
    column_exists = cursor.fetchone()[0] > 0
    
    if not column_exists:
        print("Column LevelRate does not exist. Creating column...")
        cursor.execute("ALTER TABLE tbllevel ADD LevelRate DECIMAL(10, 4) NOT NULL DEFAULT 1.0000")
        conn.commit()
        print("Column LevelRate added successfully.")
        
        print("Adding CHECK constraint...")
        cursor.execute("ALTER TABLE tbllevel ADD CONSTRAINT CK_tbllevel_LevelRate_Positive CHECK (LevelRate > 0)")
        conn.commit()
        print("Constraint CK_tbllevel_LevelRate_Positive added successfully.")
    else:
        print("Column LevelRate already exists.")

    print("\n=== Step 2: Retrieving updated table columns ===")
    cursor.execute("""
        SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE, COLUMN_DEFAULT
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = 'tbllevel'
    """)
    for r in cursor.fetchall():
        print(f"Col: {r[0]}, Type: {r[1]}, MaxLen: {r[2]}, Nullable: {r[3]}, Default: {r[4]}")

    print("\n=== Step 3: Checking records in tbllevel (before updates) ===")
    cursor.execute("SELECT * FROM tbllevel")
    cols = [col[0] for col in cursor.description]
    for r in cursor.fetchall():
        print(dict(zip(cols, r)))

    print("\n=== Step 4: Updating some LevelRates for testing ===")
    # Update LevelRates for Gb1..Gb5 to test division logic
    rates = {
        1: 1.0000,
        2: 1.1000,
        3: 1.2000,
        4: 1.3000,
        5: 1.4000
    }
    for level_id, rate in rates.items():
        cursor.execute("UPDATE tbllevel SET LevelRate = ? WHERE LevelID = ?", (rate, level_id))
    conn.commit()
    print("LevelRates updated successfully.")

    print("\n=== Step 5: Checking records in tbllevel (after updates) ===")
    cursor.execute("SELECT * FROM tbllevel")
    cols = [col[0] for col in cursor.description]
    for r in cursor.fetchall():
        print(dict(zip(cols, r)))

    print("\n=== Step 6: Testing ranking point formula with new LevelRate ===")
    test_query = """
    SELECT 
        LevelID, 
        LevelName, 
        LevelRate,
        10000.0 AS WorkCompletionXP,
        5000.0 AS OtherCriteriaXP,
        (10000.0 / LevelRate) + 5000.0 AS CalculatedRankingPoints
    FROM tbllevel
    """
    cursor.execute(test_query)
    test_cols = [col[0] for col in cursor.description]
    for r in cursor.fetchall():
        row_dict = dict(zip(test_cols, r))
        print(f"Level: {row_dict['LevelName']} (Rate: {row_dict['LevelRate']}) -> Calculated Points: {row_dict['CalculatedRankingPoints']:.2f}")

except Exception as e:
    print(f"An error occurred: {e}")
    conn.rollback()

finally:
    conn.close()
