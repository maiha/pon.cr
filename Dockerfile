FROM crystallang/crystal:0.30.0

RUN apt-get update -qq && apt-get install -y --no-install-recommends libpq-dev libsqlite3-dev libmysqlclient-dev netcat

CMD ["crystal", "--version"]

