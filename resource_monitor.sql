-- ============================================================
-- RESOURCE MONITOR SETUP
-- stealthstrategist.co
-- ============================================================
-- Run these to set up spend caps and alerts on your warehouses.
-- Requires ACCOUNTADMIN role.
-- Replace the values in CAPS with your own.
-- ============================================================


-- ============================================================
-- STEP 1: Create an account-level monitor
-- Alerts you when total account spend hits thresholds.
-- Change CREDIT_QUOTA to your monthly credit budget.
-- ============================================================

CREATE OR REPLACE RESOURCE MONITOR ACCOUNT_MONTHLY_CAP
    WITH CREDIT_QUOTA = 500          -- set your monthly credit budget here
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS
        ON 75 PERCENT DO NOTIFY      -- email alert at 75%
        ON 90 PERCENT DO NOTIFY      -- email alert at 90%
        ON 100 PERCENT DO SUSPEND;   -- suspend all warehouses at 100%


-- ============================================================
-- STEP 2: Apply the account monitor
-- ============================================================

ALTER ACCOUNT SET RESOURCE_MONITOR = ACCOUNT_MONTHLY_CAP;


-- ============================================================
-- STEP 3: Create warehouse-level monitors
-- More granular control per warehouse.
-- Duplicate this block for each warehouse you want to cap.
-- ============================================================

-- Example: Cap your reporting warehouse at 50 credits/month
CREATE OR REPLACE RESOURCE MONITOR REPORTING_WH_CAP
    WITH CREDIT_QUOTA = 50
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS
        ON 80 PERCENT DO NOTIFY
        ON 100 PERCENT DO SUSPEND_IMMEDIATE;

-- Apply to your warehouse (replace REPORTING_WH with your warehouse name)
ALTER WAREHOUSE REPORTING_WH
    SET RESOURCE_MONITOR = REPORTING_WH_CAP;


-- ============================================================
-- STEP 4: Set auto-suspend on all warehouses
-- This is the single highest-impact change you can make.
-- 60 seconds is the right default for most warehouses.
-- ============================================================

-- Run this query first to see all your warehouses:
SHOW WAREHOUSES;

-- Then apply auto-suspend to each one:
-- Replace WAREHOUSE_NAME with each of your warehouse names.

ALTER WAREHOUSE WAREHOUSE_NAME
    SET AUTO_SUSPEND = 60           -- seconds (60 = 1 minute)
    AUTO_RESUME = TRUE;


-- ============================================================
-- STEP 5: Verify your monitors are set up correctly
-- ============================================================

SHOW RESOURCE MONITORS;
