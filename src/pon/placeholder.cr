class Pon::Placeholder
  @template : String
  @current  : String
  var defined_params : Set(String)
  var unbound_params : Set(String)

  PARAM_REGEX = /{{([a-z0-9_]+)}}/

  class ParamError < Exception
  end

  def initialize(@template)
    @current = strip_comments(@template).strip
    @defined_params = scan_params
    @unbound_params = defined_params.dup
  end
  
  def bind(**params) : Placeholder
    params.each do |key, val|
      bind(key.to_s, val.to_s)
    end
    return self
  end

  def bind(key : String, val : String) : Placeholder
    defined_params.includes?(key) || abort "unknown param: '#{key}'"
    unbound_params.includes?(key) || abort "already bound: '#{key}'"
    @current = @current.gsub(/{{#{key}}}/, val)
    unbound_params.delete(key)
    return self
  end

  def build : String
    unbound_params.any? && abort "missing params: %s" % unbound_params.inspect
    @current
  end

  def sql : String
    build
  end

  private def scan_params : Set(String)
    params = Set(String).new
    @current.scan(PARAM_REGEX) do
      params << $1
    end
    return params
  end

  private def strip_comments(s : String)
    s.gsub(/^-- .*?$/m, "")
  end

  private def abort(msg : String)
    raise ParamError.new(msg)
  end
end
