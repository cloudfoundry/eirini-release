FROM ubuntu:latest

RUN apt-get update && apt-get install vim curl -y

COPY opi /workspace/jobs/opi/bin/

ENTRYPOINT [ "/workspace/jobs/opi/bin/opi", \
	"connect", \
	"--config", \
	"/workspace/jobs/opi/config/opi.yml" \
]
