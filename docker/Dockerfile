FROM nginx:1.19

RUN set -x \
    && apt-get update \
    && apt-get install -y unzip \    
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    &&  apt-get install -y iputils-ping

COPY ./copy_s3_file.sh /docker-entrypoint.d

