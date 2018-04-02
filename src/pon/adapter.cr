require "./setting"

abstract class Pon::Adapter
  Adapters = Hash(String, Adapter.class).new

  def self.[](name) : Adapter.class
    Adapters[name]? || raise ArgumentError.new("Adapter not found: '#{name}'")
  end

  delegate logger, to: Pon
end

require "./adapter/rdb"
