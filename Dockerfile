FROM mysql:8.0.33

LABEL maintainer="nekoimi <nekoimime@gmail.com>"

ENV TZ Asia/Shanghai

COPY start.sh /start.sh

RUN chmod +x start.sh

WORKDIR /opt/backup

ENTRYPOINT ["/start.sh"]

CMD ["ignore"]