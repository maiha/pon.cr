module Pon::Fields
  macro included
    macro inherited
      SETTINGS       = {} of Nil => Nil
      PRIMARY        = {name: id, type: Int64}
      CONTENT_FIELDS = {} of Int32 => HashLiteral(Symbol, ASTNode)
      ALL_FIELDS     = {} of Int32 => HashLiteral(Symbol, ASTNode)
    end
  end

  macro primary(decl)
    {% PRIMARY[:name] = decl.var %}
    {% PRIMARY[:type] = decl.type %}
  end

  macro table_name(name)
    {% SETTINGS[:table_name] = name.id %}
  end
 
  ######################################################################
  ### Adapter
  macro adapter(name) # => set adapter_name
    def self.adapter
      @@adapter ||= ::Pon::Adapter::{{name.stringify.capitalize.id}}({{@type}}).new
    end
  end

  macro field(decl)
    {% CONTENT_FIELDS[decl.var] = {name: decl.var, type: decl.type} %}
  end

  macro _finish_fields
    {% primary_name = PRIMARY[:name] %}
    {% primary_type = PRIMARY[:type] %}

    # merge PK and CONTENT_FIELDS into ALL_FIELDS
    {% ALL_FIELDS[primary_name] = {name: primary_name, type: primary_type} %}
    {% for name, h in CONTENT_FIELDS %}
      {% ALL_FIELDS[name] = {name: name, type: h[:type]} %}
    {% end %}

    # Create the properties
    {% for name, h in ALL_FIELDS %}
      property? {{name}} : {{h[:type]}}?
      def {{name.id}}
        raise {{@type.name.stringify}} + "#" + {{name.stringify}} + " cannot be nil" if @{{name.id}}.nil?
        @{{name.id}}.not_nil!
      end
    {% end %}

    @@table_name : String = LuckyInflector::Inflector.tableize({{ SETTINGS[:table_name] || @type.name.id }}).gsub("/","_")
    def self.table_name
      @@table_name
    end

    alias Types = {{ (ALL_FIELDS.values.map{|h| h[:type].stringify} + ["Nil"]).sort.join("|").id }}

    @@primary_name = "{{primary_name}}"
    def self.primary_name
      @@primary_name
    end
    
    def self.quoted_table_name
      quote(table_name)
    end

    def self.quote(v)
      adapter.quote(v)
    end

    def self.field_names : Array(String)
      @@field_names ||= {{ ALL_FIELDS.values.map{|h| h[:name]} }}
    end

    def self.get?(id : {{primary_type}}) : {{@type}}?
      fields = field_names
      clause = ""
      
      stmt = String.build do |s|
        s << "SELECT "
        s << fields.map { |name| "#{quote(table_name)}.#{quote(name)}" }.join(", ")
        s << " FROM #{quote(table_name)}"
        s << " WHERE #{quote(primary_name)}=? LIMIT 1"
      end

      if tuple = adapter.db.query_one? stmt, id, as: { {{ ALL_FIELDS.values.map{|h| h[:type].stringify + "?"}.join(",").id }} }
        obj = new
        {% i = 0 %}
        {% for name, h in ALL_FIELDS %}
          obj.{{name.id}} = tuple[{{i}}]
          {% i = i + 1 %}
        {% end %}
        return obj
      else
        return nil
      end
    end

    def initialize(**args : Object)
      set_attributes(args.to_h)
    end

    def initialize(args : Hash)
      set_attributes(args)
    end

    def initialize
    end
      
    def self.from_sql(result : DB::ResultSet) : Hash(String, Types)
      hash = Hash.new(String, Types)
      {% for name, h in ALL_FIELDS %}
        hash["{{name.id}}"] = result.read(Union({{h[:type].id}} | Nil))
      {% end %}
      return hash
    end      

    def set_attributes(args : Hash) : {{@type}}
      @new_record = true
      {% for name, h in ALL_FIELDS %}
        _{{name.id}} = args["{{name}}"]? || args[:{{name.id}}]? || nil
        self.{{name.id}} = Pon::Cast.cast(_{{name.id}}, {{h[:type]}})
      {% end %}
      return self
    end

    def set_attributes(**args)
      set_attributes(args.to_h)
    end
    
    def set_attributes(result : DB::ResultSet)
      # Loading from DB means existing records.
      @new_record = false
      {% for name, h in ALL_FIELDS %}
        self.{{name.id}} = result.read(Union({{h[:type].id}} | Nil))
      {% end %}
      return self
    end
  end
end
