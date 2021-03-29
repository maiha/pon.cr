require "./spec_helper"

{% for adapter in ADAPTERS %}
  module {{adapter.upcase.id}}
    describe "[{{adapter.upcase.id}}](Finder)" do
      it "(setup)" do
        Job.delete_all

        Job.create!(name: 1, code: Code::OK)
        Job.create!(name: 2, code: Code::OK)
        Job.create!(name: 3, code: Code::ERR, time: Time.utc)
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

      describe ".all(fields : Array(String), condition : String)" do
        it "works" do
          all = Job.all(["id", "time"], "order by id DESC LIMIT 1")
          all.size.should eq(1)

          job = all.first
          job.id?.should be_a Int32
          job.name?.should eq nil
          job.code?.should eq nil
          job.time?.should be_a Time
        end

        it "respects order of fields" do
          all = Job.all(["time", "id"], "order by id DESC LIMIT 1")
          all.size.should eq(1)

          job = all.first
          job.id?.should be_a Int32
          job.name?.should eq nil
          job.code?.should eq nil
          job.time?.should be_a Time
        end
      end

    end
  end
{% end %}
