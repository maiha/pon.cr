require "./spec_helper"

{% for adapter in ADAPTERS %}
module {{adapter.upcase.id}}
  class Multibyte < Pon::Model
    adapter {{adapter.id}}
    field   v : String
  end

  describe "[CASES] multibytes ({{adapter.upcase.id}})" do
  
    describe "Multibyte" do
      it "supported" do
        r = Multibyte.create(v: "まいは")
        r.v.should eq("まいは")
      end
    end

  end
end
{% end %}
