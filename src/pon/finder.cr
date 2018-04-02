module Pon::Finder(T)
  macro included
    def self.count
      adapter.count(table_name)
    end

    def self.find?(id : {{PRIMARY[:type]}})
      get?(id)
    end

    def self.find(id : {{PRIMARY[:type]}})
      find?(id) || raise Pon::RecordNotFound.new("Couldn't find {{@type}} with '#{ {{@type}}.primary_name }'=#{id}")
    end
  end
end
