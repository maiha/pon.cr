require "sqlite3"

# Sqlite implementation of the Adapter
class Pon::Adapter::Sqlite < Pon::Adapter::RDB
  SETTING = <<-TOML
    url            = "sqlite3:test.sqlite3"
    init_pool_size = 1
    max_pool_size  = 5
    init_connect   = "PRAGMA read_uncommitted = true;"
    TOML

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
