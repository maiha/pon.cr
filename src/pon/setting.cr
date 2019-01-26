class Pon::Setting < TOML::Config
  ######################################################################
  ### fields

  str name
  
  str url
  int init_pool_size
  int max_pool_size

  str init_connect

  str "query/show_databases"
  str "query/show_tables"
  
  ######################################################################
  ### default

  var default : Setting

  def [](key)
    key = key.to_s
    @paths.fetch(key) { default? ? default[key] : not_found(key) }
  end

  def []?(key)
    key = key.to_s
    @paths.fetch(key) { default? ? default[key]? : nil }
  end

  ######################################################################
  ### core

  def self.new
    new(TOML.parse(""))
  end

  private def not_found(key)
    clue = self.name? || "Setting"
    raise NotFound.new("setting not found: %s[%s]" % [clue, key])
  end
end
