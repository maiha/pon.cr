require "./spec_helper"

private class Job < Pon::Model
  adapter mysql
  primary id : Int32
  field   name : String
  field   time : Time::Span
end

describe "CRUD" do
  it "(setup)" do
    Job.migrate!
  end
  
  describe ".count" do
    it "returns the number of records" do
      Job.count.should eq(0)
    end
  end

  describe ".first" do
    pending "returns the first record" do
      Job.delete_all
      Job.create!(name: "foo")
      Job.first.name.should eq("foo")
    end
  end

  describe ".new" do
    it "works" do
      job = Job.new(name: "foo")
      job.id?.should eq(nil)
      job.name.should eq("foo")
      job.time?.should eq(nil)
    end
  end

  describe ".save" do
    it "inserts a new record when new_record?" do
      job = Job.new(name: "foo")
      job.new_record?.should be_true

      job.id?.should eq(nil)
      job.save.should be_true
      job.new_record?.should be_false
      job.id?.should eq(1)
    end

    pending "updates the existing record" do
      job = Job.new(name: "foo")
      job.new_record?.should be_true

      job.id?.should eq(nil)
      job.save.should be_true
      job.new_record?.should be_false
      job.id?.should eq(1)
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

  describe ".find(id)" do
    it "works" do
      job = Job.create!(name: "foo")

      job = Job.find(job.id)
      job.name.should eq("foo")
    end
  end
end
