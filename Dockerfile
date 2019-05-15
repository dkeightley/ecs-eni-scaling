FROM alpine:latest
RUN apk -v --update --no-cache add python py-pip jq bc && \
    pip install --upgrade awscli && \
    apk -v --purge del py-pip && \
    rm -rf /root/.cache/
COPY eni-scaling.sh /eni-scaling.sh
CMD ["./eni-scaling.sh"]
