import os
from typing import Optional
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
import pymysql
from db import connect  # Uses your existing SRC/db.py

app = FastAPI(title="Sahyadri Digital Bank API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET"],
    allow_headers=["*"],
)


def fetch_all(query: str, params: tuple = ()):
    conn = connect()
    try:
        with conn.cursor(pymysql.cursors.DictCursor) as cursor:
            cursor.execute(query, params)
            return cursor.fetchall()
    finally:
        conn.close()


@app.get("/health")
def health_check():
    """Returns active environment (dev/test/prod) and DB connectivity."""
    active_env = os.getenv("APP_ENV", "dev").upper()
    try:
        fetch_all("SELECT 1 AS ok")
        return {"status": "healthy", "environment": active_env}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"DB Connection Failed: {str(e)}")


@app.get("/accounts")
def get_account_summaries():
    """Returns aggregated credit, debit, and net balance per account."""
    sql = """
        SELECT 
            account_id,
            total_transactions,
            CAST(total_credits AS DOUBLE) AS total_credits,
            CAST(total_debits AS DOUBLE) AS total_debits,
            CAST(net_balance AS DOUBLE) AS net_balance,
            CAST(last_transaction_date AS CHAR) AS last_transaction_date
        FROM v_account_summary
        ORDER BY account_id ASC
    """
    return fetch_all(sql)


@app.get("/transactions")
def get_transactions(
    account_id: Optional[int] = Query(None),
    branch_id: Optional[int] = Query(None),
    source_format: Optional[str] = Query(None),
    limit: int = Query(100, le=500),
):
    """Returns unified transactions with optional filters."""
    conditions = ["1=1"]
    params = []

    if account_id is not None:
        conditions.append("account_id = %s")
        params.append(account_id)
    if branch_id is not None:
        conditions.append("branch_id = %s")
        params.append(branch_id)
    if source_format and source_format.upper() != "ALL":
        conditions.append("source_format = %s")
        params.append(source_format.upper())

    where_clause = " AND ".join(conditions)
    sql = f"""
        SELECT 
            transaction_id,
            account_id,
            CAST(transaction_date AS CHAR) AS transaction_date,
            transaction_type,
            CAST(amount AS DOUBLE) AS amount,
            branch_id,
            source_format
        FROM v_all_transactions
        WHERE {where_clause}
        ORDER BY transaction_date DESC, load_ts DESC
        LIMIT %s
    """
    params.append(limit)
    return fetch_all(sql, tuple(params))


@app.get("/ops/branch-summary")
def get_branch_summary():
    """Returns daily branch summary metrics."""
    sql = """
        SELECT 
            branch_id,
            CAST(transaction_date AS CHAR) AS transaction_date,
            transaction_count,
            CAST(total_credit AS DOUBLE) AS total_credit,
            CAST(total_debit AS DOUBLE) AS total_debit,
            CAST(total_volume AS DOUBLE) AS total_volume
        FROM v_branch_daily_summary
        LIMIT 100
    """
    return fetch_all(sql)


@app.get("/ops/audit")
def get_ingestion_audit(limit: int = Query(50, le=200)):
    """Returns ingestion_audit execution logs."""
    sql = """
        SELECT 
            audit_id,
            source_file,
            target_table,
            rows_read,
            rows_loaded,
            status,
            message,
            CAST(run_ts AS CHAR) AS run_ts
        FROM ingestion_audit
        ORDER BY run_ts DESC, audit_id DESC
        LIMIT %s
    """
    return fetch_all(sql, (limit,))
