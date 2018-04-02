module Pon::Core
  macro included
    {% primary_name = PRIMARY[:name] %}
    {% primary_type = PRIMARY[:type] %}
    {% primary_auto = PRIMARY[:auto] %}

    ######################################################################
    ### self.primary_name
    @@primary_name = "{{primary_name}}"
    def self.primary_name
      @@primary_name
    end
    
    ######################################################################
    ### self.table_name
    @@table_name : String =
      {% if SETTINGS[:table_name] %}
        {{ SETTINGS[:table_name].stringify }}
      {% else %}
        LuckyInflector::Inflector.tableize({{ @type.name.id.stringify }}).gsub("/","_")
      {% end %}
    def self.table_name
      @@table_name
    end

    ######################################################################
    ### Quoting features

    def self.quoted_table_name
      quote(table_name)
    end

    def self.quote(v)
      adapter.quote(v)
    end

    ######################################################################
    ### Field information

    def self.field_names : Array(String)
      @@field_names ||=
        {% if ALL_FIELDS.empty? %}
           Array(String).new
        {% else %}
           {{ ALL_FIELDS.values.map(&.[:name].stringify) }}
        {% end %}
    end

    def self.content_field_names : Array(String)
      @@content_field_names ||=
        {% if CONTENT_FIELDS.empty? %}
           Array(String).new
        {% else %}
           {{ CONTENT_FIELDS.keys.map(&.stringify) }}
        {% end %}
    end

    ######################################################################
    ### current values

    def content_values
      parsed_params = [] of Types
      {% for name, type in CONTENT_FIELDS %}
        {% if type.id == Time.id %}
          parsed_params << {{name.id}}?.try(&.to_s("%F %X"))
        {% else %}
          parsed_params << {{name.id}}?
        {% end %}
      {% end %}
      return parsed_params
    end

    ######################################################################
    ### to_s

    def to_s(io : IO)
      io << "#{self.class.name}("
      if new_record?
        io << "(new record)"
      else
        io << "%s=%s" % [self.class.primary_name, {{primary_name}}?]
      end
      {% for name, type in CONTENT_FIELDS %}
        io << ",{{name}}=%s" % {{name}}?
      {% end %}
      io << ")"
    end
  end
end
