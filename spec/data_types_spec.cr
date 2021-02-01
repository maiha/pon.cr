require "./spec_helper"

{% for adapter in ADAPTERS %}
  module {{adapter.upcase.id}}
    describe "[{{adapter.upcase.id}}]" do
      it "(clean)" do
        DataTypes.delete_all
      end
      
      it "(CRUD)" do
        obj = DataTypes.new(bool: true)
        obj.save!

        obj.bool.should eq(true)
        DataTypes.find(obj.id).bool.should eq(true)

        obj.bool = false
        obj.save!
        obj.bool.should eq(false)
        DataTypes.find(obj.id).bool.should eq(false)
      end

    end
  end
{% end %}
