module Pon::Cast
  def cast(value : Nil, type)
    value
  end

  def cast(value, type : Int32.class)
    case value
    when Int32 ; value.as(Int32)
    when Int64 ; value.to_i32
    when String; value.to_i32(strict: false)
    else       ;  raise ArgumentError.new("cast error: #{type} <= '#{value}'")
    end
  end

  def cast(value, type : Int64.class)
    case value
    when Int32 ; value.as(Int32).to_i64
    when Int64 ; value.to_i64
    when String; value.to_i64(strict: false)
    else       ;  raise ArgumentError.new("cast error: #{type} <= '#{value}'")
    end
  end

  def cast(value, type : String.class)
    value.to_s
  end

  def cast(value, type : Time::Span.class)
    case value.to_s
    when ""
      return nil
    when /^(\d{2}):(\d{2}):(\d{2})/
      Time::Span.new($1.to_i, $2.to_i, $3.to_i)
    else
      raise "cannot cast '#{value}' to Time::Span"
    end
  end

  extend self
end
