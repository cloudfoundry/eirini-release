FROM golang:1.12 as builder
WORKDIR /eirini/
COPY src/code.cloudfoundry.org/eirini .
RUN  CGO_ENABLED=0 GOOS=linux go build -mod vendor -a -installsuffix cgo -o bits-waiter ./cmd/bits-waiter/

FROM scratch

COPY --from=builder /eirini/bits-waiter /bits-waiter
