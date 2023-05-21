# Build frontend
FROM node:lts-alpine AS frontend-build-stage
RUN corepack enable && corepack prepare yarn@stable --activate
WORKDIR /build
COPY ./go-vhost-frontend/ .
RUN yarn install && yarn build

# Build the backend binary
FROM golang:latest AS backend-build-stage
WORKDIR /build
COPY ./go-vhostd/ .
COPY --from=frontend-build-stage /build/build/ ./html/
RUN go build -tags netgo -ldflags "-s -w" -trimpath -o go-vhostd

# Deploy the application binary into a lean image
FROM alpine:latest AS release-stage
COPY --from=backend-build-stage /build/go-vhostd /usr/bin/
VOLUME /data
WORKDIR /data
COPY --from=backend-build-stage /build/config.yaml .
ENTRYPOINT ["go-vhostd"]