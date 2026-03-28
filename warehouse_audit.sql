-- ============================================================
-- SNOWFLAKE COST AUDIT — WAREHOUSE ANALYSIS
-- stealthstrategist.co
-- ============================================================
-- Requires: ACCOUNTADMIN or access to SNOWFLAKE.ACCOUNT_USAGE
-- Run these in order. Start with Query 1.
-- ============================================================


-- ============================================================
-- QUERY 1: Top warehouses by credit spend (last 30 days)
-- This is your first stop. The top result is almost always
-- where your money is going.
-- ============================================================

SELECT
    WAREHOUSE_NAME,
    SUM(CREDITS_USED)                          AS total_credits,
    SUM(CREDITS_USED) * 3                      AS estimated_cost_usd,
    COUNT(DISTINCT DATE(START_TIME))            AS active_days,
    ROUND(SUM(CREDITS_USED) / 
        NULLIF(COUNT(DISTINCT DATE(START_TIME)), 0), 2) AS avg_credits_per_day
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE START_TIME >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())
GROUP BY WAREHOUSE_NAME
ORDER BY total_credits DESC;


-- ============================================================
-- QUERY 2: Warehouse sizing check
-- Compares warehouse size to actual query complexity.
-- X-LARGE running simple queries = money on fire.
-- ============================================================

SELECT
    WAREHOUSE_NAME,
    WAREHOUSE_SIZE,
    COUNT(*)                                    AS query_count,
    ROUND(AVG(EXECUTION_TIME) / 1000, 2)       AS avg_execution_seconds,
    ROUND(AVG(BYTES_SCANNED) / 1073741824, 2)  AS avg_gb_scanned,
    ROUND(AVG(CREDITS_USED_CLOUD_SERVICES), 4) AS avg_credits_per_query
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE START_TIME >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())
    AND WAREHOUSE_SIZE IS NOT NULL
    AND EXECUTION_STATUS = 'SUCCESS'
GROUP BY WAREHOUSE_NAME, WAREHOUSE_SIZE
ORDER BY avg_gb_scanned ASC, WAREHOUSE_SIZE DESC;


-- ============================================================
-- QUERY 3: Auto-suspend idle time analysis
-- Shows how long each warehouse sits idle before suspending.
-- High idle time = credits burning for nothing.
-- ============================================================

SELECT
    WAREHOUSE_NAME,
    WAREHOUSE_SIZE,
    COUNT(*)                                        AS sessions,
    ROUND(AVG(
        DATEDIFF('second', START_TIME, END_TIME)
    ) / 60, 1)                                     AS avg_session_minutes,
    ROUND(SUM(CREDITS_USED), 2)                    AS total_credits,
    ROUND(SUM(CREDITS_USED) * 3, 2)               AS estimated_cost_usd
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE START_TIME >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())
GROUP BY WAREHOUSE_NAME, WAREHOUSE_SIZE
ORDER BY avg_session_minutes DESC;


-- ============================================================
-- QUERY 4: Most expensive queries (last 30 days)
-- Finds the individual queries burning the most credits.
-- These are your optimization targets.
-- ============================================================

SELECT
    QUERY_ID,
    QUERY_TEXT,
    WAREHOUSE_NAME,
    WAREHOUSE_SIZE,
    USER_NAME,
    ROUND(EXECUTION_TIME / 1000, 1)             AS execution_seconds,
    ROUND(BYTES_SCANNED / 1073741824, 2)        AS gb_scanned,
    ROUND(CREDITS_USED_CLOUD_SERVICES, 6)       AS credits_used,
    START_TIME
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE START_TIME >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())
    AND EXECUTION_STATUS = 'SUCCESS'
    AND CREDITS_USED_CLOUD_SERVICES > 0
ORDER BY CREDITS_USED_CLOUD_SERVICES DESC
LIMIT 25;


-- ============================================================
-- QUERY 5: Storage cost breakdown
-- Time travel and failsafe storage often explode silently.
-- ============================================================

SELECT
    TABLE_CATALOG                               AS database_name,
    TABLE_SCHEMA                                AS schema_name,
    TABLE_NAME,
    ROUND(ACTIVE_BYTES / 1073741824, 2)         AS active_gb,
    ROUND(TIME_TRAVEL_BYTES / 1073741824, 2)    AS time_travel_gb,
    ROUND(FAILSAFE_BYTES / 1073741824, 2)       AS failsafe_gb,
    ROUND((ACTIVE_BYTES + TIME_TRAVEL_BYTES + 
        FAILSAFE_BYTES) / 1073741824, 2)        AS total_gb
FROM SNOWFLAKE.ACCOUNT_USAGE.TABLE_STORAGE_METRICS
WHERE DELETED = FALSE
    AND (TIME_TRAVEL_BYTES + FAILSAFE_BYTES) > 1073741824
ORDER BY total_gb DESC
LIMIT 50;


-- ============================================================
-- QUERY 6: Users generating the most spend
-- Useful for governance — identifies which teams or 
-- individuals are driving cost without awareness.
-- ============================================================

SELECT
    USER_NAME,
    COUNT(*)                                    AS query_count,
    ROUND(SUM(CREDITS_USED_CLOUD_SERVICES), 4) AS total_credits,
    ROUND(AVG(EXECUTION_TIME) / 1000, 2)       AS avg_execution_seconds,
    ROUND(AVG(BYTES_SCANNED) / 1073741824, 2)  AS avg_gb_scanned
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE START_TIME >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())
    AND EXECUTION_STATUS = 'SUCCESS'
GROUP BY USER_NAME
ORDER BY total_credits DESC
LIMIT 20;
