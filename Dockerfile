FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y tzdata && \
    ln -fs /usr/share/zoneinfo/Europe/Vilnius /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    apt-get install -y \
        apache2 \
        build-essential \
        ffmpeg \
        mysql-client \
        php \
        php-mysql \
        zoneminder && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy and modify the ZoneMinder database creation script
RUN cp /usr/share/zoneminder/db/zm_create.sql /zm_create.sql && \
    sed -i 's/CREATE TABLE /CREATE TABLE IF NOT EXISTS /g' /zm_create.sql

# Copy startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80

CMD ["/start.sh"]
