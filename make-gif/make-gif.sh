#!/bin/bash 
# make a temp directory for this job
tmp_dir=$(mktemp -d -t make-gif-XXXXXXXXXX)
cd $tmp_dir

# pull pictures from S3 source
aws s3 sync $1 .

# create the gif
convert -delay 50 -loop 0 * movie.gif

# upload it back to s3
aws s3 cp movie.gif $2
