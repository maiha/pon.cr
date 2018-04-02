require "./spec_helper"

{% for adapter in ADAPTERS %}
module {{adapter.upcase.id}}
  class Case04 < Pon::Model
    adapter {{adapter.id}}
    field name : String
  end

  describe "[CASES] no tables({{adapter.upcase.id}})" do

    describe "Model.create!" do
      it "should raise DB::Error" do
        # mysql: "Table 'test.mysql_kvs' doesn't exist"
        # pg   : "relation "pg_case04s" does not exist"
        expect_raises(DB::Error, /(relation|table)/i) do
          Case04.create!(name: "foo")
        end
      end
    end

  end
end
{% end %}
