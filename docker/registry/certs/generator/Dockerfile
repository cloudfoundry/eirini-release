FROM alpine:latest

RUN apk add --no-cache curl bash openssl

# This should download the latest stable version of kubectl
# It's not great from a provenance pov, but it's basically the same as the
# official instructions
RUN curl -o /usr/local/bin/kubectl -sSL https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && chmod +x /usr/local/bin/kubectl

COPY generate.sh /
RUN chmod +x /generate.sh

ENTRYPOINT [ "/bin/bash", "-c", "/generate.sh" ]
