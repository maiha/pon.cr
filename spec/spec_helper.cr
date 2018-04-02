require "spec"
require "../src/pon"

Pon::Adapter::Mysql::DEFAULT.url = ENV["MYSQL_URL"]
Pon.logger = Logger.new(File.open("spec.log", "w+"))

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
