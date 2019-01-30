require "./spec_helper"

{% for adapter in ADAPTERS %}
module {{adapter.upcase.id}}
  describe "[{{adapter.upcase.id}}](Cast)" do

    describe "Enum" do
      it "sets and gets Enum directly" do
        job = Job.new(name: "foo", code: Code::OK)
        job.code.should eq(Code::OK)
      end

      it "Model#foo=(v : Int32 | Enum) : Enum" do
        job = Job.new
        job.code?.should eq(nil)

        job.code = 200
        job.code.should eq(Code::OK)
        job.code?.should eq(Code::OK)

        job.code = nil
        job.code?.should eq(nil)

        job.code = Code::OK
        job.code.should eq(Code::OK)
        job.code?.should eq(Code::OK)
      end

      it "persists" do
        job = Job.new(name: "foo", code: Code::OK)
        job.save!

        Job.find(job.id).code.should eq(Code::OK)
      end
    end

  end
end
{% end %}
