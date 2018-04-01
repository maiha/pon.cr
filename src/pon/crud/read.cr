module Pon::Read(T, P)
  macro included
    def self.count
      adapter.count(table_name)
    end

    def self.find?(id : P)
      get?(id)
    end

    def self.find(id : P)
      find?(id) || raise Pon::RecordNotFound.new("Couldn't find {{@type}} with '#{ {{@type}}.primary_name }'=#{id}")
    end
  end
end
