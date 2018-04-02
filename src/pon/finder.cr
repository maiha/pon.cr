module Pon::Finder
  macro included
    def self.count
      adapter.count
    end

    def self.find(id : {{PRIMARY[:type]}})
      find?(id) || raise Pon::RecordNotFound.new("Couldn't find {{@type}} with '#{ {{@type}}.primary_name }'=#{id}")
    end

    def self.find?(id : {{PRIMARY[:type]}}) : {{@type}}?
      fields = field_names
      clause = ""
      
      stmt = String.build do |s|
        s << "SELECT "
        s << fields.map { |name| "#{quote(table_name)}.#{quote(name)}" }.join(", ")
        s << " FROM #{quote(table_name)}"
        s << " WHERE #{quote(primary_name)}=? LIMIT 1"
      end

      if tuple = adapter.query_one? stmt, id, as: { {{ ALL_FIELDS.values.map{|h| h[:type].stringify + "?"}.join(",").id }} }
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
  end
end
