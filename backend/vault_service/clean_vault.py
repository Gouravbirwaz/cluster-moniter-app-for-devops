import sqlite3
import os

db_path = 'vault.db'
if not os.path.exists(db_path):
    print(f"Error: {db_path} not found")
else:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute("DELETE FROM secrets WHERE name = '' OR name IS NULL OR TRIM(name) = ''")
    print(f"Deleted {conn.total_changes} malformed secrets.")
    conn.commit()
    conn.close()
