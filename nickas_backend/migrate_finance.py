import sqlite3
import datetime

# Database connection
db_path = "sql_app.db"
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

def table_exists(table_name):
    cursor.execute(f"SELECT count(name) FROM sqlite_master WHERE type='table' AND name='{table_name}'")
    return cursor.fetchone()[0] == 1

try:
    # 1. Create Categories Table
    if not table_exists("categories"):
        print("Creating categories table...")
        cursor.execute('''
            CREATE TABLE categories (
                id VARCHAR PRIMARY KEY,
                name VARCHAR,
                color VARCHAR,
                icon VARCHAR,
                user_id INTEGER,
                is_deleted BOOLEAN DEFAULT 0,
                last_synced DATETIME,
                FOREIGN KEY(user_id) REFERENCES users(id)
            )
        ''')
        cursor.execute("CREATE INDEX ix_categories_id ON categories (id)")
    else:
        print("Categories table already exists.")

    # 2. Create Transactions Table
    if not table_exists("transactions"):
        print("Creating transactions table...")
        cursor.execute('''
            CREATE TABLE transactions (
                id VARCHAR PRIMARY KEY,
                description VARCHAR,
                amount FLOAT,
                date DATETIME,
                type VARCHAR,
                category_id VARCHAR,
                user_id INTEGER,
                is_deleted BOOLEAN DEFAULT 0,
                last_synced DATETIME,
                FOREIGN KEY(user_id) REFERENCES users(id),
                FOREIGN KEY(category_id) REFERENCES categories(id)
            )
        ''')
        cursor.execute("CREATE INDEX ix_transactions_id ON transactions (id)")
    else:
        print("Transactions table already exists.")

    conn.commit()
    print("Finance migration completed successfully.")

except Exception as e:
    print(f"Migration failed: {e}")
    conn.rollback()
finally:
    conn.close()
