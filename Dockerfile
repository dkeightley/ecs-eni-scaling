FROM alpine:latest
RUN apk -v --update --no-cache add python py-pip jq bc && \
    pip install --upgrade awscli && \
    apk -v --purge del py-pip && \
    rm -rf /root/.cache/
COPY eni-metric.sh /eni-metric.sh
CMD ["./eni-metric.sh"]
