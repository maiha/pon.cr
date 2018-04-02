require "./spec_helper"

private class Case01Foo < Pon::Model
  adapter mysql
  field   v : String
end

private class Case01Bar < Pon::Model
  adapter mysql
  table_name "test.tbl2"
end

describe "[CASES] table names" do
  describe ".table_name" do
    it "should be pluralized with downcase" do
      Case01Foo.table_name.should eq("case01_foos")
    end

    it "should be settable" do
      Case01Bar.table_name.should eq("test.tbl2")
    end
  end

  describe ".quoted_table_name" do
    it "should quote with backtick" do
      Case01Foo.quoted_table_name.should eq("`case01_foos`")
    end

    it "should be settable" do
      Case01Bar.quoted_table_name.should eq("`test.tbl2`")
    end
  end
end
