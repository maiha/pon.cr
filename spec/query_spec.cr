require "./spec_helper"

{% for adapter in ADAPTERS %}
  module {{adapter.upcase.id}}

    class JobQuery < Pon::Query
      adapter {{adapter.id}}

      field name : String
      field size : (Int32|Int64) = "length(name)"

      from <<-SQL
        FROM  jobs
        ORDER BY \{{order}}
        LIMIT \{{limit}}
        SQL

      def self.all(limit = 10, order = "name")
        context.bind(limit: limit, order: order).all
      end
    end

    class JobQueryName < Pon::Query
      adapter {{adapter.id}}
      field name : String
      from "FROM jobs ORDER BY name LIMIT \{{limit}}"
    end

    describe "[{{adapter.upcase.id}}](Query)" do
      it "(setup)" do
        Job.delete_all

        Job.create!(name: "foo", time: Pretty.now(2019,8,3))
        Job.create!(name: "bar", time: Pretty.now(2019,8,4))
      end

      it "works as README" do
        JobQuery.all(limit: 1).size.should eq(1)
        JobQuery.all(limit: 2).size.should eq(2)

        JobQuery.all(order: "name").map(&.name).should eq(["bar", "foo"])
        JobQuery.all(order: "time").map(&.name).should eq(["foo", "bar"])
      end
    end

    describe "[{{adapter.upcase.id}}](Placeholder)" do
      describe "#defined_params" do
        it "returns defined parameter names" do
          ph = JobQuery.context.placeholder
          ph.defined_params.to_a.should eq(["order", "limit"])
        end
      end

      describe "#unbound_params" do
        it "returns unbound parameter names" do
          ph = JobQuery.context.placeholder
          ph.unbound_params.to_a.should eq(["order", "limit"])
          ph.bind(limit: 1)
          ph.unbound_params.to_a.should eq(["order"])
          ph.bind(order: "id")
          ph.unbound_params.to_a.should eq([] of String)
        end
      end
    end
      
    describe "[{{adapter.upcase.id}}](Context)" do
      describe "#bind" do
        it "binds parameters" do
          ctx = JobQuery.context
          ctx.bind(limit: 1)
          ctx.placeholder.unbound_params.to_a.should eq(["order"])
        end

        it "raise ParamError when unknown parameter is given" do
          ctx = JobQuery.context
          expect_raises(Pon::Placeholder::ParamError, "unknown param: 'foo'") do
            ctx.bind(foo: 1)
          end
        end

        it "raise ParamError when same parameter was bound twice" do
          ctx = JobQuery.context
          ctx.bind(limit: 1)
          expect_raises(Pon::Placeholder::ParamError, "already bound: 'limit'") do
            ctx.bind(limit: 1)
          end
        end
      end

      describe "#all" do
        it "returns all records" do
          ctx = JobQuery.context
          ctx.bind(order: "name", limit: 2)
          ctx.all.map(&.name).should eq(["bar", "foo"])
        end
      end

      describe "#scalar" do
        it "returns a scalar value" do
          ctx = JobQueryName.context
          ctx.bind(limit: 1)
          ctx.scalar.should eq("bar")
        end
      end

      describe "#csv" do
        it "builds csv" do
          ctx = JobQuery.context
          ctx.bind(order: "name", limit: 2)
          ctx.csv.should eq("bar,3\nfoo,3")
        end
      end
    end
  end
{% end %}
