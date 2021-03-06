require "./spec_helper"

{% for adapter in ADAPTERS %}
  module {{adapter.upcase.id}}
    describe "[{{adapter.upcase.id}}]" do
      it "(clean)" do
        Job.delete_all
      end
      
      describe "(CRUD)" do
        describe "Model.new" do
          it "works" do
            job = Job.new(name: "foo")
            job.id?.should eq(nil)
            job.name.should eq("foo")
            job.time?.should eq(nil)
            job.code?.should eq(nil)
          end
        end

        describe "Model.count" do
          it "returns the number of records" do
            Job.count.should eq(0)
          end
        end

        describe "Model.all" do
          it "returns all records" do
            Job.delete_all

            Job.create!(name: 1, code: Code::OK)
            Job.create!(name: 2, code: Code::OK)
            Job.create!(name: 3, code: Code::ERR)

            Job.all.map(&.name).sort.should eq(["1", "2", "3"])
            Job.all.map(&.code).uniq.sort.should eq([Code::OK, Code::ERR])

            # respects where condition
            Job.all(where: "name <> '2'").map(&.name).sort.should eq(["1", "3"])
          end

          it "works with db_serialize without overloads error" do
            # no overload matches 'Array(Code | Int64 | Nil)#<<' with type Int32
            # Overloads are:
            # - Array(T)#<<(value : T)
            Job.all.map(&.db_serialize_contents)
          end
        end

        describe "Model.where" do
          it "acts same as all(where: ...)" do
            # re-use above records
            Job.where("name <> '2'").map(&.name).sort.should eq(["1", "3"])
          end
        end

        describe "Model.first" do
          it "raises Pon::RecordNotFound if no records exist" do
            Job.delete_all
            expect_raises(Pon::RecordNotFound) do
              Job.first
            end
          end

          it "returns the first record if exists" do
            Job.create!(name: "foo")
            Job.first.name.should eq("foo")
          end
        end

        describe "Model.first?" do
          it "returns nil if no records exist" do
            Job.delete_all
            Job.first?.should eq(nil)
          end

          it "returns the first record if exists" do
            Job.create!(name: "foo")
            Job.first?.should be_a(Job)
          end
        end

        describe "Model.find(id)" do
          it "raises Pon::RecordNotFound if the record doesn't exist" do
            expect_raises(Pon::RecordNotFound) do
              Job.find(-1)
            end
          end

          it "returns the specified record if exists" do
            job = Job.create!(name: "foo")

            job = Job.find(job.id)
            job.new_record?.should be_false
            job.locked_record?.should be_false
            job.name.should eq("foo")
          end
        end

        describe "Model.find?(id)" do
          it "returns nil if the record doesn't exist" do
            Job.find?(-1).should eq(nil)
          end

          it "returns the specified record if exists" do
            job = Job.create!(name: "foo")

            job = Job.find?(job.id)
            job.should be_a(Job)
            job.try(&.new_record?).should be_false
            job.try(&.locked_record?).should be_false
            job.try(&.name).should eq("foo")
          end
        end

        describe "Model#save!" do
          it "inserts a new record when new_record?" do
            job = Job.new(name: "foo")
            job.new_record?.should be_true
            job.locked_record?.should be_false

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

          it "raises LockedRecord when locked_record" do
            job_id = Job.create!(name: "foo").id

            job = Job.find(job_id)
            job.name = "bar"
            # force locked
            job.record_locked_by = "for test"

            expect_raises(Pon::RecordLocked) do
              job.save!
            end
          end
        end

        describe "Model.create" do
          it "creates a new record" do
            job = Job.create(name: "foo")
            job.new_record?.should be_false
            job.locked_record?.should be_false
            job.name.should eq("foo")
          end
        end

        describe "Model.create!" do
          it "creates a new record" do
            job = Job.create!(name: "foo")
            job.new_record?.should be_false
            job.locked_record?.should be_false
            job.name.should eq("foo")
          end
        end

        describe "Model.delete_all" do
          it "deletes all records" do
            Job.count.should_not eq(0)
            Job.delete_all
            Job.count.should eq(0)
          end
        end

        describe "Model#delete" do
          it "deletes the record" do
            job = Job.create!(name: "foo")
            Job.find?(job.id).should be_a(Job)
            job.delete.should be_true
            Job.find?(job.id).should be_a(Nil)
          end
        end
      end

    end
  end
{% end %}
