require "./spec_helper"

private class Mutibyte < Pon::Model
  adapter mysql
  field   v : String
end

describe "Core" do
  it "(setup)" do
    Mutibyte.migrate!
  end
  
  pending "supports multibytes" do
    r = Mutibyte.create(v: "まいは")
    r.v.should eq("まいは")
  end
end
