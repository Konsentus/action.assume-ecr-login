FROM docker:19

ADD entrypoint.sh /entrypoint.sh

RUN apk add --no-cache bash jq python3 py3-pip \
  && pip3 install awscli

ENTRYPOINT ["/entrypoint.sh"]
