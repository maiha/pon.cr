require "./setting"

abstract class Pon::Adapter
  delegate logger, to: Pon
end

require "./adapter/rdb"
