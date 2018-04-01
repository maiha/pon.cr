require "./fields"
require "./crud/*"

class Pon::Model
  include Fields
  include Migrator
  
  macro inherited
    macro finished
      _finish_fields
      _generate_migrator

      include Pon::Read(Types, {{PRIMARY[:type]}})
#    include Pon::Create(Types)
#    include Pon::Save(Types)
#    include Pon::Delete(Types)
    end
  end
end
