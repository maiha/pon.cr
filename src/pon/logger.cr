module Pon
  @@logger : Logger = Logger.new(nil)

  def self.logger
    @@logger
  end

  def self.logger=(v)
    @@logger = v
  end
end
