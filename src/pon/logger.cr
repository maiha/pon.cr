module Pon
  @@logger : Logger = Logger.new(nil)
  @@query_logging : Bool = true

  def self.logger
    @@logger
  end

  def self.logger=(v)
    @@logger = v
  end

  def self.query_logging? : Bool
    @@query_logging
  end

  def self.query_logging=(v : Bool) : Bool
    @@query_logging = v
  end
end
