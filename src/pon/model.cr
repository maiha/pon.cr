require "./fields"

class Pon::Model
  include Fields
  include Migrator
  include Callbacks
  
  macro inherited
    macro finished
      _finish_fields
      _finish_migrator

      include Pon::Validations(Types, {{PRIMARY[:type]}})
      include Pon::Persistence(Types, {{PRIMARY[:type]}})
      include Pon::Finder(Types, {{PRIMARY[:type]}})
    end
  end
end
