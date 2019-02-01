require "./spec_helper"

{% for adapter in ADAPTERS %}
module {{adapter.upcase.id}}
  describe "[{{adapter.upcase.id}}](Core)" do

    describe "Model.to_s" do
      it "prints column names and its types" do
        # strip prefix: "MYSQL::Job" -> "Job"
        Job.to_s.sub(/^.*?::/,"").should eq("Job(id: Int32, name: String, time: Time, code: Code)")
      end
    end

    describe "Model#to_s" do
      it "prints column names and its values" do
        # => "#<Job id: 1, name: "foo", time: nil>"
        job = Job.new(id: 1, name: "foo")
        job.to_s.sub(/[A-Z]+::/,"").should eq("#<Job id: 1, name: \"foo\", time: nil, code: nil>")
      end
    end

    describe "Model#to_h" do
      it "converts to a Hash" do
        job = Job.new(name: "foo")
        job.to_h.should eq({"id" => nil, "name" => "foo", "time" => nil, "code" => nil})

        job = Job.new(id: 1, name: "foo")
        job.to_h.should eq({"id" => 1, "name" => "foo", "time" => nil, "code" => nil})
      end
    end

    describe "Model#[key]" do
      it "works" do
        job = Job.new(name: "foo")
        job["name"].should eq("foo")
        expect_raises(Pon::ValueNotFound) { job["code"] }
        expect_raises(ArgumentError     ) { job["xxx"]  }
      end
    end

    describe "Model#[key]?" do
      it "works" do
        job = Job.new(name: "foo")
        job["name"]?.should eq("foo")
        job["code"]?.should eq(nil)
        expect_raises(ArgumentError) { job["xxx"]? }
      end
    end

    describe "Model#[key] = value" do
      it "works" do
        job = Job.new
        job["name"] = "foo"
        job["name"].should eq("foo")
        job.name.should eq("foo")
        job["code"] = Code::OK
        job.code.should eq(Code::OK)
        expect_raises(ArgumentError) {
          job["xxx"] = 1
        }
      end
    end

    describe "(type casting for DB)" do
      it "db_serialize(field)" do
        job = Job.new
        job.db_serialize("name").should eq(nil)
        job.db_serialize("time").should eq(nil)
        job.db_serialize("code").should eq(nil)

        job = Job.new(name: "http", time: Time.now, code: Code::OK)
        job.db_serialize("name").should eq("http")
        job.db_serialize("time").should be_a(Time)
        job.db_serialize("code").should eq(200)
      end

      it "db_serialize_contents" do
        job = Job.new(name: "http", code: Code::OK)
        job.db_serialize_contents.should eq(["http", nil, 200])
      end
    end

  end
end
{% end %}
