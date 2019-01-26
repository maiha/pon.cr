require "sqlite3"

# Sqlite implementation of the Adapter
class Pon::Adapter::Sqlite < Pon::Adapter::RDB
  SETTING = <<-TOML
    name = "sqlite"

    url            = "sqlite3:test.sqlite3"
    init_pool_size = 1
    max_pool_size  = 5
    init_connect   = "PRAGMA read_uncommitted = true;"

    [query]
    show_databases = "PRAGMA database_list"
    show_tables = "SELECT name FROM sqlite_master WHERE type = 'table'"
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

  def databases : Array(String)
    query = @setting.query_show_databases
    array = query_all query, as: {Int32, String, String}
    array.map(&.[1])
  end
end
