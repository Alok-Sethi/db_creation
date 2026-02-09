import sqlite3

conn = sqlite3.connect('employee.db')

cursor = conn.cursor()

# create table
command = """CREATE TABLE IF NOT EXISTS users (  
id INTEGER PRIMARY KEY AUTOINCREMENT,
name TEXT,
email TEXT,
password TEXT
)
"""
cursor.execute(command)
print("Table created successfully")

# insert data
cursor.execute("INSERT INTO users (name, email, password) VALUES ('Alok Sethi', 'aloksethi2004@gmail.com', 'password1')")
cursor.execute("INSERT INTO users (name, email, password) VALUES ('Akshatha Pai', 'akshathap@example.com', 'password2')")
cursor.execute("INSERT INTO users (name, email, password) VALUES ('Adyansh RajAS', 'adyanshr@example.com', 'password3')")
cursor.execute("INSERT INTO users (name, email, password) VALUES ('Dhruba Charan Sethi', 'dhrubas@example.com', 'password4')")
cursor.execute("INSERT INTO users (name, email, password) VALUES ('Premalata Sethi', 'premalatas@example.com', 'password5')")
cursor.execute("INSERT INTO users (name, email, password) VALUES ('Minati Sethi', 'minatis@example.com', 'password6')")
cursor.execute("INSERT INTO users (name, email, password) VALUES ('Swarna Sethi', 'swarnas@example.com', 'password7')")
print("Data inserted successfully")

# delete duplicates from table
cursor.execute("DELETE FROM users WHERE id NOT IN (SELECT MIN(id) FROM users GROUP BY email)")
print("Duplicates deleted successfully")

# read data
cursor.execute("SELECT * FROM users")
data = cursor.fetchall()
for row in data:
    print(row)

conn.commit()
conn.close()




