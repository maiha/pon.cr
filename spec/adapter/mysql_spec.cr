require "../spec_helper"

private def adapter
  Pon::Adapter::Mysql
end

describe Pon::Adapter::Mysql do
  describe "#quote" do
    context "simple value" do
      it "should return `foo`" do
        adapter.quote("foo").should eq("`foo`")
      end
    end

    context "dotted value" do
      it "should keep dots" do
        adapter.quote("foo.bar").should eq("`foo.bar`")
      end
    end

    context "already quoted value" do
      it "should return itself" do
        ["`foo`", "`foo.bar`", "`foo.bar.baz`", "`foo`.`bar`", "`foo`.bar"].each do |value|
          adapter.quote(value).should eq value
        end
      end
    end
  end
end
