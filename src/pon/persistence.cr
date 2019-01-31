module Pon::Persistence
  macro included
    {% primary_name = PRIMARY[:name] %}
    {% primary_type = PRIMARY[:type] %}
    {% primary_auto = PRIMARY[:auto] %}

    @updated_at : Time?
    @created_at : Time?

    def self.delete_all
      adapter.delete
    end
    
    def save!(*args)
      create_or_update!(*args) || raise Pon::RecordNotSaved.new(self)
    end

    def save(*args)
      create_or_update!(*args)
    rescue DB::Error | Pon::Error
      false
    end

    def create_or_update!(*args)
      return false unless valid?

      adapter = self.class.adapter
      begin
        __run_before_save
        table_name = self.class.table_name
        now = Time.now.to_utc

        if (pk = @{{primary_name}}) && !new_record?
          __run_before_update
          # @updated_at = now
          fields = self.class.content_field_names
          params = db_serialize_contents + [pk]

          begin
            adapter.update(fields, params)
          rescue err
            raise DB::Error.new(err.message)
          end
          __run_after_update
        else
          __run_before_create
          # @created_at = @updated_at = now
          fields = self.class.content_field_names.dup
          params = db_serialize_contents
          if pk = @{{primary_name}}
            fields << "{{primary_name}}"
            params << pk
          end
          begin
            {% if primary_type.id == "Int32" %}
              adapter.insert(fields, params)
              @{{primary_name}} = adapter.lastval.to_i32
            {% elsif primary_type.id == "Int64" %}
              adapter.insert(fields, params)
              @{{primary_name}} = adapter.lastval
            {% elsif primary_auto == true %}
              {% raise "Failed to define #{@type.name}#save: Primary key must be Int(32|64), or set `auto: false` for natural keys.\n\n  primary #{primary_name} : #{primary_type}, auto: false\n" %}
            {% else %}
              if @{{primary_name}}
                adapter.insert(fields, params)
              else
                message = "Primary key('{{primary_name}}') cannot be null"
                errors << Pon::FieldError.new("{{primary_name}}", message)
                raise DB::Error.new
              end
            {% end %}
          rescue err : DB::Error
            raise err
          rescue err
            raise DB::Error.new(err.message)
          end
          __run_after_create
        end
        @new_record = false
        __run_after_save
        return true
      rescue ex : DB::Error
        if message = ex.message
          Pon.logger.error "Save Exception: #{message}"
          errors << Pon::FieldError.new(nil, message)
        end
        raise ex
      end
    end

    def delete!
      delete || raise Pon::RecordNotDeleted.new(self)
    end

    def delete
      begin
        __run_before_destroy
        self.class.adapter.delete({{primary_name}})
        __run_after_destroy
        @destroyed = true
        return true
      rescue ex : DB::Error
        if message = ex.message
          Pon.logger.error "Destroy Exception: #{message}"
          errors << Pon::FieldError.new(nil, message)
        end
        return false
      end
    end

    def self.create(**args)
      object = new(args.to_h)
      object.save
      object
    end
    
    def self.create!(**args)
      object = new(args.to_h)
      object.save! || raise Pon::RecordInvalid.new(object)
      object
    end
    
    # Returns true if this object hasn't been saved yet.
    getter? new_record : Bool = true

    # Returns true if this object has been destroyed.
    getter? destroyed : Bool = false

    # Returns true if the record is persisted.
    def persisted?
      !(new_record? || destroyed?)
    end

    # Returns true if this object hasn't been saved yet.
    getter? new_record : Bool = true

    # Returns true if this object has been destroyed.
    getter? destroyed : Bool = false

    # Returns true if the record is persisted.
    def persisted?
      !(new_record? || destroyed?)
    end
  end
end
