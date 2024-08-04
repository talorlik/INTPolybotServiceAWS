# The Polybot plus Image processing & detection Service: AWS Project

## Intro

This project is a further expansion on two previous projects:
1. The <a href="https://github.com/talorlik/ImageProcessingService" title="Python Image processing service" target="_blank">Python Image processing service</a>
2. The <a href="https://github.com/talorlik/DockerProject" title="Docker Polybot Service" target="_blank">Docker Polybot Service</a>

To fully understand the functionality involved regarding image filtering, image object detection and the integration with Telegram Bot please read about the above projects.

## AWS Infra

> [!NOTE]
> A full explanation of the Terraform deployment of the infra described below can be read here [Terraform](#terraform)

1. A `VPC` in `us-east-1` or `us-east-2`, containing two Public Subnets, in `us-east-1a` and `us-east-1b` or `us-east-2a` and `us-east-2b` `Availability Zones (AZ)` respectively.
2. The services deployed within these subnets communicate to the world via an `Internet Gateway`, which is attached on the VPC.
3. The `Polybot` service runs as a `Docker` container on two `EC2` machines (`t3.micro`), 1 in each AZ, behind an `Application Load Balancer (ALB)`.
    - I've created a sub-domain under the main `INT` domain `.int-devops.click` and attached it to the ALB.
    - I've created a <a href="https://core.telegram.org/bots/webhooks#a-self-signed-certificate" title="self-signed certificate" target="_blank">self-signed certificate</a> and attached it to my sub-domain for secure communication with the Telegram API.
4. The `Yolo5` service runs as a `Docker` container, starting with a single `EC2` (`t3.medium`) which is instantiated via an `Auto Scaling Group (ASG)`.
    - The ASG is configured to scale up when the CPU reaches 20% utilization **(for testing purposes)**
    - The ASG makes use of a `Launch Template (LT)`, to create the EC2 machines.
      - The LT uses <a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html" title="User Data" target="_blank">User Data</a> to automatically install what is needed and get the latest Docker image from the `ECR` repository and then run the Yolo5 service.
      - The LT is configured to deploy the EC2s inside the above VPC and in the specified subnets.
      - It also makes use of an existing `Key Pair` which is created separately for SSH.
      - It uses its own SG for the Yolo5's EC2 machines (read below).
5. There is a `Security Group (SG)` for the ALB which restricts Inbound traffic to the <a href="https://core.telegram.org/bots/webhooks" title="CIDRs of Telegram servers" target="_blank">CIDRs of Telegram servers</a> on port 8443 only and Outbound to the Security Group of the Polybot's EC2 machines on port 8443 as well.
6. The SG for the Polybot's EC2s, accepts Inbound traffic only from the ALB SG and SSH and Outbound to All.
7. The SG for the Yolo5's EC2s, accepts Inbound traffic only for SSH and Outbound to All.
8. All EC2 machines have Public IP enabled for convenience only, for use with SSH.
9. A `Secret Manager (SM)` which has two secrets in it:
    - Telegram Token
    - Sub-Domain Certificate
10. There are two `SQS Queues`, one for `identify` and one for `results` with which each of the EC2s can put messages into and pull messages from.
11. A `DynamoDB` Table, into which the Image Object Detection results are written and read from.
12. An `S3 Bucket`, which holds the images which are to be identified and then the resulted images.
13. I've created an `IAM Role`, with an inline policy, which follows the `Least Privilege` principle and only grants the absolute necessary permissions to the EC2s.
    - For the Polybot the role is attached to the two machines
    - for the Yolo5 the role is part of the LT configuration and each machine that is created gets it.
14. I use the latest Ubuntu 24.04 `AMI`. I use this image for the creation of all the EC2s in this project.

![][architecture]

## Basic Flow

1. The user uploads an image on the Telegram App and puts a caption of `predict`.
2. The Polybot service picks up the message and handles it by instantiating the `ObjectDetectionBot`.
3. The image is then uploaded to S3 and a message with the `chatId` and `imgName` to the `identify` SQS Queue.
4. The Yolo5 service polls the identify SQS Queue for incoming messages. Once a message is picked up, it gets the `imgName`, downloads it from S3 and the detection process kicks in.
5. The resulted image is uploaded back to S3 and the summary is save to DynamoDB. A message containing either a failure or success details is sent to the `results` SQS Queue.
6. The Polybot service polls the results SQS Queue for incoming results messages. Once a message is picked up it gets the `prediction_id`, queries the DynamoDB, gets the output from the prediction, parses the output, gets the image name and downloads it from S3, sends responds back to the user with the image and a readable summary of what was found.

## Directory structure

```console
.
├── .github
│   └── workflows
│       ├── backend-state-destroying.yaml
│       ├── backend-state-provisioning.yaml
│       ├── infra-destroying.yaml
│       ├── infra-provisioning-main.yaml
│       ├── infra-provisioning-region.yaml
│       ├── polybot-deployment.yaml
│       └── yolo5-deployment.yaml
├── .gitignore
├── AWS_Project.jpg
├── LICENSE
├── README.md
├── load_test.py
├── polybot
│   ├── .dockerignore
│   ├── Dockerfile
│   ├── __init__.py
│   ├── ansible
│   │   ├── ansible.cfg
│   │   ├── aws_ec2.yaml
│   │   └── playbook.yaml
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
├── tf_backend_state
│   ├── .gitignore
│   ├── .terraform.lock.hcl
│   ├── dev.tfvars
│   ├── main.tf
│   ├── prod.tfvars
│   ├── providers.tf
│   ├── terraform.plan
│   ├── terraform.tfstate
│   └── variables.tf
├── tf_infra
│   ├── .gitignore
│   ├── .terraform.lock.hcl
│   ├── main.tf
│   ├── modules
│   │   ├── dynamodb
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   └── variables.tf
│   │   ├── ec2-key-pair
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   └── variables.tf
│   │   ├── ecr-and-policy
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   └── variables.tf
│   │   ├── iam-role-and-policy
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   ├── policy_template.tftpl
│   │   │   └── variables.tf
│   │   ├── polybot
│   │   │   ├── deploy.sh
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   └── variables.tf
│   │   ├── secret-manager
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   └── variables.tf
│   │   ├── sqs-queue
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   └── variables.tf
│   │   ├── sub-domain-and-cert
│   │   │   ├── generate_certificate.sh
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   └── variables.tf
│   │   └── yolo5
│   │       ├── deploy.sh.tftpl
│   │       ├── main.tf
│   │       ├── outputs.tf
│   │       └── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── region.us-east-1.tfvars
│   ├── region.us-east-2.tfvars
│   └── variables.tf
└── yolo5
    ├── .dockerignore
    ├── Dockerfile
    ├── ansible
    │   ├── ansible.cfg
    │   ├── aws_ec2.yaml
    │   └── playbook.yaml
    ├── app.py
    ├── prediction_cleanup.sh
    ├── requirements.txt
    └── yolo_utils.py
```

## General Technical Details

### Polybot

* In the Python code I'm using Threading. When the application starts two threads get initiated, one for the Bot to poll the `results` SQS Queue and one for the Bot to poll an internal Python Queue for incoming messages from the Telegram app.
* Both threads are getting a single instance of the `bot_factory` so that the same bot setup is used in both. Both threads also get the app to maintain context for globally declared values.
* The secrets i.e. the Telegram Token and Domain Certificate are pulled from AWS Secret Manager and used in the code but are not saved anywhere thus improving security.
* The Polybot Dockerfile no longer uses the UWSGI server. It now makes use of regular Flask server. The reason for this has to do with my use of threading which didn't work with the UWSGI.
* The container is run with the `--restart always` flag so that when that machine stops and starts or restarts for some reason, the container will immediately start as well.

### Yolo5

* The yolo5 service polls the `identify` SQS Queue for incoming messages placed there by the `Polybot` service.
* I've decoupled the services by introducing an additional SQS Queue so that the Yolo5 doesn't make a POST request to the Polybot directly (via the ALB) but rather place a message in the `results` queue.
* In order to prevent container bloat, I've created a cleanup bash script, `prediction_cleanup.sh`, which I run as a cron service in the background inside the container. It deletes all the prediction files and images that are older than 2 minutes.
  - I added this to the `Dockerfile`.
* The container is run with the `--restart always` flag so that when that machine stops and starts or restarts for some reason, the container will immediately start as well.

> [!NOTE]
> I've discovered that with the existing architecture the `concat` image filtering functionality doesn't work because for every image in the group Telegram makes a separate HTTP request causing the ALB to route the second request to the second machine thus making it "loose" state.
> In order to resolve this some additional component has to be introduced, perhaps Redis or another Table in DynamoDB.

## Testing

1. I created a bash script, `load_test.sh` which sends messages directly to the identify SQS Queue. The images must be pre-loaded to S3 and the image name list must be updated in the script itself. This simulates increased traffic.
2. Navigate to the **CloudWatch** console, observe the metrics related to CPU utilization for your Yolo5 instances. You should see a noticeable increase in CPU utilization during the period of increased load.
3. After ~3 minutes, as the CPU utilization crosses the threshold of 60%, **CloudWatch alarms** will be triggered.
   Check your ASG size, you should see that the desired capacity increases in response to the increased load.
4. After approximately 15 minutes of reduced load, CloudWatch alarms for scale-in will be triggered.

## Terraform

### Backend State

> [!IMPORTANT]
> This has to be deployed prior to the main project else the init will not work.

In order to manage the Terraform state one has to create the backend infra which includes the S3 bucket `talo-tf-s3-tfstate` for the state file itself and DynamoDB Table `talo-tf-terraform-lock-table` for the locking mechanism so prevent deployment from multiple sources, overriding each other.

I've created a separate Terraform deployment for this purpose in the `tf_backend_state` directory. It creates the above mentioned services with the relevant failure and security configurations, such as versioning and encryption on the bucket. Also, both the S3 and the DynamoDB Table get least privilege Service Policies allowing only myself to execute specific actions on them.

### Main Project

The main project's infrastructure deployment is in the `tf_infra` directory.
Here I've follow TF best practices:
1. Making use of modules to create clear and easy to manage separation of the various components making up the whole project.
2. Each module has it's own main, variables and outputs.
3. Separating variables from their values so that it's easy to alter values and redeploy.
4. Separating the outputs.
5. Names are dynamically created per region and environment to prevent any possible clash.
6. All services and elements that make them up are tagged

The modules are in two categories:
1. Global modules which are not service specific or are shared amongst multiple services.
2. Custom modules which are made of a group of resources for a specific service.

I've made use of both modules which are ready made from the official AWS Terraform repository and some which I've custom built for this project's specific needs.

#### Module Breakdown

1. Root main - Calls all other modules.
    - It makes use of a `data` resource to get the available AZs for the region.
    - It uses the [terraform-aws-ami-ubuntu](https://github.com/andreswebs/terraform-aws-ami-ubuntu) to get the latest Ubuntu 24.04 distribution.
    - Has some declared locals for names, AZs, AMI and tags
    - All values are passed in and then "trickle-in" to the relevant modules.
    - Certain values come directly from outputs of modules
2. [VPC](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest) - Creates all relevant services for the VPC, such as:
    - Subnets
    - Route tables
    - Security groups
    - Network connections
3. [S3](https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/latest) - Creates and configures the bucket
4. [Route53 - Sub Domain and Certificate](tf_infra/modules/sub-domain-and-cert/) - Creates a Self-Signed Certificate of which values are injected dynamically through the CI/CD inputs. It then creates an A Record under the main College domain using that certificate. It uses a `aws_route53_zone` data source to get information regarding the main domain.
5. [Secret Manager](tf_infra/modules/secret-manager/) - I've made generic so that multiple secrets can be created with it. It's able to create either `plain text` or `key-value` secrets depending on the value that is passed into it.
    - In my case, two secrets are created: one for the Telegram Token as key-value and one is the sub-domain certificate which I later pull for use in the Python code
6. [SQS](tf_infra/modules/sqs-queue/) - I've made it generic so that multiple queues can be created with it.
    - In my case, two queues are created: one for the `identify` and one for the `results`
7. [DynamoDB](tf_infra/modules/dynamodb/) - Creates the Dynamo DB Table with it's partition key and indexes based on values sent passed in.
8. [ECR and Lifecycle Policy](tf_infra/modules/ecr-and-policy/) - Creates an ECR Repository and Lifecycle Policy to be used to store the Docker images I build either manually or through the CI/CD process.
    - In my case the lifecycle policy only keeps one copy (the latest one) of each docker image and only keeps 1 untagged image for 'caching'
9. [IAM Role and Policy](tf_infra/modules/iam-role-and-policy/) - Creates the IAM Role with the Policy that is needed to give permissions to the different services to talk to each other. It makes use of a `policy_template.tftpl` and dynamically replaces all the ARN placeholders which are retrieved from the other modules and passed in.
10. [EC2 Key Pair](tf_infra/modules/ec2-key-pair/) - It creates an SSH Key Pair which I then use to be able to SSH into all the EC2 machines created in this project. It also saves both private and public keys physically as files as I later upload them as artifacts so that they can be downloaded and used.
11. [Polybot](tf_infra/modules/polybot/) - It creates all the relevant components which make up the Polybot service such as:
    - **EC2** per AZ and uses the `deploy.sh` file for the `user_data` to install things which are needed in order for things to work.
    - [Application Load Balancer (ALB)](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest) using the official AWS module. It creates all the relevant resources such as:
      - Security Group for the ALB
      - Listeners
      - Target Groups and Health Checks
    - Security Group for the EC2s
12. [Yolo5](tf_infra/modules/yolo5/) - It creates all the relevant components which make up the Yolo5 service such as:
    - Security Group for the EC2s
    - Launch Template with all the relevant configurations.
      - The launch template makes use of `deploy.sh.tftpl` file for the user_data into which values are passed in dynamically.
    - Auto Scaling Group and Policy
    - SNS Topic for scaling event notifications

## CI/CD pipeline with GitHub Actions

### Backend State

* I created two manually triggered workflows
  - [Provision](.github/workflows/backend-state-provisioning.yaml)
  - [Destroy](.github/workflows/backend-state-destroying.yaml)

### Main Project

#### Infra

* The Infra deployment consists of three workflows
  - [Main](.github/workflows/infra-provisioning-main.yaml) which triggers the next one
  - [Region Specific](.github/workflows/infra-provisioning-region.yaml)
  - [Destroy](.github/workflows/infra-destroying.yaml)

##### Infra Breakdown

**Main**
* The main workflow takes inputs for the region, sub-domain details and environment.
* Based on the region selection it passes onto the next workflow the correct Telegram Token which is saved in GitHub Secrets.

**Region Sepccific**
* Takes in the incoming values from the main workflow.
* Sets up Terraform, initializes it, selects workspace, plans and applies.
* Once the Terraform provisioning is done it captures the paths of the SSH private and public keys from the outputs and uploads them as Artifacts for later use.
* It also captures all of the Terraform outputs into a file and uploads it as Artifacts for use in following workflows.

**Destroy**
* The destroy workflow captures the latest successful `run_id` from the main workflow using GitHub API command and sets it as GitHub outputs for use in following job
* It uses the `run_id` output to download the Terraform outputs file from the Artifacts.
* It uses jq to extract values from the outputs file and sets them as GitHub outputs for use in following job
* The last job sets up Terraform, captures the correct Telegram Token from GitHub Secrets based on the region, initializes it, selects workspace, plans and applies using the values that were passed down

#### Services

* There are two services, namely: `Polybot` and `Yolo5` each deployed on manual trigger with their respective workflows:
  - [Polybot](.github/workflows/polybot-deployment.yaml)
  - [Yolo5](.github/workflows/yolo5-deployment.yaml)
* Both workflows are structured similarly:
  - Each consists of two jobs, namely: `Build` and `Deploy`.
  - In the Build job it builds a new Docker image and pushes it to the ECR.
  - In the Deploy job I've made use of `Ansible` to deploy the application's new image on the machines and run the docker container.
  - I'm using the `aws_ec2` Ansible plugin to dynamically build the inventory base on Tags that I've assigned to the Polybot and Yolo5 EC2 machines, `APP=talo-polybot` and `APP=talo-yolo5` respectively.

[architecture]: https://github.com/talorlik/INTPolybotServiceAWS/blob/main/AWS_Project.jpg
