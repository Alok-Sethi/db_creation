# Database usage & checks

This project contains two example scripts that create and interact with a SQLite database named `employee.db`.

Files
- `Database/db_using_sqllite.py`: simple, standalone SQLite usage (creates DB, inserts sample rows, removes duplicates, prints rows).
- `Database/db_using_sqlalchemy_fastapi.py`: SQLAlchemy + FastAPI example exposing REST endpoints to create/list/read users.

Quick requirements
- Python 3.8+
- Install dependencies from `requirements.txt` if present:

```powershell
pip install -r requirements.txt
```

1) Run the standalone SQLite script

This creates (or opens) `employee.db`, creates the `users` table, inserts sample users, removes duplicate emails, and prints the table contents.

```powershell
python Database\db_using_sqllite.py
```

After the script runs you should see console output indicating table creation, insertion, duplicate removal, and the printed rows.

2) Inspect the SQLite database file

Option A — sqlite3 CLI (if installed)

```powershell
sqlite3 employee.db
-- then inside sqlite3 shell:
PRAGMA table_info(users);
SELECT * FROM users;
.exit
```

Option B — Python quick check

```python
import sqlite3
conn = sqlite3.connect('employee.db')
cur = conn.cursor()
cur.execute('SELECT * FROM users')
print(cur.fetchall())
conn.close()
```

Option C — GUI
- Use a SQLite browser (DB Browser for SQLite, SQLiteStudio) and open `employee.db` from the project root.

3) Run the FastAPI app (SQLAlchemy)

This example uses SQLAlchemy and exposes endpoints to create and read users. It will use the same `employee.db` file (relative to where you run it).

Run with uvicorn (recommended):

```powershell
python -m uvicorn Database.db_using_sqlalchemy_fastapi:app --reload
```

Or run the file directly:

```powershell
python Database\db_using_sqlalchemy_fastapi.py
```

Endpoints (default host 0.0.0.0, port 8000)
- `POST /users` — create a user (JSON: `name`, `email`, `password`)
- `GET /users` — list users
- `GET /users/{user_id}` — get user by id
- `DELETE /users/remove-duplicates` — (example) attempts to remove duplicates (see source; its implementation may be a no-op)

Example curl (create):

```powershell
curl -X POST "http://127.0.0.1:8000/users" -H "Content-Type: application/json" -d "{\"name\":\"Alice\",\"email\":\"alice@example.com\",\"password\":\"secret\"}"
```

4) Notes & troubleshooting
- The SQLite file `employee.db` will be created in the current working directory when you run either script. If you run from the repo root, it will be `./employee.db`.
- `db_using_sqllite.py` inserts hard-coded sample rows every run; re-running will insert duplicates which the script then removes by email.
- `db_using_sqlalchemy_fastapi.py` uses `connect_args={"check_same_thread": False}` so it can work with FastAPI's threaded server.
- The delete-route `remove-duplicates` in the FastAPI file appears to contain a placeholder filter and may not remove duplicates as intended. Use a direct SQL query or the sqlite CLI to remove duplicates safely.

If you want, I can: run the scripts, run the FastAPI server, or add a safer duplicate-removal implementation. Which would you like next?
