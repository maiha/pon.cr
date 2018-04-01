module Pon::Validations(T, P)
  macro included
    getter errors : Array(Pon::Error) = Array(Pon::Error).new

    def valid?
      # TODO: implement
      true
    end
  end
end
