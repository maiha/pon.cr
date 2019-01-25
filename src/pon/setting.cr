class Pon::Setting < TOML::Config
  def self.new
    new(TOML.parse(""))
  end

  ######################################################################
  ### fields

  str url
  int init_pool_size
  int max_pool_size

  str init_connect
  
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
end
