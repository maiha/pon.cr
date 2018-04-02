require "pg"

# PostgreSQL implementation of the Adapter
class Pon::Adapter::Pg < Pon::Adapter::RDB
  setting.url = "postgres://postgres:@127.0.0.1:5432/postgres"

  module Schema
    QUOTING_CHAR = '"'
    TYPES = {
      "AUTO_Int32" => "SERIAL PRIMARY KEY",
      "AUTO_Int64" => "BIGSERIAL PRIMARY KEY",
      "Time::Span" => "TIME",
      "created_at" => "TIMESTAMP",
      "updated_at" => "TIMESTAMP",
    }
  end  

  def one?(id, fields : Array(String), as types : Tuple)
    where = "#{quote(@primary_name)} = $1"
    stmt  = build_select_stmt(fields: fields, where: where, limit: 1)
    query_one? stmt, id, as: types
  end
  
  # select_one is used by the find method.
  def select_one(table_name, fields, field, id, &block)
    statement = String.build do |stmt|
      stmt << "SELECT "
      stmt << fields.map { |name| "#{quote(table_name)}.#{quote(name)}" }.join(", ")
      stmt << " FROM #{quote(table_name)}"
      stmt << " WHERE #{quote(field)}=$1 LIMIT 1"
    end

    log statement, id

    open do |db|
      db.query_one? statement, id do |rs|
        yield rs
      end
    end
  end

  def insert(table_name, fields, params, lastval)
    statement = String.build do |stmt|
      stmt << "INSERT INTO #{quote(table_name)} ("
      stmt << fields.map { |name| "#{quote(name)}" }.join(", ")
      stmt << ") VALUES ("
      stmt << fields.map { |name| "$#{fields.index(name).not_nil! + 1}" }.join(", ")
      stmt << ")"
    end

    exec statement, params
    if lastval
      return scalar(last_val()).as(Int64)
    else
      return -1_i64
    end
  end

  private def last_val
    return "SELECT LASTVAL()"
  end

  # This will update a row in the database.
  def update(table_name, primary_name, fields, params)
    statement = String.build do |stmt|
      stmt << "UPDATE #{quote(table_name)} SET "
      stmt << fields.map { |name| "#{quote(name)}=$#{fields.index(name).not_nil! + 1}" }.join(", ")
      stmt << " WHERE #{quote(primary_name)}=$#{fields.size + 1}"
    end

    exec statement, params
  end

  def delete(value) : Nil
    stmt = "DELETE FROM #{@quoted_table_name} WHERE #{quote(primary_name)}=$1"
    exec stmt, value
  end

  private def _ensure_clause_template(clause)
    if clause.includes?("?")
      num_subs = clause.count("?")

      num_subs.times do |i|
        clause = clause.sub("?", "$#{i + 1}")
      end
    end

    clause
  end
end
