require "./spec_helper"

{% for adapter in ADAPTERS %}
  module {{adapter.upcase.id}}

    class Multibyte < Pon::Model
      adapter mysql
      field   v : String
    end

    describe "Multibyte" do
      it "supported" do
        r = Multibyte.create(v: "まいは")
        r.v.should eq("まいは")
      end
    end

  end
{% end %}
