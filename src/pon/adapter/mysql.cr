require "mysql"

class Pon::Adapter::Mysql < Pon::Adapter::RDB
  setting.url = "mysql://root@127.0.0.1:3306/mysql"

  QUOTING_CHAR = '`'
  BIND_TYPE    = BindType::Q
  LAST_VAL     = "SELECT LAST_INSERT_ID()"

  RawTypes = {
    "AUTO_Int32" => "INT NOT NULL AUTO_INCREMENT PRIMARY KEY",
    "AUTO_Int64" => "BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY",
    "Time::Span" => "TIME",
    "created_at" => "TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
    "updated_at" => "TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP",
  }

  def one?(id, fields : Array(String), as types : Tuple)
    where = "#{quote(@primary_name)} = ?"
    stmt  = build_select_stmt(fields: fields, where: where, limit: 1)
    query_one? stmt, id, as: types
  end
end
