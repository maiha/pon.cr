require "./spec_helper"

{% for adapter in ADAPTERS %}
module {{adapter.upcase.id}}
  enum Data::Status
    ZERO    = 0
    SUCCESS = 200
    PENDING = 300
    ERROR   = 400
    FAILURE = 500
  end

  class Case05 < Pon::Model
    adapter {{adapter.id}}
    table_name case05

    field path    : String
    field seq     : Int32
    field body    : String
    field compile : Data::Status
    field spec    : Data::Status
  end

  describe "[CASES] enum({{adapter.upcase.id}})" do
    it "migrates" do
      Case05.migrate!
    end
  end
end
{% end %}
