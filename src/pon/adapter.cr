require "./setting"

abstract class Pon::Adapter
  delegate logger, to: Pon

  def query_log(*args)
    logger.info(*args) if Pon.query_logging?
  end

  def self.databases
    @@databases ||= Hash(String, DB::Database).new
  end

  def self.database(setting : Setting) : DB::Database
    databases[setting.url] ||= build_database(setting)
  end

  # used from instances
  def self.build_database(setting) : DB::Database
    db = ::DB.open(setting.url)
    db.setup_connection do |con|
      if sql = setting.init_connect?
        Pon.logger.info("#{sql}", "init_connect") if Pon.query_logging?
        con.exec(sql)
      end
    end
    return db
  end

  def self.reset!(setting : Setting) : Nil
    if db = databases[setting.url]?
      db.close
      databases.delete(setting.url)
    end
  end
end

require "./adapter/rdb"
