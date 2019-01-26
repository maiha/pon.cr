module Pon::Finder
  macro included
    {% all_tuple = { ALL_FIELDS.values.map{|h| h[:type].stringify + "?"}.join(",").id } %}
    def self.count
      adapter.count
    end

    def self.all(where : String? = nil, limit : Int32? = nil)
      adapter.all(fields: field_names, as: {{ all_tuple }}, where: where, limit: limit).map{|t| new(t)}
    end

    def self.where(condition : String, limit : Int32? = nil)
      all(where: condition, limit: limit)
    end

    def self.first?
      adapter.all(fields: field_names, limit: 1, as: {{ all_tuple }}).map{|t| new(t)}.first?
    end

    def self.first
      first? || raise Pon::RecordNotFound.new("{{@type}}.first")
    end

    def self.find(id : {{PRIMARY[:type]}})
      find?(id) || raise Pon::RecordNotFound.new("Couldn't find {{@type}} with '#{ {{@type}}.primary_name }'=#{id}")
    end

    def self.find?(id : {{PRIMARY[:type]}}) : {{@type}}?
      if tuple = adapter.one?(id, fields: field_names, as: {{ all_tuple }})
        new(tuple)
      else
        nil
      end
    end
  end
end
