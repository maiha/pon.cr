require "spec"
require "../src/pon"

require "../src/pon/adapter/mysql"
Pon::Adapter::Mysql.setting.url = ENV["MYSQL_URL"]?

require "../src/pon/adapter/pg"
Pon::Adapter::Pg.setting.url = ENV["PG_URL"]?

require "../src/pon/adapter/sqlite"
Pon::Adapter::Sqlite.setting.url = ENV["SQLITE_URL"]?

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

  Job.migrate!
  
end
{% end %}
