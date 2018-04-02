require "sqlite3"

# Sqlite implementation of the Adapter
class Pon::Adapter::Sqlite < Pon::Adapter::RDB
  setting.url = "sqlite3:test.sqlite3"

  QUOTING_CHAR = '"'
  BIND_TYPE    = BindType::Q
  LAST_VAL     = "SELECT LAST_INSERT_ROWID()"

  RawTypes = {
    "AUTO_Int32" => "INTEGER NOT NULL PRIMARY KEY",
    "AUTO_Int64" => "INTEGER NOT NULL PRIMARY KEY",
    "Int32"      => "INTEGER",
    "Int64"      => "INTEGER",
    "Time::Span" => "VARCHAR",
    "created_at" => "VARCHAR",
    "updated_at" => "VARCHAR",
  }

  def one?(id, fields : Array(String), as types : Tuple)
    where = "#{quote(@primary_name)} = ?"
    stmt  = build_select_stmt(fields: fields, where: where, limit: 1)
    query_one? stmt, id, as: types
  end

  def update(table_name, primary_name, fields, params)
    statement = String.build do |stmt|
      stmt << "UPDATE #{quote(table_name)} SET "
      stmt << fields.map { |name| "#{quote(name)}=?" }.join(", ")
      stmt << " WHERE #{quote(primary_name)}=?"
    end

    exec statement, params
  end
end
