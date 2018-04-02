require "./spec_helper"

{% for adapter in ADAPTERS %}
module {{adapter.upcase.id}}
  describe "[{{adapter.upcase.id}}](Core)" do

    describe "Model.to_s" do
      it "prints column names and its types" do
        # strip prefix: "MYSQL::Job" -> "Job"
        Job.to_s.sub(/^.*?::/,"").should eq("Job(id: Int32, name: String, time: Time::Span)")
      end
    end

    describe "Model#to_s" do
      it "prints column names and its values" do
        # => "#<Job id: 1, name: "foo", time: nil>"
        job = Job.new(id: 1, name: "foo")
        job.to_s.sub(/[A-Z]+::/,"").should eq("#<Job id: 1, name: \"foo\", time: nil>")
      end
    end
  end
end
{% end %}
