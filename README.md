# pon.cr [![Build Status](https://travis-ci.org/maiha/pon.cr.svg?branch=master)](https://travis-ci.org/maiha/pon.cr)

Maiha's private ORM for [Crystal](https://crystal-lang.org/).

##### tested
- crystal: 1.6.0-alpine
  - db: crystal-db-0.10.1
  - mysql: crystal-mysql-0.13.0
  - sqlite3: crystal-sqlite3-0.18.0
  - pg: will/crystal-pg-0.23.2
- mysql:5.6
- postgres:12.4

## Usage

```crystal
require "pon"
require "pon/adapter/mysql"  # "mysql", "pg", "sqlite"

# Enum support!
enum Code
  OK  = 200
  ERR = 500
end

# Model definition
class Job < Pon::Model
  adapter mysql              # "mysql", "pg", "sqlite"
  field   name : String
  field   time : Time
  field   code : Code = Code::OK  # default value
end

Pon::Adapter::Mysql.setting.url = "mysql://root@127.0.0.1:3306/test"

# Create table
Job.migrate! # drop and create the table
Job.count                 # => 0

# CRUD
job = Job.new(name: "foo")
job.name                  # => "foo"
job.time?                 # => nil
job.time                  # raises Pon::ValueNotFound
job.code                  # => Code::OK
job.save                  # => true
Job.find(job.id).code.ok? # => true
Job.create!(name: "bar", code: Code::ERR)

# Finder
Job.all.size                      # => 2
Job.all(where: "code = 200").size # => 1
Job.all(["code"]).map(&.name?)    # => [nil, nil]

# And more useful features
Job.pluck(["name"]) # => [["foo"], ["bar"]]
Job.count_by_code   # => {Code::OK => 1, Code::ERR => 1}
```

## DataTypes

The following data types are supported (tested).
* `Bool`
* `Enum(Int32)`
* `Int32`
* `String`
* `Time`

See defined fields written in [spec/spec_helper.cr](spec/spec_helper.cr).

## API : Adapter

```crystal
  def exec(sql) : Nil
  def lastval : Int64
  def scalar(*args)
  def reset! : Nil

  # CRUD
  def insert(fields, params)
  def all(fields : Array(String), types, condition = nil, **opts)
  def one?(id, fields : Array(String), as types : Tuple)
  def count : Int32
  def delete(key) : Bool
  def delete : Nil
  def truncate : Nil

  # ODBC
  def databases : Array(String)
  def tables : Array(String)

  # Experimental
  def transaction(&block) : Nil # only sqlite and pg
```

## API : Model

```crystal
class Pon::Model
  # Databases
  def self.adapter : Adapter(A)
  def self.migrator : Migrator
  def self.migrate! : Nil

  # Core
  def self.table_name : String
  def new_record? : Bool
  def to_h : Hash(String, ALL_TYPES)

  # CRUD
  def self.create! : M
  def self.create : M
  def self.count : Int32
  def self.all : Array(M)
  def self.all(query_string : String) : Array(M)
  def self.where(condition : String) : Array(M)
  def self.first : M
  def self.first? : M?
  def save : Bool
  def save! : Bool
  def self.delete_all
  def delete

  # Field "foo"
  def foo : T
  def foo? : T?
  def [](key) : T
  def []?(key) : T?
  def []=(key, val)

  # Aggregations
  def self.count_by_xxx : Hash(Type, Int64)

  # Misc
  def self.pluck(fields : Array(String))
```

## API : Query

```crystal
class JobName < Pon::Query
  adapter pg
  field name : String
  field size : Int32 = "length(name)"

  from <<-SQL
    FROM  jobs
    ORDER BY {{order}}
    LIMIT {{limit}}
    SQL

  def self.all(limit = 10, order = "name")
    context.bind(limit: limit, order: order).all
  end
end

JobName.all(limit: 2).map(&.name) # => ["bar", "foo"]
```

## Connection Pool

The `Adapter.database` is pooled because it uses `DB::Database`. The default `max_pool_size` is 5.
It can be overridden by `Setting` and `reset!`.

```crystal
Job.adapter.database.pool.stats.max_connections # => 5

Pon::Adapter::Pg.setting.max_pool_size = 3
Pon::Adapter.reset!

Job.adapter.database.pool.stats.max_connections # => 3
```

## Logging

```crystal
Pon.query_logging=(v : Bool) # writes queries into the logger or not (default: true)
Pon.query_logging?           # => true

# when Log is enabled
Pon.logger=(v : Logger)      # replace Logger instance

# when Logger is enabled
Pon.log.backend = Log::IOBackend.new(io: File.open("sql.log", "w+"))
Pon.log.level = :debug
```

## Roadmap

- Adapter Core
  - [x] connect lazily
  - [x] share same connection between adapters
  - [x] exec plain sql
  - [x] exec prepared statement
  - [x] all
  - [x] count
  - [x] scalar
  - [x] quote
  - [ ] escape
  - [x] migrator
- Adapter Drivers
  - [x] reset connections
  - RDB
    - [x] mysql
    - [x] pg
    - [x] sqlite
  - KVS
    - [ ] redis
- Core
  - [x] pluralize table names
  - [x] special types (Enum)
  - [ ] custom type
  - [x] multibytes
  - [x] record status
  - [x] inspect class and records
  - [ ] callbacks
  - [ ] validations
  - [x] natural keys
  - [x] default values
- CRUD
  - [x] create
  - [x] delete, delete_all
  - [x] find
  - [x] save
- Finder
  - [x] all, count, first
  - [x] pluck (with casting)
  - [ ] field aliases
- Aggregations
  - [x] count_by_xxx
- Relations
  - [ ] belongs_to
  - [ ] has_many
  - [ ] has_many through
- Query
  - [x] typed column access
  - [x] arbitrary select query
  - [x] prepared statement
- Misc
  - [ ] bulk insert
  - [ ] upsert

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  pon:
    github: maiha/pon.cr
    version: 1.6.0

  # one of following adapter
  mysql:
    github: crystal-lang/crystal-mysql
  sqlite3:
    github: crystal-lang/crystal-sqlite3
  pg:
    github: will/crystal-pg
```

## Development

```console
$ make spec
```

## Contributing

1. Fork it ( https://github.com/maiha/pon.cr/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [maiha](https://github.com/maiha) maiha - creator, maintainer

## Thanks / Inspiration

* [crecto](https://github.com/Crecto/crecto)
* [AciveRecord](https://github.com/rails/rails/tree/master/activerecord)
* [active_record.cr](https://github.com/waterlink/active_record.cr)
