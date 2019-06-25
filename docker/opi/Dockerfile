FROM golang:1.12 as builder
WORKDIR /eirini/
COPY src/code.cloudfoundry.org/eirini .
RUN  CGO_ENABLED=0 GOOS=linux go build -mod vendor -a -installsuffix cgo -o eirini ./cmd/opi/

FROM scratch
COPY --from=builder /eirini/eirini /workspace/jobs/opi/bin/opi
ENTRYPOINT [ "/workspace/jobs/opi/bin/opi", \
	"connect", \
	"--config", \
	"/workspace/jobs/opi/config/opi.yml" \
]
