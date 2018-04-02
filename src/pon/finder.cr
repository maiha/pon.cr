module Pon::Finder
  macro included
    {% all_tuple = { ALL_FIELDS.values.map{|h| h[:type].stringify + "?"}.join(",").id } %}
    def self.count
      adapter.count
    end

    def self.all
      adapter.all(fields: field_names, as: {{ all_tuple }}).map{|t| new(t)}
    end

    def self.find(id : {{PRIMARY[:type]}})
      find?(id) || raise Pon::RecordNotFound.new("Couldn't find {{@type}} with '#{ {{@type}}.primary_name }'=#{id}")
    end

    def self.find?(id : {{PRIMARY[:type]}}) : {{@type}}?
      if tuple = adapter.one?(id, fields: field_names, as: { {{ ALL_FIELDS.values.map{|h| h[:type].stringify + "?"}.join(",").id }} })
        new(tuple)
      else
        nil
      end
    end
  end
end
