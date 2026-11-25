-- Run this script in SQLYog (local dev) and promote to Aiven (test & prod)
-- Creates unified read-only views across your 5 staging tables

-- 1. Unified view across all 5 staging tables
CREATE OR REPLACE VIEW v_all_transactions AS
SELECT transaction_id, account_id, transaction_date, transaction_type, amount, branch_id, load_ts, 'CSV' AS source_format FROM stg_csv
UNION ALL
SELECT transaction_id, account_id, transaction_date, transaction_type, amount, branch_id, load_ts, 'JSON' AS source_format FROM stg_json
UNION ALL
SELECT transaction_id, account_id, transaction_date, transaction_type, amount, branch_id, load_ts, 'PDF' AS source_format FROM stg_pdf
UNION ALL
SELECT transaction_id, account_id, transaction_date, transaction_type, amount, branch_id, load_ts, 'TXT' AS source_format FROM stg_txt
UNION ALL
SELECT transaction_id, account_id, transaction_date, transaction_type, amount, branch_id, load_ts, 'XLSX' AS source_format FROM stg_xlsx;

-- 2. Account balance summary view
CREATE OR REPLACE VIEW v_account_summary AS
SELECT 
    account_id,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN UPPER(transaction_type) = 'CREDIT' THEN amount ELSE 0 END) AS total_credits,
    SUM(CASE WHEN UPPER(transaction_type) = 'DEBIT' THEN amount ELSE 0 END) AS total_debits,
    SUM(CASE WHEN UPPER(transaction_type) = 'CREDIT' THEN amount ELSE -amount END) AS net_balance,
    MAX(transaction_date) AS last_transaction_date
FROM v_all_transactions
GROUP BY account_id;

-- 3. Branch daily summary view
CREATE OR REPLACE VIEW v_branch_daily_summary AS
SELECT 
    branch_id,
    transaction_date,
    COUNT(*) AS transaction_count,
    SUM(CASE WHEN UPPER(transaction_type) = 'CREDIT' THEN amount ELSE 0 END) AS total_credit,
    SUM(CASE WHEN UPPER(transaction_type) = 'DEBIT' THEN amount ELSE 0 END) AS total_debit,
    SUM(amount) AS total_volume
FROM v_all_transactions
GROUP BY branch_id, transaction_date
ORDER BY transaction_date DESC, branch_id ASC;
