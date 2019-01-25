require "./setting"

abstract class Pon::Adapter
  delegate logger, to: Pon

  def query_log(*args)
    logger.info(*args) if Pon.query_logging?
  end
end

require "./adapter/rdb"
