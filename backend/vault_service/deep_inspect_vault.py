import sqlite3
import os

db_path = 'vault.db'
if not os.path.exists(db_path):
    print(f"Error: {db_path} not found")
else:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute("SELECT id, name, type FROM secrets")
    rows = cursor.fetchall()
    print(f"Total secrets: {len(rows)}")
    for row in rows:
        name = row[1]
        name_hex = name.encode('utf-8').hex()
        print(f"ID: {row[0]}, Name: '{name}', Hex: {name_hex}, Type: {row[2]}")
    conn.close()
