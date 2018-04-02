module Pon::Dsl
  macro included
    macro inherited
      SETTINGS       = {} of Nil => Nil
      PRIMARY        = {name: id, type: Int64, auto: true}
      CONTENT_FIELDS = {} of Int32 => HashLiteral(Symbol, ASTNode)
      ALL_FIELDS     = {} of Int32 => HashLiteral(Symbol, ASTNode)
    end
  end

  # specify the primary key column and type
  macro primary(decl)
    {% PRIMARY[:name] = decl.var %}
    {% PRIMARY[:type] = decl.type %}
  end

  # specify the primary key column and type and auto_increment
  macro primary(decl, auto)
    {% PRIMARY[:name] = decl.var %}
    {% PRIMARY[:type] = decl.type %}
    {% PRIMARY[:auto] = auto %}
  end
  
  macro table_name(name)
    {% SETTINGS[:table_name] = name.id %}
  end
 
  ######################################################################
  ### Adapter
  macro adapter(name) # => set adapter_name
    def self.adapter
      @@adapter ||= ::Pon::Adapter::{{name.stringify.capitalize.id}}.new(self, table_name, primary_name)
    end
  end

  macro field(decl)
    {% CONTENT_FIELDS[decl.var] = {name: decl.var, type: decl.type} %}
  end

  macro _finish_dsl
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
   
    alias Types = {{ (ALL_FIELDS.values.map{|h| h[:type].stringify} + ["Nil"]).sort.join("|").id }}

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

    ######################################################################
    ### Model.new(tuple)

    # called from `DB#query_all`
    # ```
    # db.query_all "select a,b from ...", as: {a: String, b: Int32}
    # ```
    def self.new(tuple : Tuple)
      obj = new
      obj.set_attributes(tuple)
      return obj
    end
    
    def set_attributes(tuple : Tuple)
      {% i = 0 %}
      {% for name, h in ALL_FIELDS %}
        self.{{name.id}} = tuple[{{i}}]
        {% i = i + 1 %}
      {% end %}
    end
  end
end
