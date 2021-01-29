require "./context"
require "./placeholder"

abstract class Pon::Query
  def self.database
    raise "adapter is not set"
  end

  macro inherited
    FIELDS = {} of Int32 => HashLiteral(Symbol, ASTNode)

    macro finished
      _finish_dsl
    end
  end

  ######################################################################
  ### Adapter
  macro adapter(name) # => set adapter_name
    def self.database
      setting = ::Pon::Adapter::{{name.stringify.capitalize.id}}.setting
      ::Pon::Adapter.database(setting)
    end
  end
  
  ######################################################################
  ### SQL (partial sql string that starts with 'from' part)
  macro from(buf)
    FROM_SQL = {{buf}}
  end
  
  ######################################################################
  ### Field

  macro field(name)
    {% if name.is_a?(TypeDeclaration) %}
      {% FIELDS[name.var] = {name: name.var, type: name.type, sql: name.value || name.var} %}
    {% else %}
      {% raise "Pon::Query.field doesn't support " + name.class_name %}
    {% end %}
  end

  macro _finish_dsl
    # Create the properties
    {% for name, h in FIELDS %}
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
          raise ::Pon::ValueNotFound.new({{@type.name.stringify}} + "#" + {{name.stringify}} + " is nil")
        end
        @{{name.id}}.not_nil!
      end
    {% end %}
   
    alias Types = {{ (FIELDS.values.map{|h| h[:type].stringify} + ["Nil"]).sort.join("|").id }}

    ResultTypes = { {{ FIELDS.values.map{|h| h[:type].stringify}.join(",").id }} }

    FIELD_NAMES = {{ FIELDS.values.map{|h| h[:name].stringify} }}
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
      {% for name, h in FIELDS %}
        when "{{name.id}}"
          {{h[:type]}}
      {% end %}
      else
        raise ArgumentError.new("#{self}.type_for expects field name, but got: #{field.inspect}")
      end
       {% end %}
    end

    TO_SQL = String.build do |s|
      s.puts "SELECT"
      {% for name, h in FIELDS %}
        s << %|  {{h[:sql].id}} AS "{{name}}"|
        {% if name == FIELDS.values.map{|h| h[:name].stringify}.last %}
          s.puts ""
        {% else %}
          s.puts ","
        {% end %}
      {% end %}
      s.puts FROM_SQL
    end
    
    def self.to_sql : String
      TO_SQL
    end

    def self.context : ::Pon::Context
      ::Pon::Context({{@type}}).new(database, ::Pon::Placeholder.new(to_sql))
    end

    def self.defined_params
      context.placeholder.defined_params
    end
    
    def self.unbound_params
      context.placeholder.unbound_params
    end
    
    def self.from_sql(result : DB::ResultSet) : Hash(String, Types)
      hash = Hash.new(String, Types)
      {% for name, h in FIELDS %}
        hash["{{name.id}}"] = result.read(Union({{h[:type].id}} | Nil))
      {% end %}
      return hash
    end      

    def set_attributes(args : Hash) : {{@type}}
      @new_record = true
      {% for name, h in FIELDS %}
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
      {% for name, h in FIELDS %}
        self.{{name.id}} = result.read(Union({{h[:type].id}} | Nil))
      {% end %}
      return self
    end

    def [](field : String)
      {% for name, h in FIELDS %}
        return self.{{name}} if "{{name}}" == field
      {% end %}
      raise ArgumentError.new("#{self.class}#['#{field}']: invalid field name")
    end

    def []?(field : String)
      {% for name, h in FIELDS %}
        return self.{{name}}? if "{{name}}" == field
      {% end %}
      raise ArgumentError.new("#{self.class}#['#{field}']: invalid field name")
    end

    def []=(field : String, value : Nil)
      {% for name, h in FIELDS %}
        return self.{{name}} = nil if "{{name}}" == field
      {% end %}
      raise ArgumentError.new("#{self.class}#['#{field}']: invalid field name")
    end

    def []=(field : String, value)
      {% for name, h in FIELDS %}
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
      {% for name, h in FIELDS %}
        self.{{name.id}} = tuple[{{i}}]
        {% i = i + 1 %}
      {% end %}
    end

    ### Conversions

    def to_h
      {
        {% for name, h in FIELDS %}
          "{{name}}" => {{name}}?,
        {% end %}
      }
    end
    
    def to_csv
      CSV.build do |csv|
        csv.row to_h.values
      end.strip
    end

  end
end
