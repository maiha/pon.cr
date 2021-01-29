require "./errors"

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

  macro field(name)
    {% if name.is_a?(TypeDeclaration) %}
      {% CONTENT_FIELDS[name.var] = {name: name.var, type: name.type, default: name.value || "nil".id} %}
    {% else %}
      {% raise "Pon::Model.field doesn't support " + name.class_name %}
    {% end %}
  end

  macro _finish_dsl
    {% primary_name = PRIMARY[:name] %}
    {% primary_type = PRIMARY[:type] %}

    # merge PK and CONTENT_FIELDS into ALL_FIELDS
    #   db: db type
    #   sp: the name of special type that differs between crystal and db
    {% ALL_FIELDS[primary_name] = {name: primary_name, type: primary_type, db: primary_type, sp: :none, default: "nil".id } %}
    {% for name, h in CONTENT_FIELDS %}
      {% typ = h[:type].resolve %}
      {% enm = (typ < Enum) %}
      {% sp  = enm ? :enum      : ( (typ == Time::Span) ? :span : :none ) %}
      {% db  = enm ? "Int32".id : ( (typ == Time::Span) ? "Time".id : h[:type] ) %}
      {% ALL_FIELDS[name] = {name: name, type: h[:type], db: db, sp: sp, default: h[:default]} %}
    {% end %}

    # Create the properties
    {% for name, h in ALL_FIELDS %}
      property? {{name}} : {{h[:type]}}?

      {% if h[:sp] == :enum %}
        def {{name.id}}=(v : Int32)
          self.{{name}} = {{h[:type]}}.from_value(v)
        end
      {% elsif h[:sp] == :span %}
        def {{name.id}}=(v : String)
          self.{{name}} = Time::Span.parse(v)
        end
      {% end %}

      def {{name.id}}
        if @{{name.id}}.nil?
          if {{h[:default]}} != nil
            return {{h[:default]}}.not_nil!
          else
            raise ::Pon::ValueNotFound.new({{@type.name.stringify}} + "#" + {{name.stringify}} + " is nil")
          end
        end
        @{{name.id}}.not_nil!
      end

      {% if h[:default] != "nil".id %}
        def {{name.id}}? : {{h[:type]}}?
          @{{name.id}} || {{h[:default]}}.not_nil!
        end
      {% end %}
    {% end %}
   
    alias Types = {{ (ALL_FIELDS.values.map{|h| h[:type].stringify} + ["Nil"]).sort.join("|").id }}
    alias DBTypes = {{ (ALL_FIELDS.values.map{|h| h[:db].stringify} + ["Nil"]).sort.join("|").id }}

    FIELD_NAMES = {{ ALL_FIELDS.values.map{|h| h[:name].stringify} }}
    FIELD_NAMES_SET = FIELD_NAMES.to_set

    def initialize(**args : Object)
      set_attributes(args.to_h)
    end

    def initialize(args : Hash)
      set_attributes(args)
    end

    def initialize
    end

    def self.type_for(field : String)
      {% begin %}
      case field
      {% for name, h in ALL_FIELDS %}
        when "{{name.id}}"
          {{h[:type]}}
      {% end %}
      else
        raise ArgumentError.new("#{self}.type_for expects field name, but got: #{field.inspect}")
      end
       {% end %}
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

    def [](field : String)
      {% for name, h in ALL_FIELDS %}
        return self.{{name}} if "{{name}}" == field
      {% end %}
      raise ArgumentError.new("#{self.class}#['#{field}']: invalid field name")
    end

    def []?(field : String)
      {% for name, h in ALL_FIELDS %}
        return self.{{name}}? if "{{name}}" == field
      {% end %}
      raise ArgumentError.new("#{self.class}#['#{field}']: invalid field name")
    end

    def []=(field : String, value : Nil)
      {% for name, h in ALL_FIELDS %}
        return self.{{name}} = nil if "{{name}}" == field
      {% end %}
      raise ArgumentError.new("#{self.class}#['#{field}']: invalid field name")
    end

    def []=(field : String, value)
      {% for name, h in ALL_FIELDS %}
        if "{{name}}" == field
          if value.nil?
            return self.{{name}} = nil
          else
            return self.{{name}} = ::Pon::Cast.cast(value.not_nil!, {{h[:type]}})
          end
        end
      {% end %}
      raise ArgumentError.new("#{self.class}#['#{field}']: invalid field name")
    end

    ######################################################################
    ### Instantiate

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
      @new_record = false
      {% i = 0 %}
      {% for name, h in ALL_FIELDS %}
        self.{{name.id}} = tuple[{{i}}]
        {% i = i + 1 %}
      {% end %}
    end

  end
end
