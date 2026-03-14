import sqlite3
import os

db_path = 'vault.db'
if not os.path.exists(db_path):
    print(f"Error: {db_path} not found")
else:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute("SELECT id, name, type, description FROM secrets")
    rows = cursor.fetchall()
    print(f"Total secrets: {len(rows)}")
    for row in rows:
        print(f"ID: {row[0]}, Name: '{row[1]}', Type: {row[2]}, Description: {row[3]}")
    conn.close()
