#!/bin/bash 
# make a temp directory for this job
tmp_dir=$(mktemp -d -t copy-to-s3-XXXXXXXXXX)
cd $tmp_dir

# pull pictures from source
curl -o src_image $1

# upload to given S3 key
aws s3 cp src_image $2
