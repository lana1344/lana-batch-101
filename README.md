# AWS Batch Workshop

This workshop demonstrates AWS Batch with Fargate for container-based image processing jobs.
Original workshop source: https://catalog.us-east-1.prod.workshops.aws/workshops/81ff4a6e-0a3c-41d4-be17-6ffc942d6451/en-US
It has been tested from AWS account, lanaaa+app-dev@amazon.com in Oregon region.

## Prerequisites

- AWS CLI configured with appropriate permissions
- Docker installed locally
- VPC with public subnets and security groups

## Deployment Steps

### 1. Deploy AWS Infrastructure

The template now includes default values for VPC, subnets, and security groups, so you can deploy without parameters if using the defaults:

```bash
aws cloudformation deploy \
  --template-file lana-batch-101.yaml \
  --stack-name lana-batch-101 \
  --capabilities CAPABILITY_NAMED_IAM
```

Or override with your own values:

```bash
aws cloudformation deploy \
  --template-file lana-batch-101.yaml \
  --stack-name lana-batch-101 \
  --parameter-overrides \
    VpcId=vpc-04ef49f6455cd32b9 \
    SubnetIds=subnet-004543c70f3124880,subnet-07fb107b05cc4f4f6 \
    SecurityGroupIds=sg-051abebf86a637480 \
  --capabilities CAPABILITY_NAMED_IAM
```

### 2. Upload Source Code and Build Container Image

```bash
# Create zip file and upload to S3
cd make-gif && zip -o ../make-gif.zip * && cd ..
# Upload the source code to S3
aws s3 cp make-gif.zip s3://$(aws cloudformation describe-stacks --stack-name lana-batch-101 --query 'Stacks[0].Outputs[?OutputKey==`BatchWorkshopBucketName`].OutputValue' --output text)/make-gif.zip

# Start CodeBuild to build and push Docker image
aws codebuild start-build --project-name $(aws cloudformation describe-stacks --stack-name lana-batch-101 --query 'Stacks[0].Outputs[?OutputKey==`CodeBuildProjectName`].OutputValue' --output text)
```

This will:
- Upload the make-gif source code to S3
- Trigger CodeBuild to build and push the Docker image to ECR

### 3. Verify Deployment

```bash
# Check Batch resources
aws batch describe-compute-environments --compute-environments learn-awsbatch-ce
aws batch describe-job-queues --job-queues lana-batch-101-jq
aws batch describe-job-definitions --job-definition-name copy-to-s3
aws batch describe-job-definitions --job-definition-name make-gif

# Check ECR image
aws ecr describe-images --repository-name lana-batch-101-make-gif
```

## Resources Created

- S3 bucket for file storage
- ECR repository for container images
- CodeBuild project for building Docker images
- Batch compute environment (Fargate)
- Batch job queue and job definitions
- IAM roles and policies

## Submit Jobs and View Results

### Setup Environment Variables

```bash
# Set environment variables for job submission
export BATCH_WS_BUCKET=$(aws cloudformation describe-stacks --stack-name lana-batch-101 --query 'Stacks[0].Outputs[?OutputKey==`BatchWorkshopBucketName`].OutputValue' --output text)
```

### Copy Images to S3

```bash
aws batch submit-job --job-name 'copy-img-1' \
  --job-queue 'lana-batch-101-jq' \
  --job-definition 'copy-to-s3' \
  --parameters Source='https://static.us-east-1.prod.workshops.aws/public/20d4c8cb-bdf5-46c0-b536-eca634717c8e/static/images/console-fargate/examples/make-gif/batch-101-make-gif-01.jpeg',Destination="s3://${BATCH_WS_BUCKET}/input/01.png"

aws batch submit-job --job-name 'copy-img-2' \
  --job-queue 'lana-batch-101-jq' \
  --job-definition 'copy-to-s3' \
  --parameters Source='https://static.us-east-1.prod.workshops.aws/public/20d4c8cb-bdf5-46c0-b536-eca634717c8e/static/images/console-fargate/examples/make-gif/batch-101-make-gif-02.jpeg',Destination="s3://${BATCH_WS_BUCKET}/input/02.png"

aws batch submit-job --job-name 'copy-img-3' \
  --job-queue 'lana-batch-101-jq' \
  --job-definition 'copy-to-s3' \
  --parameters Source='https://static.us-east-1.prod.workshops.aws/public/20d4c8cb-bdf5-46c0-b536-eca634717c8e/static/images/console-fargate/examples/make-gif/batch-101-make-gif-03.jpeg',Destination="s3://${BATCH_WS_BUCKET}/input/03.png"

aws batch submit-job --job-name 'copy-img-4' \
  --job-queue 'lana-batch-101-jq' \
  --job-definition 'copy-to-s3' \
  --parameters Source='https://static.us-east-1.prod.workshops.aws/public/20d4c8cb-bdf5-46c0-b536-eca634717c8e/static/images/console-fargate/examples/make-gif/batch-101-make-gif-04.jpeg',Destination="s3://${BATCH_WS_BUCKET}/input/04.png"
```

### Check Job Status

```bash
aws batch list-jobs --job-queue lana-batch-101-jq
```

### Create Animated GIF

Once the copy jobs are complete, submit the make-gif job:

```bash
aws batch submit-job --job-name 'make-gif-1' \
  --job-queue 'lana-batch-101-jq' \
  --job-definition 'make-gif' \
  --parameters Source="s3://${BATCH_WS_BUCKET}/input/",Destination="s3://${BATCH_WS_BUCKET}/output/myCoolGif.gif"
```

### View Results

Once complete, download and view the GIF from the S3 console or using:

```bash
aws s3 cp s3://${BATCH_WS_BUCKET}/output/myCoolGif.gif ./myCoolGif.gif
```

## Cleanup

```bash
aws cloudformation delete-stack --stack-name lana-batch-101
```
