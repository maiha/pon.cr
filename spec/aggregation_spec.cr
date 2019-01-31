require "./spec_helper"

{% for adapter in ADAPTERS %}
  module {{adapter.upcase.id}}
    describe "[{{adapter.upcase.id}}](Aggregations)" do

      describe ".count_by_xxx" do
        it "works with empty Hash(Type, Int64)" do
          Job.delete_all
          Job.count_by_name.should be_empty
          Job.count_by_name.should be_a(Hash(String, Int64))
        end

        it "returns Hash(String, Int64) for String" do
          Job.create!(name: "foo", code: Code::OK)
          Job.create!(name: "bar", code: Code::OK)
          Job.create!(name: "bar", code: Code::ERR)

          Job.count_by_name.should eq({"foo" => 1, "bar" => 2})
          Job.count_by_name.should be_a(Hash(String, Int64))
        end

        it "returns Hash(Enum, Int64) for Enum" do
          Job.count_by_code.should eq({Code::OK => 2, Code::ERR => 1})
          Job.count_by_code.should be_a(Hash(Code, Int64))
        end
      end

    end
  end
{% end %}
