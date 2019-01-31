module Pon::Finder
  macro included
    {% db_tuple = { ALL_FIELDS.values.map{|h| h[:db].stringify + "?"}.join(",").id } %}
    def self.count
      adapter.count
    end

    def self.all(fields : Array(String), types, rest = nil, **opts)
      adapter.all(fields, types, rest, **opts)
    end

    def self.all(**opts)
      adapter.all(field_names, {{ db_tuple }}, nil, **opts).map{|t| new(t)}
    end

    def self.where(condition : String, limit : Int32? = nil)
      all(where: condition, limit: limit)
    end

    def self.first?
      all(limit: 1).first?
    end

    def self.first
      first? || raise Pon::RecordNotFound.new("{{@type}}.first")
    end

    def self.find(id : {{PRIMARY[:type]}})
      find?(id) || raise Pon::RecordNotFound.new("Couldn't find {{@type}} with '#{ {{@type}}.primary_name }'=#{id}")
    end

    def self.find?(id : {{PRIMARY[:type]}}) : {{@type}}?
      if tuple = adapter.one?(id, fields: field_names, as: {{ db_tuple }})
        new(tuple)
      else
        nil
      end
    end
  end
end
