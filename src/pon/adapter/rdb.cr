# base class for crystal-db
abstract class Pon::Adapter::RDB < Pon::Adapter
  abstract def table_name : String
  abstract def exec(query : String, params = [] of String)
  abstract def lastval : Int64
  abstract def scalar(*args)
  abstract def transaction(&block) : Nil
  abstract def reset! : Nil

  abstract def insert(fields, params)
  abstract def all(fields : Array(String), types, rest = nil, **opts)
  abstract def one?(id, fields : Array(String), as types : Tuple)
  abstract def count : Int32
  abstract def delete(key) : Nil
  abstract def delete : Nil
  abstract def truncate : Nil

  # odbc
  abstract def databases : Array(String)
  abstract def tables : Array(String)

  delegate quote, to: self.class
  delegate query_one?, query_all, scalar, to: database

  enum BindType
    Question = 1                # "?"
    Dollar   = 2                # "$1", "$2", ...
  end

  # SETTING = "" # This should be defined in subclasses
  QUOTE     = '"'
  BIND_TYPE = BindType::Question
  LAST_VAL  = "SELECT LAST_INSERT_ROWID()"

  RawTypes = {
    "Bool"    => "BOOL",
    "Float32" => "FLOAT",
    "Float64" => "REAL",
    "Int32"   => "INT",
    "Int64"   => "BIGINT",
    "String"  => "VARCHAR(255)",
    "Time"    => "TIMESTAMP",
  }

  # Use macro in order to resolve subclass constants like `SETTING`, `QUOTE`
  macro inherited
    @qt : String                # quoted table name
    @qp : String                # quoted primary name

    getter table_name : String
    getter qt : String
    getter qp : String

    def initialize(klass, @table_name : String, @primary_name : String, @setting : ::Pon::Setting = ::Pon::Setting.new, @db : ::DB::Database? = nil)
      # bind class setting to default only if default is not set
      if @setting.default? == nil
        @setting.default = self.class.setting
      end

      @qt = quote(@table_name)
      @qp = quote(@primary_name)
    end

    # `database` abstracts unique connections and access to shared connections.
    # Querying each time accessing without caching slightly degrades performance,
    # but this mechanism is required when resetting shared connections.
    def database : ::DB::Database
      @db || Pon::Adapter.database(@setting)
    end

    def reset! : Nil
      if db = @db
        db.close
        @db = Pon::Adapter.build_database(@setting)
      else
        Pon::Adapter.reset!(@setting)
      end
    end
    
    ### ODBC
    
    def databases : Array(String)
      query = @setting.query_show_databases
      query_all query, as: String
    end

    def tables : Array(String)
      query = @setting.query_show_tables
      query_all query, as: String
    end

    # NOTE: all "?" appeared in query part will be replaced when params exist
    def exec(query : String, params = [] of String)
      query = underlying_prepared(query) if !params.empty?
      query_log "#{query}: #{params}", "exec"
      if !params.empty?
        database.exec query, args: params
      else
        database.exec query
      end
    end

    def transaction(&block) : Nil
      exec "BEGIN"
      begin
        yield
        exec "COMMIT"
      rescue
        exec "ROLLBACK"
      end
    end

    def count : Int32
      query = "SELECT COUNT(*) FROM #{@qt}"
      query_log query, "count"
      scalar(query).to_s.to_i32
    end

    def all(fields : Array(String), types, query_string = nil, **opts)
      query = select_statement(fields, query_string, **opts)
      query_log query, "all"
      query_all query, as: types
    end
    
    def all(fields : Array(String?), types, query_string = nil, **opts)
      query = select_statement(fields, query_string, **opts)
      query_log query, "all"
      query_all query, as: types
    end
    
    def one?(id, fields : Array(String), as types : Tuple)
      query = select_statement(fields, where: "#{@qp} = ?", limit: 1)
      query_log query, "one?"
      query_one? query, id, as: types
    end

    def truncate : Nil
      exec "TRUNCATE #{@qt}"
    end

    def update(fields, params)
      exec "UPDATE #{@qt} SET #{qc(fields)} WHERE #{@qp} = ?", params
    end

    def delete : Nil
      exec "DELETE FROM #{@qt}"
    end

    def delete(value) : Nil
      exec "DELETE FROM #{@qt} WHERE #{@qp} = ?", [value]
    end
    
    def insert(fields, params)
      cols = fields.map{|n| quote(n)}.join(", ")
      vals = Array.new(fields.size, "?").join(", ")
      exec "INSERT INTO #{@qt} (#{cols}) VALUES (#{vals})", params
    end

    def lastval : Int64
      scalar(LAST_VAL).as(Int64)
    end

    protected def select_statement(fields : Array(String?), rest : String? = nil, **opts)
      stmt = String.build do |s|
        s << "SELECT "
        s << fields.map { |name| quote_field(name) }.join(", ")
        s << " FROM #{@qt}"
        s << " #{rest}" if rest
        opts.each do |k, v|
          s << " #{k} #{v}" if v
        end
      end
      return underlying_prepared(stmt)
    end

    # same as `select_statement` except fill ALL_FIELD with nil if absent
    protected def pluck_statement(fields : Array(String), rest : String? = nil, **opts)
      stmt = String.build do |s|
        s << "SELECT "
        
        s << fields.map { |name| quote_field(name) }.join(", ")
        s << " FROM #{@qt}"
        s << " #{rest}" if rest
        opts.each do |k, v|
          s << " #{k} #{v}" if v
        end
      end
      return underlying_prepared(stmt)
    end

    def quote_field(name : String?) : String
      case name
      when Nil
        "NULL"
      when /^[a-z0-9_]+$/i
        "#{@qt}.#{quote(name)}"
      else
        # Nop if not match because it should be functions such as "COUNT(*)"
        name
      end
    end

    protected def underlying_prepared(stmt : String) : String
      case BIND_TYPE
      when .question?
        return stmt
      when .dollar?
        bind_pos = 0
        Pon.debug "UNDERLYING PREPARED(#{BIND_TYPE}): #{stmt}"
        converted = stmt.gsub(/\?/){ bind_pos += 1; "$#{bind_pos}" }
        Pon.debug "=> #{converted}"
        return converted
      else
        raise Pon::Error.new("Unsupported bind type: #{BIND_TYPE}")
      end
    end

    # quote columns
    private def qc(names : Array(String)) : String
      names.map { |name| "#{quote(name)} = ?" }.join(", ")
    end

    # ensures the value is quoted with idempotency
    # returns the value itself when it already contains `QUOTE`
    # ```crystal
    # quote("foo")       # => "`foo`"
    # quote("`foo`")     # => "`foo`"
    # quote("`foo`.bar") # => "`foo`.bar"
    # ```
    def self.quote(name : String) : String
      if name.includes?(QUOTE)
        return name
      else
        return QUOTE + name + QUOTE
      end
    end

    # escapes the value by `QUOTE`
    def self.escape(name : String) : String
      QUOTE + name.gsub(QUOTE, "#{QUOTE}#{QUOTE}") + QUOTE
    end

    # converts the crystal class to database type of this adapter
    def self.raw_type?(key : String)
      RawTypes[key]? || Pon::Adapter::RDB::RawTypes[key]?
    end

    def self.setting
      @@setting ||= Setting.new(TOML.parse(SETTING))
    end
  end
end
