require "./spec_helper"

private class Multibyte < Pon::Model
  adapter mysql
  field   v : String
end

private class Multibyte2 < Pon::Model
  adapter mysql
  table_name "test.mb2"
end

describe "Core" do
  it "(setup)" do
    Multibyte.migrate!
  end

  describe ".table_name" do
    it "should be pluralized with downcase" do
      Multibyte.table_name.should eq("multibytes")
    end

    it "should be settable" do
      Multibyte2.table_name.should eq("test.mb2")
    end
  end

  describe ".quoted_table_name" do
    it "should quote with backtick" do
      Multibyte.quoted_table_name.should eq("`multibytes`")
    end

    it "should be settable" do
      Multibyte2.quoted_table_name.should eq("`test.mb2`")
    end
  end

  it "supports multibytes" do
    r = Multibyte.create(v: "まいは")
    r.v.should eq("まいは")
  end
end
