FROM ubuntu:latest

RUN apt-get update && apt-get install vim curl -y

COPY eirinifs.tar /workspace/jobs/registry/
COPY opi /workspace/jobs/registry/bin/


ENTRYPOINT [ "/workspace/jobs/registry/bin/opi", \
    "registry", \
    "--rootfs", \
		"/workspace/jobs/registry/eirinifs.tar", \
		"--cert", \
		"/workspace/jobs/certs/ca.crt", \
		"--key", \
		"/workspace/jobs/certs/domain.key" \
]
