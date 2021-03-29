module Pon::Finder
  macro included
    {% db_tuple = { ALL_FIELDS.values.map{|h| h[:db].stringify + "?"}.join(",").id } %}

    def self.count
      adapter.count
    end

    def self.__todo__all(fields : Array(String?), types : Tuple, query_string : String? = nil, **opts)
      adapter.all(fields, types, query_string, **opts).map{|tuple|
        __partial_loading__ do |obj|
          tuple.each_with_index do |raw, i|
            field = fields[i]
            if FIELD_NAMES_SET.includes?(field)
              obj[field] = db_deserialize(field, raw)
            else
              # TODO: add "extra_attributes" to hold any db results
              obj.extra_attributes[field] = value
            end
          end
        end
      }
    end

    def self.all(fields : Array(String?), query_string : String? = nil, **opts)
      masked  = field_names.map{|name| fields.includes?(name) ? name : nil}
      indexes = masked.map_with_index{|v,i| v ? i : nil}.compact

      adapter.all(masked, {{db_tuple}}, query_string, **opts).map{|tuple|
        __partial_loading__ do |obj|
          indexes.each do |i|
            field = field_names[i]
            value = db_deserialize(field, tuple[i])
            obj[field] = value
          end
        end
      }
    end

    def self.all(query_string : String? = nil, **opts)
      adapter.all(field_names, {{ db_tuple }}, query_string, **opts).map{|t| new(t)}
    end

    # TODO: condition with parameters
    # def self.all(condition : String, params : Array(Types), **opts)
    #   condition = build_condition(condition, param)
    #   all(condition, **opts)
    # end

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
