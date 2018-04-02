# pon.cr

Maiha's private ORM for [Crystal](http://crystal-lang.org/).

- crystal: 0.24.2

## Usage

```crystal
require "pon"
require "pon/adapter/mysql"

class Job < Pon::Model
  adapter mysql
  field   name : String
  field   time : Time::Span
end

Pon::Adapter::Mysql.setting.url = "mysql://root@127.0.0.1:3306/test"
Job.migrate! # drop and create the table

Job.count # => 0

job = Job.new(name: "foo")
job.name  # => "foo"
job.time? # => nil

job.save  # => true
```

## API : Adapter

```crystal
  def exec(sql) : Nil
  def lastval : Int64
  def scalar(*args)

  def insert(fields, params)
  def all(fields : Array(String), as types : Tuple, limit = nil)
  def one?(id, fields : Array(String), as types : Tuple)
  def count : Int32
  def delete(key) : Bool
  def delete : Nil
  def truncate : Nil
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

  # CRUD
  def self.create! : M
  def self.create : M
  def self.count : Int32
  def self.all : Array(M)
  def self.first : M
  def self.first? : M?
  def save : Bool
  def save! : Bool
  def self.delete_all
  def delete

  # Field "foo"
  def foo : T
  def foo? : T?
```

## Roadmap

- Adapter Core
  - [x] connect lazily
  - [x] exec plain sql
  - [x] exec prepared statement
  - [x] count
  - [x] scalar
  - [x] quote
  - [ ] escape
  - [x] migrator
- Adapter Drivers
  - RDB
    - [x] mysql
    - [x] pg
    - [x] sqlite
  - KVS
    - [ ] redis
- Core
  - [x] pluralize table names
  - [ ] custom type
  - [x] multibytes
  - [x] record status
  - [x] inspect class and records
  - [ ] callbacks
  - [ ] validations
  - [x] natural keys
- CRUD
  - [x] all, count, first
  - [x] create
  - [x] delete, delete_all
  - [x] find
  - [x] save
- Relations
  - [ ] belongs_to
  - [ ] has_many
  - [ ] has_many through
- Misc
  - [ ] bulk insert
  - [ ] upsert

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  pon:
    github: maiha/pon.cr
	version: 0.1.0

  # one of following adapter
  mysql:
    github: crystal-lang/crystal-mysql
    version: ~> 0.4.0
  sqlite3:
	github: crystal-lang/crystal-sqlite3
	version: ~> 0.9.0
  pg:
	github: will/crystal-pg
	version: ~> 0.14.1
```

## Development

TODO: Write development instructions here

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
