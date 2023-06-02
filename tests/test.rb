require 'duckdb'

DuckDB::Database.open do |db|
  db.connect do |con|
    con.query('CREATE TABLE users (id INTEGER, name VARCHAR(30))')

    con.query("INSERT into users VALUES(1, 'Alice')")
    con.query("INSERT into users VALUES(2, 'Bob')")
    con.query("INSERT into users VALUES(3, 'Cathy')")

    result = con.query('SELECT * from users')
    result.each do |row|
      p row
    end
  end
end
