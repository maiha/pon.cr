require "spec"
require "../src/pon"

require "../src/pon/adapter/mysql"
if url = ENV["MYSQL_URL"]?
  Pon::Adapter::Mysql.setting.url = url
end

require "../src/pon/adapter/pg"
if url = ENV["PG_URL"]?
  Pon::Adapter::Pg.setting.url = url
end

require "../src/pon/adapter/sqlite"
if url = ENV["SQLITE_URL"]?
  Pon::Adapter::Sqlite.setting.url = url
end

Pon.logger = Logger.new(File.open("spec.log", "w+"))
# Pon.query_logging = false

ADAPTERS = ["mysql","pg","sqlite"]

######################################################################
### Models
{% for adapter in ADAPTERS %}
module {{adapter.upcase.id}}

  class Job < Pon::Model
    adapter {{adapter.id}}
    table_name jobs
    primary id : Int32
    field   name : String
    field   time : Time::Span
  end

end
{% end %}
