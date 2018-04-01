# DB migration tool that prepares a table for the class
#
# ```crystal
# class User < Pon::Model
#   adapter mysql
#   field name : String
# end
#
# User.migrator.migrate!
# # => "DROP TABLE IF EXISTS `users`;"
# # => "CREATE TABLE `users` (id BIGSERIAL PRIMARY KEY, name VARCHAR(255));"
#
# User.migrator(table_options: "ENGINE=InnoDB DEFAULT CHARSET=utf8").create
# # => "CREATE TABLE ... ENGINE=InnoDB DEFAULT CHARSET=utf8;"
# ```
module Pon::Migrator
  class Base
    @quoted_table_name : String

    def initialize(klass, @table_options = "")
      @quoted_table_name = klass.quoted_table_name
    end
    
    def migrate!
      drop
      create
    end      

    def drop
    end

    def create
    end
  end

  macro _finish_migrator
    {% primary_name = PRIMARY[:name] %}
    {% primary_type = PRIMARY[:type] %}
    {% primary_auto = PRIMARY[:auto] %}
    {% adapter = "#{@type.name}.adapter".id %}
    
    class Migrator < Pon::Migrator::Base
      private def exec(*args)
        {{adapter}}.exec(*args)
      end

      def drop
        exec "DROP TABLE IF EXISTS #{ @quoted_table_name };"
      end
    
      def create
        resolve = ->(key : String) {
          {{adapter}}.class.schema_type?(key) || raise "Migrator(#{ {{adapter}}.class.name }) doesn't support '#{key}' yet."
        }

        stmt = String.build do |s|
          s.puts "CREATE TABLE #{ @quoted_table_name }("

          # primary key
          k = {{adapter}}.quote("{{primary_name}}")
          v =
            {% if primary_auto %}
              resolve.call("AUTO_{{primary_type.id}}")
            {% else %}
              resolve.call("{{primary_type}}")
            {% end %}
          s.print "#{k} #{v}"

          # content fields
          {% for name, h in CONTENT_FIELDS %}
            s.puts ","
            k = {{adapter}}.quote("{{name}}")
            v = resolve.call("{{h[:type]}}")
            s.puts "#{k} #{v}"
          {% end %}

          s.puts ") #{@table_options};"
        end

        exec stmt
      end
    end
    
    def self.migrator(**args)
      Migrator.new(self, **args)
    end

    def self.migrate!(**args)
      migrator(**args).migrate!
    end
  end
end
