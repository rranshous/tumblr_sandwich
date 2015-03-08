FROM ruby:2.2.0
MAINTAINER "Robby Ranshous <rranshous@gmail.com>"

WORKDIR /app
COPY ./ /app
RUN bundle install

ENTRYPOINT ["bundle", "exec", "ruby", "package_blog.rb"]
