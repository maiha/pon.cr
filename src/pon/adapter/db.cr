# base class for crystal-db
abstract class Pon::Adapter::DB < Pon::Adapter
  abstract def db : ::DB::Database
  abstract def logger : Logger

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
    scalar("SELECT COUNT(*) FROM #{quote(table_name)}").to_s.to_i32
  end

  def truncate(table_name : String) : Nil
    exec "TRUNCATE #{quote(table_name)}"
  end

  def delete(table_name : String) : Nil
    exec "DELETE FROM #{quote(table_name)}"
  end

  def scalar(clause = "")
    db.scalar(clause)
  end

  # Use macro in order to read a constant defined in each subclasses.
  macro inherited
    getter db : ::DB::Database
    delegate quote, to: self.class

    def initialize(setting : Setting? = nil)
      setting ||= DEFAULT
      @db = ::DB.open(setting.url)
    end

    # ensures the value is quoted with idempotency
    # returns the value itself when it already contains `QUOTING_CHAR`
    # ```crystal
    # quote("foo")       # => "`foo`"
    # quote("`foo`")     # => "`foo`"
    # quote("`foo`.bar") # => "`foo`.bar"
    # ```
    def self.quote(name : String) : String
      char = Schema::QUOTING_CHAR
      if name.includes?(char)
        return name
      else
        return char + name + char
      end
    end

    # escapes the value by `QUOTING_CHAR`
    def self.escape(name : String) : String
      char = Schema::QUOTING_CHAR
      char + name.gsub(char, "#{char}#{char}") + char
    end

    # converts the crystal class to database type of this adapter
    def self.schema_type?(key : String)
      Schema::TYPES[key]? || Pon::Adapter::DB::Schema::TYPES[key]?
    end
  end
end
