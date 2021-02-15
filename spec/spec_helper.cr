require "log"                   # specify log library first
require "spec"
require "../src/pon"

require "../src/pon/adapter/mysql"
Pon::Adapter::Mysql.setting.url = ENV["MYSQL_URL"]?

require "../src/pon/adapter/pg"
Pon::Adapter::Pg.setting.url = ENV["PG_URL"]?

require "../src/pon/adapter/sqlite"
Pon::Adapter::Sqlite.setting.url = ENV["SQLITE_URL"]?

Pon.query_logging = false
Pon.log.backend = Log::IOBackend.new(io: File.open("spec.log", "w+"))
Pon.log.level = :debug

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
