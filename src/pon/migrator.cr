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

  macro included
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
        stmt = String.build do |s|
          s.puts "CREATE TABLE #{ @quoted_table_name }("

          # primary key
          k = {{adapter}}.quote("{{primary_name}}")
          v =
            {% if primary_auto %}
              resolve("AUTO_{{primary_type.id}}")
            {% else %}
              resolve("{{primary_type}}")
            {% end %}
          s.print "#{k} #{v}"

          # content fields
          # use `ALL_FIELDS` because `CONTENT_FIELDS` doesn't contain `h[:db]`
          {% for name, h in ALL_FIELDS %}
            {% if name != primary_name %}
              s.puts ","
              k = {{adapter}}.quote("{{name}}")
              v = resolve("{{h[:db]}}")
              s.puts "#{k} #{v}"
            {% end %}
          {% end %}

          s.puts ") #{@table_options};"
        end
        exec stmt
      end

      private def resolve(key : String)
        if key =~ /Code$/
          return resolve("Int32")
        end
        {{adapter}}.class.raw_type?(key) || raise "Migrator(#{ {{adapter}}.class.name }) doesn't support '#{key}' yet."
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
