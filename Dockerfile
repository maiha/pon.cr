FROM crystallang/crystal:0.24.2

RUN apt-get update -qq && apt-get install -y --no-install-recommends libpq-dev libsqlite3-dev libmysqlclient-dev

ADD . /mnt

WORKDIR /mnt

RUN shards update

CMD ["crystal", "spec"]

