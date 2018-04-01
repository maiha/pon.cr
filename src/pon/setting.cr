class Pon::Setting < Hash(String, String)
  private macro named_accessor(name)
    def {{name}}
      self[{{name.stringify}}].to_s
    end

    def {{name}}=(v)
      self[{{name.stringify}}] = v
    end
  end

  named_accessor url
end
