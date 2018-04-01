require "spec"
require "../src/pon"

Pon::Adapter::Mysql::DEFAULT.url = ENV["MYSQL_URL"]
