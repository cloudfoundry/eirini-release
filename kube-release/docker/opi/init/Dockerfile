FROM library/python:3.6-jessie

RUN apt-get update && \
    apt-get install --yes \
        wget \
        curl
RUN wget --quiet --output-document /usr/bin/goml https://github.com/JulzDiverse/goml/releases/download/v0.4.0/goml-linux-amd64 && chmod +x /usr/bin/goml
COPY init.sh /
RUN chmod +x /init.sh

ENTRYPOINT /init.sh
