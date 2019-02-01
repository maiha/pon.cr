require "./spec_helper"

{% for adapter in ADAPTERS %}
module {{adapter.upcase.id}}
  enum Status
    DEFAULT = 0
    SUCCESS = 200
    PENDING = 300
    ERROR   = 400
    FAILURE = 500
  end

  class Case06 < Pon::Model
    adapter {{adapter.id}}
    table_name case06

    field path : String
    field test : Status
    field spec : Status = Status::DEFAULT
  end

  describe "[CASES] default value({{adapter.upcase.id}})" do
    it "migrates" do
      Case06.migrate!
    end

    describe ".new" do
      it "sets default value" do
        obj = Case06.new
        obj.path?.should eq(nil)
        obj.test?.should eq(nil)
        obj.spec?.should eq(Status::DEFAULT)
      end

      it "can overwrite default value" do
        obj = Case06.new(spec: Status::SUCCESS)
        obj.path?.should eq(nil)
        obj.test?.should eq(nil)
        obj.spec?.should eq(Status::SUCCESS)
      end

      it "can't overwrite default value by nil" do
        obj = Case06.new(spec: nil)
        obj.path?.should eq(nil)
        obj.test?.should eq(nil)
        obj.spec?.should eq(Status::DEFAULT)
      end
    end

    describe ".create!" do
      it "sets default value" do
        obj = Case06.create!(test: Status::SUCCESS)
        obj.path?.should eq(nil)
        obj.test?.should eq(Status::SUCCESS)
        obj.spec?.should eq(Status::DEFAULT)
      end

      it "can overwrite default value" do
        obj = Case06.create!(spec: Status::SUCCESS)
        obj.path?.should eq(nil)
        obj.test?.should eq(nil)
        obj.spec?.should eq(Status::SUCCESS)
      end

      it "can't overwrite default value by nil" do
        obj = Case06.create!(spec: nil)
        obj.path?.should eq(nil)
        obj.test?.should eq(nil)
        obj.spec?.should eq(Status::DEFAULT)
      end
    end

    describe ".all" do
      it "sets default value" do
        # force to update 'spec' to `NULL`
        qt = Case06.adapter.qt
        Case06.adapter.exec("UPDATE #{qt} SET spec = NULL")

        Case06.all.map(&.spec?).uniq.should eq([Status::DEFAULT])
      end
    end

  end
end
{% end %}
