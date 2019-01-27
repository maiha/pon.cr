require "./spec_helper"

private class MysqlFoo1 < Pon::Model
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
      MysqlFoo1.quoted_table_name.should eq("`mysql_foo1s`")
    end

    it "should respect user setting" do
      MysqlFoo2.quoted_table_name.should eq("`foo2`")
    end

    it "should respect user setting with dotted string" do
      MysqlFoo3.quoted_table_name.should eq("`db1.foo3`")
    end
  end

  describe "#table_name" do
    it "returns table name" do
      MysqlFoo1.adapter.table_name.should eq("mysql_foo1s")
      MysqlFoo2.adapter.table_name.should eq("foo2")
      MysqlFoo3.adapter.table_name.should eq("db1.foo3")
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

  describe "[{{adapter.upcase.id}}](Trasaction)" do
    describe "#transaction" do
      {% if adapter == "mysql" %}
      pending "ensures transaction" do
      {% else %}
      it "ensures transaction" do
      {% end %}
        Job.adapter.transaction do
          Job.create!(name: "1")
          Job.create!(name: "2")
        end
      end
    end
  end

  describe "[{{adapter.upcase.id}}](Reset)" do
    describe "#reset!" do
      it "closes and re-builds connection" do
        id1 = Job.adapter.database.object_id
        Job.adapter.reset!
        id2 = Job.adapter.database.object_id
        id1.should_not eq(id2)
      end
    end
  end
end
{% end %}
