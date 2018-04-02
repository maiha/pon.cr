# base class for crystal-db
abstract class Pon::Adapter::DB < Pon::Adapter
  abstract def db : ::DB::Database
  abstract def logger : Logger
  abstract def one?(id, fields : Array(String), as types : Tuple)

  delegate quote, to: self.class
  delegate query_one?, query_all, to: db

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

  DEFAULT = Setting.new

  @quoted_table_name : String

  getter db : ::DB::Database

  def initialize(klass, @table_name : String, @primary_name : String, @setting : Setting? = nil)
    @quoted_table_name = quote(@table_name)
    @db = ::DB.open(setting("url"))
  end

  private def setting(key : String)
    setting = @setting || self.class.setting
    setting[key]? || raise ArgumentError.new("#{self.class}.setting.#{key} not found")
  end

  def exec(query : String, params = [] of String)
    logger.info "#{query}: #{params}"
    db.exec query, params
  end

  def count : Int32
    scalar("SELECT COUNT(*) FROM #{@quoted_table_name}").to_s.to_i32
  end

  def truncate : Nil
    exec "TRUNCATE #{@quoted_table_name}"
  end

  def delete : Nil
    exec "DELETE FROM #{@quoted_table_name}"
  end
  
  def scalar(clause = "")
    db.scalar(clause)
  end

  def all(fields : Array(String), as types : Tuple, limit : Int32? = nil)
    stmt = build_select_stmt(fields: fields, limit: limit)
    query_all stmt, as: types
  end
  
  def build_select_stmt(fields : Array(String), where : String? = nil, limit : Int32? = nil)
    stmt = String.build do |s|
      s << "SELECT "
      s << fields.map { |name| "#{@quoted_table_name}.#{quote(name)}" }.join(", ")
      s << " FROM #{@quoted_table_name}"
      s << " WHERE #{where}" if where
      s << " LIMIT #{limit}" if limit
    end
  end

  # Use macro in order to read a constant defined in each subclasses.
  macro inherited
    def self.setting
      @@setting ||= Setting.new
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
