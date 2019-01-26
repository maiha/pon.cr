require "mysql"

class Pon::Adapter::Mysql < Pon::Adapter::RDB
  SETTING = <<-TOML
    name = "mysql"

    url = "mysql://root@127.0.0.1:3306/mysql"
    init_pool_size = 1
    max_pool_size  = 5

    [query]
    show_databases = "SHOW DATABASES"
    show_tables = "SHOW TABLES"
    TOML

  QUOTE     = '`'
  BIND_TYPE = BindType::Question
  LAST_VAL  = "SELECT LAST_INSERT_ID()"

  RawTypes = {
    "AUTO_Int32" => "INT NOT NULL AUTO_INCREMENT PRIMARY KEY",
    "AUTO_Int64" => "BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY",
    "Time::Span" => "TIME",
    "created_at" => "TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
    "updated_at" => "TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP",
  }
end
