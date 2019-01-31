module Pon::Aggregations
  macro included

    # `count_by_xxx` : Hash(Type, Int64)
    # MySQL returns `Int64` as record count
    
    {% for name, h in ALL_FIELDS %}
      {% clue = "count_by_xxx(#{h}):" %}
      def self.count_by_{{name}} : Hash({{h[:type]}}, Int64)

        _hash = Hash({{h[:type]}}, Int64).new
        all(["{{name}}", "COUNT(*)"], { {{h[:db]}}?, Int64? }, "GROUP BY {{name}}").each do |raw, cnt|
          raw || raise ::Pon::Bug.new({{clue}} + " raw is nil")
          cnt || raise ::Pon::Bug.new({{clue}} + " cnt is nil")

          key = ::Pon::Cast.cast(raw.not_nil!, {{h[:type]}})
          _hash[key] = cnt.not_nil!
        end
        return _hash
      end
    {% end %}

  end
end
