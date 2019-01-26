require "./spec_helper"

private class MysqlFoo < Pon::Model
  adapter mysql
end

private class MysqlFoo2 < Pon::Model
  adapter mysql
  table_name foo2
end

private class MysqlFoo3 < Pon::Model
  adapter mysql
  table_name "db1.foo3"
end

describe "Adapter" do
  describe ".quoted_table_name" do
    it "should quote with backtick" do
      MysqlFoo.quoted_table_name.should eq("`mysql_foos`")
    end

    it "should respect user setting" do
      MysqlFoo2.quoted_table_name.should eq("`foo2`")
    end

    it "should respect user setting with dotted string" do
      MysqlFoo3.quoted_table_name.should eq("`db1.foo3`")
    end
  end
end


{% for adapter in ADAPTERS %}
module {{adapter.upcase.id}}
  describe "[{{adapter.upcase.id}}](ODBC)" do

    describe "#databases" do
      it "returns database names as Array(String)" do
        Job.adapter.databases.should be_a(Array(String))
      end
    end

    describe "#tables" do
      it "returns table names as Array(String)" do
        Job.adapter.tables.should contain("jobs")
      end
    end

  end
end
{% end %}
