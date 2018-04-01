# pon.cr

Maiha's private ORM for [Crystal](http://crystal-lang.org/).

- crystal: 0.24.2

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

## Usage

```crystal
require "pon"
require "pon/adapter/mysql"

class Job < Pon::Model
  adapter mysql
  field   name : String
  field   time : Time::Span
end

Pon::Adapter::Mysql::DEFAULT.url = "mysql://root@127.0.0.1:3306/test"
Job.migrate!  # drop and create the table

Job.count # => 0

job = Job.new(name: "foo")
job.name  # => "foo"
job.time? # => nil

# job.save # TODO
```

## API

```
class Pon::Model
  # Databases
  def self.adapter : Adapter(T)
  def self.migrator : Migrator
  def self.migrate! : Nil
  def self.exec(sql) : Nil
  def self.table_name : String
  def self.quote(v) : String

  # CRUD
  def self.count : Int32
  def save : Bool

  # Field "foo"
  def foo : T
  def foo? : T?
```

## Roadmap

- Adapter Core
  - [x] connect lazily
  - [x] exec plain sql
  - [ ] exec prepared statement
  - [x] count
  - [ ] scalar
  - [x] quote
  - [x] migrator
- Adapter Drivers
  - [x] mysql
  - [ ] pg
  - [ ] sqlite
- Core
  - [x] pluralize table names
  - [ ] custom type
  - [ ] multibytes
  - [ ] record status
  - [ ] inspect class and records
  - [ ] callbacks
  - [ ] validations
- CRUD
  - [ ] all
  - [x] count
  - [ ] create
  - [ ] delete
  - [ ] find
  - [ ] save


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
