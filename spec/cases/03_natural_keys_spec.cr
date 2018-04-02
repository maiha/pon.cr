require "./spec_helper"

{% for adapter in ADAPTERS %}
module {{adapter.upcase.id}}
  class Kvs < Pon::Model
    adapter {{adapter.id}}
    table_name kvs
    primary k : String, auto: false
    field   v : String
  end

  describe "[CASES] Natural Keys({{adapter.upcase.id}})" do
    it "(setup)" do
      Kvs.migrate!
    end

    it "fails when a primary key is not set" do
      kv = Kvs.new
      kv.save.should be_false
      kv.errors.first.message.should eq "Primary key('k') cannot be null"
    end

    it "creates a new object when a primary key is given" do
      Kvs.create!(k: "foo")

      Kvs.find("foo").k.should eq("foo")
    end

    it "updates an existing object" do
      kv = Kvs.create!(k: "foo", v: "1")
      kv.v = "2"
      kv.save!

      kv = Kvs.find("foo")
      kv.k.should eq("foo")
      kv.v.should eq("2")
    end
  end

  describe "[CASES] Natural Keys({{adapter.upcase.id}}) usecases" do
    it "CRUD" do
      Kvs.delete_all

      ## Create
      port = Kvs.create!(k: "mysql_port", v: "3306")
      port.v.should eq("3306")
      Kvs.count.should eq(1)

      ## Read
      port = Kvs.find("mysql_port")
      port.v.should eq("3306")
      port.new_record?.should be_false

      ## Update
      port.v = "3307"
      port.new_record?.should be_false
      port.save!
      port.v.should eq("3307")
      Kvs.count.should eq(1)

      ## Delete
      port.delete!
      Kvs.count.should eq(0)
    end

    it "creates a new record twice" do
      Kvs.delete_all

      # create a new record
      port = Kvs.create!(k: "mysql_port", v: "3306")
      port.v.should eq("3306")
      Kvs.count.should eq(1)

      # create a new record again
      port = Kvs.create!(k: "mysql_port", v: "3306")
      port.v.should eq("3306")
      Kvs.count.should eq(2)
    end
  end
end
{% end %}
