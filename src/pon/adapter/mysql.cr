require "mysql"

class Pon::Adapter::Mysql < Pon::Adapter::DB
  DEFAULT = Setting.new
  DEFAULT.url = "mysql://root@127.0.0.1:3306/mysql"

  module Schema
    QUOTING_CHAR = '`'
    TYPES = {
      "AUTO_Int32" => "INT NOT NULL AUTO_INCREMENT PRIMARY KEY",
      "AUTO_Int64" => "BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY",
      "Time::Span" => "TIME",
      "created_at" => "TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
      "updated_at" => "TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP",
    }
  end

  # select performs a query against a table.  The table_name and fields are
  # configured using the sql_mapping directive in your model.  The clause and
  # params is the query and params that is passed in via .all() method
  def select(table_name, fields, clause = "", params = nil, &block)
    statement = String.build do |stmt|
      stmt << "SELECT "
      stmt << fields.map { |name| "#{quote(table_name)}.#{quote(name)}" }.join(", ")
      stmt << " FROM #{quote(table_name)} #{clause}"
    end

    log statement, params

    open do |db|
      db.query statement, params do |rs|
        yield rs
      end
    end
  end

  # select_one is used by the find method.
  # it checks id by default, but one can
  # pass another field.
  def select_one(table_name, fields : Array(String), field : String, id, &block)

    # "select name, age from contacts where id = ?"
    
        # ```
    
#    log statement, id

    db.query_one?(statement, id) do |rs|
      block.call(rs)
    end
  end

  def insert(table_name, fields, params, lastval)
    statement = String.build do |stmt|
      stmt << "INSERT INTO #{quote(table_name)} ("
      stmt << fields.map { |name| "#{quote(name)}" }.join(", ")
      stmt << ") VALUES ("
      stmt << fields.map { |name| "?" }.join(", ")
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
    return "SELECT LAST_INSERT_ID()"
  end

  # This will update a row in the database.
  def update(table_name, primary_name, fields, params)
    statement = String.build do |stmt|
      stmt << "UPDATE #{quote(table_name)} SET "
      stmt << fields.map { |name| "#{quote(name)}=?" }.join(", ")
      stmt << " WHERE #{quote(primary_name)}=?"
    end

    exec statement, params
  end

  Adapters["mysql"] = self.as(Adapter.class)
end
