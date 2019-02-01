require "./spec_helper"

{% for adapter in ADAPTERS %}
  module {{adapter.upcase.id}}
    describe "[{{adapter.upcase.id}}](Pluck)" do
      it "(setup)" do
        Job.delete_all

        Job.create!(name: "foo", code: Code::OK)
        Job.create!(name: "bar", code: Code::OK)
        Job.create!(name: "baz", code: Code::ERR)
      end

      describe ".pluck([String])" do
        it "returns Array(Array(String))" do
          Job.pluck(["name"]).should eq([["foo"], ["bar"], ["baz"]])
          Job.pluck(["name"], where: "code = 500").should eq([["baz"]])
        end
      end

      describe ".pluck([String, Enum])" do
        it "returns Array(Array(String, Enum))" do
          Job.pluck(["name", "code"]).should eq([["foo", Code::OK], ["bar", Code::OK], ["baz", Code::ERR]])
          Job.pluck(["name", "code"], where: "code = 500").should eq([["baz", Code::ERR]])
        end
      end

    end
  end
{% end %}
