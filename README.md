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

job = Job.new(name: "foo")
job.name  # => "foo"
job.time? # => nil

# job.save # TODO
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
