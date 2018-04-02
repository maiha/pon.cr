# base class for crystal-db
abstract class Pon::Adapter::RDB < Pon::Adapter
  abstract def db : ::DB::Database
  abstract def logger : Logger
  abstract def one?(id, fields : Array(String), as types : Tuple)
  abstract def delete(key) : Bool

  abstract def insert(fields, params, lastval)

  abstract def exec(query : String, params = [] of String)
  abstract def count : Int32
  abstract def truncate : Nil
  abstract def delete : Nil
  abstract def scalar(clause = "")
  abstract def all(fields : Array(String), as types : Tuple, limit : Int32? = nil)

  delegate quote, to: self.class
  delegate query_one?, query_all, to: db

  enum BindType
    Q = 1                       # use question mark: '?'
    D = 2                       # use dollar mark: '$1', '$2', ...
  end

  QUOTING_CHAR = '"'
  BIND_TYPE    = BindType::Q
  LAST_VAL     = "SELECT LAST_INSERT_ROWID()"

  RawTypes = {
    "Bool"    => "BOOL",
    "Float32" => "FLOAT",
    "Float64" => "REAL",
    "Int32"   => "INT",
    "Int64"   => "BIGINT",
    "String"  => "VARCHAR(255)",
    "Time"    => "TIMESTAMP",
  }

  # Use macro in order to resolve subclass constants.
  macro inherited
    @quoted_table_name : String

    getter db : ::DB::Database

    def initialize(klass, @table_name : String, @primary_name : String, @setting : Setting? = nil)
      @quoted_table_name = quote(@table_name)
      @db = ::DB.open(setting("url"))
    end

    # NOTE: all "?" appeared in query part will be replaced when params exist
    def exec(query : String, params = [] of String)
      query = underlying_prepared(query) if params.any?
      logger.info "#{query}: #{params}"
      db.exec query, params
    end

    def count : Int32
      scalar("SELECT COUNT(*) FROM #{@quoted_table_name}").to_s.to_i32
    end

    def truncate : Nil
      exec "TRUNCATE #{@quoted_table_name}"
    end

    def update(table_name, primary_name, fields, params)
      stmt = String.build do |s|
        s << "UPDATE #{@quoted_table_name} SET "
        s << fields.map { |name| "#{quote(name)} = ?" }.join(", ")
        s << " WHERE #{quote(primary_name)} = ?"
      end
      exec stmt, params
    end

    def delete : Nil
      exec "DELETE FROM #{@quoted_table_name}"
    end

    def delete(value) : Nil
      stmt = "DELETE FROM #{@quoted_table_name} WHERE #{quote(@primary_name)} = ?"
      exec stmt, [value]
    end
    
    def insert(fields, params, lastval)
      stmt = build_insert_stmt(fields)
      exec stmt, params
      if lastval
        return scalar(LAST_VAL).as(Int64)
      else
        return -1_i64
      end
    end
    
    def scalar(clause = "")
      db.scalar(clause)
    end

    def all(fields : Array(String), as types : Tuple, limit : Int32? = nil)
      stmt = build_select_stmt(fields: fields, limit: limit)
      query_all stmt, as: types
    end
    
    protected def build_select_stmt(fields : Array(String), where : String? = nil, limit : Int32? = nil)
      String.build do |s|
        s << "SELECT "
        s << fields.map { |name| "#{@quoted_table_name}.#{quote(name)}" }.join(", ")
        s << " FROM #{@quoted_table_name}"
        s << " WHERE #{where}" if where
        s << " LIMIT #{limit}" if limit
      end
    end

    protected def build_insert_stmt(fields : Array(String))
      String.build do |s|
        s << "INSERT INTO #{@quoted_table_name} ("
        s << fields.map { |name| "#{quote(name)}" }.join(", ")
        s << ") VALUES ("
        s << fields.map { |name| "?" }.join(", ")
        s << ")"
      end
    end
    
    protected def underlying_prepared(stmt : String) : String
      case BIND_TYPE
      when .q?
        return stmt
      when .d?
        bind_pos = 0
        logger.debug "UNDERLYING PREPARED(#{BIND_TYPE}): #{stmt}"
        converted = stmt.gsub(/\?/){ bind_pos += 1; "$#{bind_pos}" }
        logger.debug "=> #{converted}"
        return converted
      else
        raise Pon::Error.new("Unsupported bind type: #{BIND_TYPE}")
      end
    end
    
    # ensures the value is quoted with idempotency
    # returns the value itself when it already contains `QUOTING_CHAR`
    # ```crystal
    # quote("foo")       # => "`foo`"
    # quote("`foo`")     # => "`foo`"
    # quote("`foo`.bar") # => "`foo`.bar"
    # ```
    def self.quote(name : String) : String
      char = QUOTING_CHAR
      if name.includes?(char)
        return name
      else
        return char + name + char
      end
    end

    # escapes the value by `QUOTING_CHAR`
    def self.escape(name : String) : String
      char = QUOTING_CHAR
      char + name.gsub(char, "#{char}#{char}") + char
    end

    # converts the crystal class to database type of this adapter
    def self.raw_type?(key : String)
      RawTypes[key]? || Pon::Adapter::RDB::RawTypes[key]?
    end

    def self.setting
      @@setting ||= Setting.new
    end

    private def setting(key : String)
      setting = @setting || self.class.setting
      setting[key]? || raise ArgumentError.new("#{self.class}.setting.#{key} not found")
    end
  end
end
