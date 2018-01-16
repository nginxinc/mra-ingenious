FROM ruby:2.5-alpine
MAINTAINER NGINX Professional Services <support@nginxps.com>

# install Ruby
RUN apk update

# install fake-s3
RUN gem install fakes3 -v 1.2.1

# run fake-s3
RUN mkdir -p /fakes3_root && \
    which fakes3
ENTRYPOINT ["fakes3"]
CMD ["-r",  "/fakes3_root", "-p",  "4569"]
EXPOSE 4569
