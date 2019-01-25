require "pg"

# PostgreSQL implementation of the Adapter
class Pon::Adapter::Pg < Pon::Adapter::RDB
  SETTING = <<-TOML
    url = "postgres://postgres:@127.0.0.1:5432/postgres"
    init_pool_size = 1
    max_pool_size  = 5
    TOML

  QUOTE     = '"'
  BIND_TYPE = BindType::Dollar
  LAST_VAL  = "SELECT LASTVAL()"

  RawTypes = {
    "AUTO_Int32" => "SERIAL PRIMARY KEY",
    "AUTO_Int64" => "BIGSERIAL PRIMARY KEY",
    "Time::Span" => "TIME",
    "created_at" => "TIMESTAMP",
    "updated_at" => "TIMESTAMP",
  }
end
