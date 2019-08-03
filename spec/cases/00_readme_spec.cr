require "./spec_helper"

{% for adapter in ADAPTERS %}
module {{adapter.upcase.id}}
  module Case00

    enum Code
      OK  = 200
      ERR = 500
    end

    # Model definition
    class Job < Pon::Model
      adapter {{adapter.id}}
      table_name case00

      field   name : String
      field   time : Time
      field   code : Code   = Code::OK
    end
    
    it "works" do
      # Create table
      Job.migrate! # drop and create the table
      Job.count                         .should eq(0)

      # CRUD
      job = Job.new(name: "foo")
      job.name                          .should eq("foo")
      job.time?                         .should eq(nil)
      expect_raises(Pon::ValueNotFound) { job.time }
      job.time = Time.now
      job.code                          .should eq(Code::OK)
      job.save                          .should eq(true)
      Job.find(job.id).code.ok?         .should eq(true)
      Job.find(job.id).time             .should be_a(Time)
      Job.create!(name: "bar", code: Code::ERR)

      # Finder
      Job.all.size                      .should eq(2)
      Job.all(where: "code = 200").size .should eq(1)
      Job.all(["code"]).map(&.name?)    .should eq([nil, nil])

      # And more useful features
      Job.pluck(["name"])               .should eq([["foo"], ["bar"]])
      Job.count_by_code                 .should eq({Code::OK => 1, Code::ERR => 1})
    end

  end
end
{% end %}
