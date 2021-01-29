FROM crystallang/crystal:0.35.1-alpine
RUN apk add --no-cache libxml2-dev postgresql-dev mariadb-dev sqlite-dev
