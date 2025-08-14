FROM alpine:3.19

RUN apk add --no-cache curl tar && \
    curl -L https://github.com/aquasecurity/trivy/releases/download/v0.51.2/trivy_0.51.2_Linux-64bit.tar.gz -o trivy.tar.gz && \
    tar -xzf trivy.tar.gz && \
    mv trivy /usr/local/bin/trivy && \
    rm -rf trivy.tar.gz

WORKDIR /scan

CMD ["sh"]