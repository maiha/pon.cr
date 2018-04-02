require "spec"
require "../src/pon"

Pon::Adapter::Mysql::DEFAULT.url = ENV["MYSQL_URL"]
Pon.logger = Logger.new(File.open("spec.log", "w+"))
