FROM nginx:latest
RUN apt-get -qq update && apt-get install -y bash

RUN rm -rf /etc/nginx/*
ADD wait-for /usr/bin
ADD setupscript /
ADD new-site /usr/bin

ENTRYPOINT ["/setupscript"]