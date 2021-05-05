require "./setting"

abstract class Pon::Adapter
  def query_log(sql, group)
    Pon.info(sql, group) if Pon.query_logging?
  end

  def self.databases
    @@databases ||= Hash(String, DB::Database).new
  end

  def self.settings
    @@settings ||= Hash(String, Setting).new
  end

  def self.database(setting : Setting) : DB::Database
    databases[setting.url] ||= build_database(setting)
  end

  # used from instances
  def self.build_database(setting) : DB::Database
    settings[setting.url] = setting

    uri = URI.parse(setting.url)
    params = uri.query_params
    if v = setting.init_pool_size?
      params["initial_pool_size"]  = v.to_s
    end
    if v = setting.max_pool_size?
      params["max_pool_size"]  = v.to_s
    end
    uri.query = params.to_s

    db = ::DB.open(uri.to_s)
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
      databases.delete(setting.url)
      db.close
    end
  end

  def self.reset! : Nil
    settings.values.each do |setting|
      reset!(setting)
    end
  end
end

require "./adapter/rdb"
