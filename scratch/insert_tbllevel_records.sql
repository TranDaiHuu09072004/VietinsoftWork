-- T-SQL Script to merge levels from 1.0 to 10.0 into tbllevel
-- Range: LevelID 1 to 91, LevelRate 1.0 to 10.0

WITH LevelCTE AS (
    SELECT 
        1 AS LevelID,
        CAST('Gb1' AS NVARCHAR(50)) AS LevelName,
        CAST('Gb1' AS NVARCHAR(50)) AS LevelNameEN,
        CAST(1.0 AS DECIMAL(10, 4)) AS LevelRate
    UNION ALL
    SELECT 
        LevelID + 1,
        CAST('Gb' + CAST(LevelID + 1 AS NVARCHAR(10)) AS NVARCHAR(50)) AS LevelName,
        CAST('Gb' + CAST(LevelID + 1 AS NVARCHAR(10)) AS NVARCHAR(50)) AS LevelNameEN,
        CAST(LevelRate + 0.1 AS DECIMAL(10, 4)) AS LevelRate
    FROM LevelCTE
    WHERE LevelID < 91
)
MERGE INTO tbllevel AS target
USING LevelCTE AS source
ON target.LevelID = source.LevelID
WHEN MATCHED THEN
    UPDATE SET 
        target.LevelName = source.LevelName,
        target.LevelNameEN = source.LevelNameEN,
        target.LevelRate = source.LevelRate
WHEN NOT MATCHED THEN
    INSERT (LevelID, LevelName, LevelNameEN, Note, LevelRate)
    VALUES (source.LevelID, source.LevelName, source.LevelNameEN, NULL, source.LevelRate)
OPTION (MAXRECURSION 100);
