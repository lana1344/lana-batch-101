FROM public.ecr.aws/amazonlinux/amazonlinux:latest

RUN yum install -y ImageMagick unzip glibc-devel less groff

RUN cd /tmp &&\
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
  unzip awscliv2.zip && \
  ./aws/install

COPY copy-to-s3.sh /usr/local/bin/copy-to-s3.sh
COPY make-gif.sh /usr/local/bin/make-gif.sh
