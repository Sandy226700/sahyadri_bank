import os
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from db import connect

app = FastAPI(title="Sahyadri Digital Bank API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def fetch_all(query: str):
    conn = connect()
    try:
        with conn.cursor() as cur:
            cur.execute(query)
            columns = [desc[0] for desc in cur.description] if cur.description else []
            rows = cur.fetchall()
            return [dict(zip(columns, row)) for row in rows]
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))
    finally:
        conn.close()


def sort_by_first_available(rows: list[dict], candidate_keys: list[str], reverse: bool = True):
    if not rows:
        return rows
    for key in candidate_keys:
        if key in rows[0]:
            return sorted(rows, key=lambda r: str(r.get(key) or ""), reverse=reverse)
    return rows


@app.get("/health")
def health_check():
    fetch_all("SELECT 1 AS ok")
    return {
        "status": "healthy",
        "environment": os.getenv("APP_ENV", "dev").strip().upper(),
    }


@app.get("/accounts")
def get_accounts():
    rows = fetch_all("SELECT * FROM v_account_summary")
    return sort_by_first_available(rows, ["account_id", "account_number"], reverse=False)


@app.get("/transactions")
def get_transactions():
    rows = fetch_all("SELECT * FROM v_all_transactions LIMIT 200")
    rows = sort_by_first_available(
        rows, ["txn_date", "transaction_date", "created_at", "txn_id", "id"], reverse=True
    )
    return rows[:100]


@app.get("/branches")
@app.get("/branch-summary")
def get_branches():
    rows = fetch_all("SELECT * FROM v_branch_daily_summary")
    return sort_by_first_available(
        rows, ["txn_date", "summary_date", "date", "branch_code", "branch"], reverse=True
    )


@app.get("/audit")
@app.get("/audit-logs")
def get_audit():
    rows = fetch_all("SELECT * FROM ingestion_audit")
    rows = sort_by_first_available(
        rows, ["run_id", "audit_id", "id", "created_at", "ingested_at", "run_timestamp"], reverse=True
    )
    return rows[:50]