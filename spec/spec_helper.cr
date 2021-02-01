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

{% if @type.has_constant? "Log" %}
  Log.setup do |c|
    level   = Log::Severity::Info
    level   = Log::Severity::Debug if ENV["PON_DEBUG"]?
    backend = Log::IOBackend.new
    c.bind "*", level, backend
  end
{% end %}

ADAPTERS = ["mysql","pg","sqlite"]

######################################################################
### Models
{% for adapter in ADAPTERS %}
module {{adapter.upcase.id}}

  enum Code
    OK  = 200
    ERR = 500
  end
  
  class Job < Pon::Model
    adapter {{adapter.id}}
    table_name jobs
    primary id : Int32
    field   name : String
    field   time : Time
    field   code : Code
  end

  Job.migrate!

  class DataTypes < Pon::Model
    adapter {{adapter.id}}
    table_name data_types
    primary id : Int32
    field   bool : Bool
  end

  DataTypes.migrate!

end
{% end %}
