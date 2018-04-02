require "pg"

# PostgreSQL implementation of the Adapter
class Pon::Adapter::Pg < Pon::Adapter::RDB
  setting.url = "postgres://postgres:@127.0.0.1:5432/postgres"

  QUOTING_CHAR = '"'
  BIND_TYPE    = BindType::D
  LAST_VAL     = "SELECT LASTVAL()"

  RawTypes = {
    "AUTO_Int32" => "SERIAL PRIMARY KEY",
    "AUTO_Int64" => "BIGSERIAL PRIMARY KEY",
    "Time::Span" => "TIME",
    "created_at" => "TIMESTAMP",
    "updated_at" => "TIMESTAMP",
  }

  def one?(id, fields : Array(String), as types : Tuple)
    where = "#{quote(@primary_name)} = $1"
    stmt  = build_select_stmt(fields: fields, where: where, limit: 1)
    query_one? stmt, id, as: types
  end

  def update(table_name, primary_name, fields, params)
    statement = String.build do |stmt|
      stmt << "UPDATE #{quote(table_name)} SET "
      stmt << fields.map { |name| "#{quote(name)}=$#{fields.index(name).not_nil! + 1}" }.join(", ")
      stmt << " WHERE #{quote(primary_name)}=$#{fields.size + 1}"
    end

    exec statement, params
  end
end
