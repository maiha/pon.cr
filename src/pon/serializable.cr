# Glue betwen Crystal data and DB data.
module Pon::Serializable
  macro included

    # converts value of the field into DBType
    def db_serialize(field : String) : DBTypes
      {% begin %}
      case field
      {% for name, type in CONTENT_FIELDS %}
        when "{{name.id}}"
          _{{name.id}} = {{name.id}}?
          {% if type.id == Time.id || type.id == Time::Span %}
            return _{{name.id}}.try(&.to_s("%F %X"))
          {% else %}
            if _{{name.id}}.is_a?(Enum)
              return _{{name.id}}.value
            else
              return _{{name.id}}
            end
          {% end %}
      {% end %}
      else
        raise ArgumentError.new("db_serialize expects field name, but got: #{field.inspect}")
      end
      {% end %}
    end

    # converts values of content_fields into Array(DBTypes)
    def db_serialize_contents : Array(DBTypes)
      values = Array(DBTypes).new
      {% for name, h in CONTENT_FIELDS %}
        values << db_serialize("{{name.id}}")
      {% end %}
      return values
    end
    
    def self.db_deserialize(field : String, value)
      Pon::Cast.cast(value, type_for(field))
    end

  end
end
