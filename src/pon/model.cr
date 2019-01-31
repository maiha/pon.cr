require "./dsl"

class Pon::Model
  include Dsl
  include Callbacks

  macro inherited
    macro finished
      _finish_dsl

      include Pon::Core
      include Pon::Validations
      include Pon::Serializable
      include Pon::Persistence
      include Pon::Finder
      include Pon::Aggregations
      include Pon::Migrator
    end
  end
end
