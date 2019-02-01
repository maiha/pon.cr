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

        it "should not be new_record" do
          Job.all("WHERE 1 = 1").map(&.new_record?).uniq.should eq([false])
        end

        it "should not be locked_record" do
          Job.all("WHERE 1 = 1").map(&.locked_record?).uniq.should eq([false])
        end
      end

      describe ".all(fields : Array(String))" do
        it "work" do
          all = Job.all(["name"])
          all.size.should eq(3)

          obj = all.first
          obj.should be_a(Job)
          obj.id?.should eq(nil)
          obj.name?.should be_a(String)
          obj.code?.should eq(nil)
          obj.new_record?.should be_false
          obj.locked_record?.should be_true
        end
      end

    end
  end
{% end %}
