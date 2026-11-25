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


@app.get("/health")
def health_check():
    fetch_all("SELECT 1 AS ok")
    return {
        "status": "healthy",
        "environment": os.getenv("APP_ENV", "dev").strip().upper(),
    }


@app.get("/accounts")
def get_accounts():
    return fetch_all("SELECT * FROM v_account_summary ORDER BY account_id")


@app.get("/transactions")
def get_transactions():
    return fetch_all("SELECT * FROM v_all_transactions ORDER BY txn_date DESC LIMIT 100")


@app.get("/branches")
@app.get("/branch-summary")
def get_branches():
    return fetch_all(
        "SELECT * FROM v_branch_daily_summary ORDER BY txn_date DESC, branch_code"
    )


@app.get("/audit")
@app.get("/audit-logs")
def get_audit():
    return fetch_all("SELECT * FROM ingestion_audit ORDER BY run_id DESC LIMIT 50")