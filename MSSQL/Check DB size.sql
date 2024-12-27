DROP TABLE IF EXISTS #TableSizeInfo
 
SELECT 
    tables.[name] AS [TableName],
    schemas.[name] AS [SchemaName],
    partitions.[Rows] AS [RowsCount],
    CAST(ROUND(((SUM(allocation_units.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS [TotalSpaceMB],
    CAST(ROUND(((SUM(allocation_units.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS [UsedSpaceMB], 
    CAST(ROUND(((SUM(allocation_units.total_pages) - SUM(allocation_units.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS [UnusedSpaceMB]
INTO #TableSizeInfo
FROM sys.tables
    INNER JOIN sys.indexes ON tables.OBJECT_ID = indexes.OBJECT_ID
    INNER JOIN sys.partitions ON indexes.object_id = partitions.OBJECT_ID AND indexes.index_id = partitions.index_id
    INNER JOIN sys.allocation_units ON partitions.partition_id = allocation_units.container_id
    LEFT OUTER JOIN sys.schemas ON tables.schema_id = schemas.schema_id
WHERE tables.is_ms_shipped = 0 AND indexes.OBJECT_ID > 255 
GROUP BY tables.[name], schemas.[name], partitions.[Rows]
 
SELECT *,
    CAST(ROUND(100.0 * [RowsCount] / SUM([RowsCount]) OVER() , 2) AS NUMERIC(36, 2)) AS [RowsCount (%)],
    CAST(ROUND(100.0 * [TotalSpaceMB] / SUM([TotalSpaceMB]) OVER(), 2) AS NUMERIC(36, 2)) AS [TotalSpace (%)],
    CAST(ROUND(100.0 * [UsedSpaceMB] / SUM([UsedSpaceMB]) OVER(), 2) AS NUMERIC(36, 2)) AS [UsedSpace (%)],
    CAST(ROUND(100.0 * [UnusedSpaceMB] / SUM([UnusedSpaceMB]) OVER(), 2) AS NUMERIC(36, 2)) AS [UnusedSpace (%)]
FROM #TableSizeInfo
ORDER BY [TotalSpaceMB] DESC, [TableName]