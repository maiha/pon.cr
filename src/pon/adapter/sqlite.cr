require "sqlite3"

# Sqlite implementation of the Adapter
class Pon::Adapter::Sqlite < Pon::Adapter::RDB
  URL       = "sqlite3:test.sqlite3"
  QUOTE     = '"'
  BIND_TYPE = BindType::Question
  LAST_VAL  = "SELECT LAST_INSERT_ROWID()"

  RawTypes = {
    "AUTO_Int32" => "INTEGER NOT NULL PRIMARY KEY",
    "AUTO_Int64" => "INTEGER NOT NULL PRIMARY KEY",
    "Int32"      => "INTEGER",
    "Int64"      => "INTEGER",
    "Time::Span" => "VARCHAR",
    "created_at" => "VARCHAR",
    "updated_at" => "VARCHAR",
  }
end
