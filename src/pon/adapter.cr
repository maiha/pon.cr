require "./setting"

abstract class Pon::Adapter
  def query_log(sql, group)
    Pon.info(sql, group) if Pon.query_logging?
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
        Pon.info("#{sql}", "init_connect") if Pon.query_logging?
        con.exec(sql)
      end
    end
    return db
  rescue err : DB::ConnectionRefused
    raise DB::ConnectionRefused.new(setting.url.to_s)
  end

  def self.reset!(setting : Setting) : Nil
    if db = databases[setting.url]?
      db.close
      databases.delete(setting.url)
    end
  end
end

require "./adapter/rdb"
