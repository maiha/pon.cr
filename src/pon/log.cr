module Pon
  @@query_logging : Bool = true

  def self.query_logging? : Bool
    @@query_logging
  end

  def self.query_logging=(v : Bool) : Bool
    @@query_logging = v
  end
end


{% if @type.has_constant? "Logger" %}
######################################################################
### Logger
module Pon
  @@logger : Logger = Logger.new(nil)

  def self.logger
    @@logger
  end

  def self.logger=(v)
    @@logger = v
  end

  {% for m in %w( debug info warn error falta ) %}
    def self.{{m.id}}(*args, **opts)
      logger.{{m.id}}(*args, **opts)
    end
  {% end %}
end


{% elsif @type.has_constant? "Log" %}
######################################################################
### Log
module Pon
  @@log : Log = Log.new("pon", Log::MemoryBackend.new, :warn)
  
  def self.log
    @@log
  end

  def self.log=(v : Log)
    @@log = v
  end

  {% for m in %w( debug info warn error falta ) %}
    def self.{{m.id}}(msg, group = nil)
      msg = "[#{group}] #{msg}" if !group.to_s.empty?
      log.{{m.id}} { msg }
    end
  {% end %}
end

Log.setup do |c|
  level   = Log::Severity::Info
  level   = Log::Severity::Debug if ENV["PON_DEBUG"]?
  backend = Log::IOBackend.new
  c.bind "*", level, backend
end

{% else %}
######################################################################
### no logs library found
module Pon
  {% for m in %w( debug info warn error falta ) %}
    def self.{{m.id}}(msg, group = nil)
      msg = "[#{group}] #{msg}" if !group.to_s.empty?
#      STDERR.puts msg
    end
  {% end %}
end


{% end %}
