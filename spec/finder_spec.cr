require "./spec_helper"

{% for adapter in ADAPTERS %}
  module {{adapter.upcase.id}}
    describe "[{{adapter.upcase.id}}](Finder)" do
      it "(setup)" do
        Job.delete_all

        Job.create!(name: 1, code: Code::OK)
        Job.create!(name: 2, code: Code::OK)
        Job.create!(name: 3, code: Code::ERR)
      end

      describe ".all(query_string : String)" do
        it "work" do
          Job.all("WHERE 1 = 1").size.should eq(3)
          Job.all("WHERE 1 = 2").size.should eq(0)
        end
      end

    end
  end
{% end %}
