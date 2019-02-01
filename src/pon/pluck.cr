module Pon::Pluck
  macro included
    {% db_tuple = { ALL_FIELDS.values.map{|h| h[:db].stringify + "?"}.join(",").id } %}

    def self.pluck(fields : Array(String), **opts)
      # fields      : ["name", "code"]
      # field_names : ["id", "name", "code"]

      masked = field_names.map{|name| fields.includes?(name) ? name : nil}
      # => [nil, "name", "code"]
      indexes = masked.map_with_index{|v,i| v ? i : nil}.compact
      # => [1, 2]

      adapter.all(masked, {{db_tuple}}, **opts).map{|tuple|
        # => {nil, "foo", 200}
        row = indexes.map{|i| tuple[i]}
        # => ["foo", 200]
        row.map_with_index{|value, i| db_deserialize(fields[i], value)}
        # => ["foo", Code::OK]
      }
    end
  end
end
