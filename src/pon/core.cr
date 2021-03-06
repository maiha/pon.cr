module Pon::Core
  macro included
    {% primary_name = PRIMARY[:name] %}
    {% primary_type = PRIMARY[:type] %}
    {% primary_auto = PRIMARY[:auto] %}

    delegate log_query, to: self.class.adapter
    
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
        Wordsmith::Inflector.tableize({{ @type.name.id.stringify }}).gsub("/","_")
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
    ### Conversions

    def to_h
      {
        {% for name, h in ALL_FIELDS %}
          "{{name}}" => {{name}}?,
        {% end %}
      }
    end

    ######################################################################
    ### to_s

    def self.to_s(io : IO)
      # => "Job(id: Int32, name: String, time: Time::Span)"
      io << "#{name}("
      io << {{ ALL_FIELDS.map{|n,h| "#{n}: #{h[:type]}"}.join(", ") }}
      io << ")"
    end

    def to_s(io : IO)
      # => "#<Job id: 1, name: "foo", time: nil>"
      io << "#<#{self.class.name} "
      io << "{{primary_name}}: %s" % {{primary_name}}?.inspect
      {% for name, h in CONTENT_FIELDS %}
        io << ", {{name}}: %s" % {{name}}?.inspect
      {% end %}
      io << ">"
    end
  end
end
