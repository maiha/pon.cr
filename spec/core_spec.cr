require "./spec_helper"

private class Multibyte < Pon::Model
  adapter mysql
  field   v : String
end

describe "Core" do
  it "(setup)" do
    Multibyte.migrate!
  end

  describe ".table_name" do
    it "should be pluralized with downcase" do
      Multibyte.table_name.should eq("multibytes")
    end
  end
  
  it "supports multibytes" do
    r = Multibyte.create(v: "まいは")
    r.v.should eq("まいは")
  end
end
