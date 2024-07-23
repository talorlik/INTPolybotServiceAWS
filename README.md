# The Polybot plus Image processing & detection Service: AWS Project

## Intro

This project is a further expansion on two previous projects:
1. The <a href="https://github.com/talorlik/ImageProcessingService" title="Python Image processing service" target="_blank">Python Image processing service</a>
2. The <a href="https://github.com/talorlik/DockerProject" title="Docker Polybot Service" target="_blank">Docker Polybot Service</a>

To fully understand the functionality involved regarding image filtering, image object detection and the integration with Telegram Bot please read about the above projects.

## AWS Infra

1. A `VPC`, `talo-vpc`, containing two Public Subnets, `talo-public-subnet` and `talo-public-subnet-2` in `us-east-1a` and `us-east-1b` `Availability Zones (AZ)` respectively.
2. The services deployed within these subnets communicate to the world via an `Internet Gateway`, `talo-igw`, which is attached on the VPC.
3. The `Polybot` service runs as a `Docker` container on two `EC2` machines (`t3.micro`), `talo-ec2-polybot-1` and `talo-ec2-polybot-2` respectively (1 in each AZ), behind an `Application Load Balancer (ALB)`, `talo-alb`.
    - I've created a sub-domain, `talo-polybot.int-devops.click` under the main `INT` domain and attached it to the ALB.
    - I've created a <a href="https://core.telegram.org/bots/webhooks#a-self-signed-certificate" title="self-signed certificate" target="_blank">self-signed certificate</a> and attached it to my sub-domain for secure communication with the Telegram API.
4. The `Yolo5` service runs as a `Docker` container, starting with a single `EC2` (`t3.medium`) which is instantiated via an `Auto Scaling Group (ASG)`.
    - The ASG is configured to auto scale when the CPU reaches 20% utilization (for testing purposes)
    - The ASG makes use of a `Launch Template (LT)`, `talo-launch-template`, to create the EC2 machines.
      - The LT uses <a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html" title="User Data" target="_blank">User Data</a> to automatically get the latest Docker image from the `ECR` repository `talo-docker-images` and then run the Yolo5 service.
      - The LT is configured to deploy the EC2s inside the above VPC and in the specified subnets.
      - It also makes use of an existing `Key Pair`, `talo-key-pair` for SSH.
      - It uses the same SG as the Polybot's EC2 machines (read below).
5. There is a `Security Group (SG)` for the ALB `talo-alb-sg` which restricts Inbound traffic to the <a href="https://core.telegram.org/bots/webhooks" title="CIDRs of Telegram servers" target="_blank">CIDRs of Telegram servers</a> on port 8443 only and Outbound to the Security Group of the EC2 machines on port 8443 as well.
6. The SG for the EC2s, `talo-public-sg` accepts Inbound traffic only from the ALB SG and Outbound to All.
7. All EC2 machines have Public IP enabled for convenience only, for use with SSH.
8. A `Secret Manager (SM)` which has two secrets in it: `talo/telegram/token` and `talo/sub-domain/certificate`.
9. There are two `SQS Queues`, `talo-sqs-identify` and `talo-sqs-results` with which each of the EC2s can put messages into and pull messages from.
10. A `DynamoDB`, `talo-prediction-results` into which the Image Object Detection results are written and read from.
11. An `S3 Bucket`, `talo-s3` which holds the images which are to be identified and then the resulted images.
12. I've created an `IAM Role`, `talo-ec2-role` with an inline policy `talo-ec2-policy` which follows the `Least Privilege` principle and only grants the absolute necessary permissions to the EC2s.
    - For the Polybot the role is attached to the two machines
    - for the Yolo5 the role is part of the LT configuration and each machine that is created gets it.
13. I created an `AMI` which is Ubuntu based and has everything I need already installed. I use this image for the creation of all the EC2s in this project.

![][architecture]

## Basic Flow

1. The user uploads an image on the Telegram App and puts a caption of `predict`.
2. The Polybot service picks up the message and handles it by instantiating the `ObjectDetectionBot`.
3. The image is then uploaded to S3 and a message with the `chatId` and `imgName` to the `talo-sqs-identify` SQS Queue.
4. The Yolo5 service polls the identify SQS Queue for incoming messages. Once a message is picked up, it gets the `imgName`, downloads it from S3 and the detection process kicks in.
5. The resulted image is uploaded back to S3 and the summary is save to DynamoDB. A message containing either a failure or success details is sent to the `talo-sqs-results` SQS Queue.
6. The Polybot service polls the results SQS Queue for incoming results messages. Once a message is picked up it gets the `prediction_id`, queries the DynamoDB, gets the output from the prediction, parses the output, gets the image name and downloads it from S3, sends responds back to the user with the image and a readable summary of what was found.

## Directory structure

```console
.
├── AWS_Project.jpg
├── LICENSE
├── README.md
├── load_test.py
├── polybot
│   ├── Dockerfile
│   ├── __init__.py
│   ├── ansible
│   │   ├── ansible.cfg
│   │   ├── aws_ec2.yaml
│   │   └── playbook.yaml
│   ├── pushrefresh.txt
│   ├── python
│   │   ├── __init__.py
│   │   ├── bot.py
│   │   ├── bot_utils.py
│   │   ├── flask_app.py
│   │   ├── img_proc.py
│   │   ├── process_messages.py
│   │   ├── process_results.py
│   │   └── requirements.txt
│   ├── uwsgi.ini
│   └── wsgi.py
└── yolo5
    ├── Dockerfile
    ├── ansible
    │   ├── ansible.cfg
    │   ├── aws_ec2.yaml
    │   └── playbook.yaml
    ├── app.py
    ├── prediction_cleanup.sh
    ├── pushrefresh.txt
    ├── requirements.txt
    └── yolo_utils.py
```

## General Technical Details

### Polybot

* In the Python code I'm using Threading. When the application starts two threads get initiated, one for the Bot to poll the SQS Queue for results and one for the Bot to poll an internal Python Queue for incoming messages from the Telegram app.
* Both threads are getting a single instance of the bot_factory so that the same bot setup is used in both. Both threads also get the app to maintain context for globally declared values.
* The secrets i.e. the Telegram Token and Domain Certificate are pulled from AWS Secret Manager and used in the code but are not saved anywhere thus improving security.
* The Polybot Dockerfile no longer uses the UWSGI server. It now makes use of regular Flask server. The reason for this has to do with my use of threading which didn't work with the UWSGI.
* The container is run with the `--restart always` flag so that when that machine stops and starts or restarts for some reason, the container will immediately start as well.

### Yolo5

* The yolo5 service no longer uses Flask server to run as it's not only "listening" to incoming messages from the "identify" SQS Queue.
* I've decoupled the services by introducing an additional SQS Queue so that the Yolo5 doesn't have to make a POST request to the Polybot directly (via the ALB) but rather place a message in the new queue.
* In order to prevent container bloat, I've created a cleanup bash script which I run as a cron service in the background. It deletes all the prediction files and images that are older than 2 minutes.
  - I added this to the Dockerfile
* The container is run with the `--restart always` flag so that when that machine stops and starts or restarts for some reason, the container will immediately start as well.

> **NOTE:** I've discovered that with the existing architecture the `concat` image filtering functionality doesn't work because for every image in the group Telegram makes an HTTP request causing the ALB to route the second request to the second machine thus making it "loose" state.
> In order to resolve this some additional component has to be introduced, perhaps Redis or another Table in DynamoDB.

## Testing

1. I created a bash script, `load_test.sh` which sends messages directly to the identify SQS Queue. The images must be pre-loaded to S3 and the image name list must be updated in the script itself. This simulates increased traffic.
2. Navigate to the **CloudWatch** console, observe the metrics related to CPU utilization for your Yolo5 instances. You should see a noticeable increase in CPU utilization during the period of increased load.
3. After ~3 minutes, as the CPU utilization crosses the threshold of 60%, **CloudWatch alarms** will be triggered.
   Check your ASG size, you should see that the desired capacity increases in response to the increased load.
4. After approximately 15 minutes of reduced load, CloudWatch alarms for scale-in will be triggered.

## CI/CD pipeline with GitHub Actions

* I created two GitHub Workflows, one for the Polybot, `.github/workflows/polybot-deployment.yaml` and one for the Yolo5 `.github/workflows/yolo5-deployment.yaml`.
* Each is triggered upon push action to the `main` branch to their respective directories (`polybot` and `yolo5`)ץ
* Each consists of two jobs, namely: `Build` and `Deploy`.
* In the Build job it build a new Docker image and pushes it to the ECR.
* In the Deploy job I've made use of Ansible to deploy the application's new image on the machines and run the docker container.
  - I'm using the aws_ec2 Ansible plugin to dynamically build the inventory base on Tags that I've assigned to the Polybot and Yolo5 EC2 machines, `APP=talo-polybot` and `APP=talo-yolo5` respectively.


[architecture]: https://github.com/talorlik/INTPolybotServiceAWS/blob/main/AWS_Project.jpg
