import sqlite3
import datetime

# Database connection
db_path = "sql_app.db"
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

def add_column_if_not_exists(table, column, definition):
    try:
        cursor.execute(f"ALTER TABLE {table} ADD COLUMN {column} {definition}")
        print(f"Added column {column} to {table}")
    except sqlite3.OperationalError as e:
        if "duplicate column name" in str(e):
            print(f"Column {column} already exists in {table}")
        else:
            raise e

try:
    # 1. Add columns
    # We add them as nullable first to avoid issues with existing rows
    add_column_if_not_exists("users", "username", "VARCHAR")
    add_column_if_not_exists("users", "date_of_birth", "DATETIME")

    # 2. Backfill existing users
    cursor.execute("SELECT id FROM users WHERE username IS NULL OR date_of_birth IS NULL")
    users = cursor.fetchall()

    for user in users:
        user_id = user[0]
        default_username = f"Username{user_id}"
        # Default date 2000-01-01
        default_dob = "2000-01-01 00:00:00.000000" 
        
        print(f"Updating user {user_id} with username={default_username} and dob={default_dob}")
        
        cursor.execute(
            "UPDATE users SET username = ?, date_of_birth = ? WHERE id = ?",
            (default_username, default_dob, user_id)
        )

    conn.commit()
    print("Migration completed successfully.")

except Exception as e:
    print(f"Migration failed: {e}")
    conn.rollback()
finally:
    conn.close()
