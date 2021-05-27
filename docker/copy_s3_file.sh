#!/bin/bash

echo "S3_METADATA:" $S3_METADATA

aws s3 cp $S3_METADATA /usr/share/nginx/html/index.html

ping -c 5 www.google.com >> /usr/share/nginx/html/index.html

exit 0