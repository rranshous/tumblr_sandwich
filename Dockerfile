FROM ruby:2.2.0
MAINTAINER "Robby Ranshous <rranshous@gmail.com>"

WORKDIR /app
ENV OUTDIR /data
ENV CACHEDIR /cache
COPY ./ /app
RUN bundle install
RUN mkdir /data
RUN mkdir /cache

ENTRYPOINT ["bundle", "exec", "ruby", "package_blog.rb"]
