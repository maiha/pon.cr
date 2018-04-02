require "./dsl"

class Pon::Model
  include Dsl
  include Callbacks
  
  macro inherited
    macro finished
      _finish_fields

      include Pon::Core
      include Pon::Validations
      include Pon::Persistence
      include Pon::Finder
      include Pon::Migrator
    end
  end
end
