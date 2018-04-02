require "./spec_helper"

{% for adapter in ADAPTERS %}
  module {{adapter.upcase.id}}
    describe "[{{adapter.upcase.id}}]" do

      describe "(CRUD)" do
        it "(setup)" do
          Job.migrate!
        end
        
        describe ".new" do
          it "works" do
            job = Job.new(name: "foo")
            job.id?.should eq(nil)
            job.name.should eq("foo")
            job.time?.should eq(nil)
          end
        end

        describe ".count" do
          it "returns the number of records" do
            Job.count.should eq(0)
          end
        end

        describe ".delete_all" do
          it "deletes all records" do
            Job.create!(name: "foo")
            Job.count.should_not eq(0)

            Job.delete_all
            Job.count.should eq(0)
          end
        end

        describe ".all" do
          it "returns all records" do
            Job.delete_all
            3.times{|i| Job.create!(name: i)}

            Job.all.map(&.name).sort.should eq(["0", "1", "2"])
          end
        end

        describe ".first" do
          it "returns the first record" do
            Job.delete_all
            Job.create!(name: "foo")
            Job.first.name.should eq("foo")
          end
        end

        describe ".find(id)" do
          it "works" do
            job = Job.create!(name: "foo")

            job = Job.find(job.id)
            job.new_record?.should be_false
            job.name.should eq("foo")
          end
        end

        describe ".save" do
          it "inserts a new record when new_record?" do
            job = Job.new(name: "foo")
            job.new_record?.should be_true

            job.id?.should be_a(Nil)
            job.save!
            job.id?.should be_a(Int32)
          end

          it "updates the existing record" do
            job_id = Job.create!(name: "foo").id

            job = Job.find(job_id)
            job.name = "bar"
            job.save!

            job = Job.find(job_id)
            job.name.should eq("bar")
          end
        end

        describe ".create" do
          it "works" do
            job = Job.create(name: "foo")
            job.new_record?.should be_false
            job.name.should eq("foo")
          end
        end

        describe ".create!" do
          it "works" do
            job = Job.create!(name: "foo")
            job.new_record?.should be_false
            job.name.should eq("foo")
          end
        end
      end

    end
  end
{% end %}
