# base class for crystal-db
abstract class Pon::Adapter::DB(T) < Pon::Adapter
  abstract def db : ::DB::Database
  abstract def logger : Logger

  delegate quoted_table_name, to: T

  module Schema
    TYPES = {
      "Bool"    => "BOOL",
      "Float32" => "FLOAT",
      "Float64" => "REAL",
      "Int32"   => "INT",
      "Int64"   => "BIGINT",
      "String"  => "VARCHAR(255)",
      "Time"    => "TIMESTAMP",
    }
  end

  def exec(query : String, params = [] of String)
    logger.info "#{query}: #{params}"
    db.exec query, params
  end

  def count(table_name : String) : Int32
    quoted_table_name = quote(table_name)
    scalar("SELECT COUNT(*) FROM #{quoted_table_name}").to_s.to_i32
  end

  def scalar(clause = "")
    db.scalar(clause)
  end

  # Use macro in order to read a constant defined in each subclasses.
  macro inherited
    getter db : ::DB::Database

    def initialize(setting : Setting? = nil)
      setting ||= DEFAULT
      @db = ::DB.open(setting.url)
    end

    # quotes table and column names
    def self.quote(name : String) : String
      char = Schema::QUOTING_CHAR
      char + name.gsub(char, "#{char}#{char}") + char
    end

    def quote(name : String) : String
      self.class.quote(name)
    end

    # converts the crystal class to database type of this adapter
    def self.schema_type?(key : String)
      Schema::TYPES[key]? || Pon::Adapter::DB::Schema::TYPES[key]?
    end
  end
end
