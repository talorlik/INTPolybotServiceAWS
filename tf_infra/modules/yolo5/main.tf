locals {
  yolo5_sg_name           = "${var.prefix}-${var.yolo5_sg_name}-${var.env}"
  launch_template_name    = "${var.prefix}-${var.launch_template_name}-${var.env}"
  ec2_name                = "${var.prefix}-${var.instance_name}-${var.env}"
  asg_name                = "${var.prefix}-${var.asg_name}-${var.env}"
  sns_topic_name          = "${var.prefix}-${var.sns_topic_name}-${var.env}"
  autoscaling_policy_name = "${var.prefix}-${var.autoscaling_policy_name}-${var.env}"
  # Using a template to dynamically generate the userdata deployment script
  user_data               = templatefile("${path.module}/deploy.sh.tftpl", {
    region                 = var.region
    identify_queue_name    = var.identify_queue_name
    results_queue_name     = var.results_queue_name
    s3_bucket_name         = var.s3_bucket_name
    s3_bucket_prefix       = var.s3_bucket_prefix
    table_name             = var.table_name
    ecr_name               = var.ecr_name
    ecr_repository_url     = var.ecr_repository_url
    image_prefix           = var.image_prefix
  })
}

################## Security Groups ########################
resource "aws_security_group" "yolo5_ec2_sg" {
  name   = local.yolo5_sg_name
  vpc_id = var.vpc_id

  # Dynamic Ingress rules
  dynamic "ingress" {
    for_each = var.ec2_sg_ingress_rules
    content {
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = try(ingress.value.cidr_blocks, null)
      security_groups = try(ingress.value.security_groups, null)
    }
  }

  # Dynamic Egress rules
  dynamic "egress" {
    for_each = var.ec2_sg_egress_rules
    content {
      from_port       = egress.value.from_port
      to_port         = egress.value.to_port
      protocol        = egress.value.protocol
      cidr_blocks     = try(egress.value.cidr_blocks, null)
      security_groups = try(egress.value.security_groups, null)
    }
  }

  tags = merge(
    {
      Name = local.yolo5_sg_name
    },
    var.tags
  )
}

################## Launch Template ########################
resource "aws_launch_template" "launch_template" {
  name                   = local.launch_template_name
  description            = var.launch_template_description
  image_id               = var.ami
  instance_type          = var.instance_type

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  # vpc_security_group_ids = [aws_security_group.yolo5_ec2_sg.id]
  key_name               = var.key_pair_name
  user_data              = base64encode(local.user_data)
  ebs_optimized          = var.ebs_optimized
  update_default_version = var.update_default_version

  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings
    content {
      device_name = block_device_mappings.value.device_name

      dynamic "ebs" {
        for_each = block_device_mappings.value.ebs != null ? [block_device_mappings.value.ebs] : []
        content {
          delete_on_termination = try(ebs.value.delete_on_termination, true)
          iops                  = try(ebs.value.iops, null)
          volume_size           = try(ebs.value.volume_size, null)
          volume_type           = try(ebs.value.volume_type, null)
        }
      }
    }
  }

  monitoring {
    enabled = var.monitoring.enabled
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.yolo5_ec2_sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      {
        Name = local.ec2_name
        App = "talo-yolo5"
      },
      var.tags
    )
  }

  tags = merge(
    {
      Name = local.launch_template_name
    },
    var.tags
  )
}

################## Autoscaling Group #####################
resource "aws_autoscaling_group" "asg" {
  name                = local.asg_name
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size
  vpc_zone_identifier = var.public_subnets
  health_check_type   = var.health_check_type

  # Launch Template
  launch_template {
    id      = aws_launch_template.launch_template.id
    version = aws_launch_template.launch_template.latest_version
  }
  # Instance Refresh
  instance_refresh {
    strategy = var.instance_refresh.strategy

    dynamic "preferences" {
      for_each = var.instance_refresh.preferences == null ? [] : [var.instance_refresh.preferences]
      content {
        min_healthy_percentage = try(preferences.value.min_healthy_percentage, null)
      }
    }

    triggers = try(var.instance_refresh.triggers, null)
  }
}

################# Autoscaling Notifications ##################

################### SNS - Topic ########################
resource "aws_sns_topic" "sns_topic" {
  name = local.sns_topic_name
}

################## SNS - Subscription ##################
resource "aws_sns_topic_subscription" "sns_topic_subscription" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = var.sns_protocol
  endpoint  = var.sns_endpoint
}

############### Autoscaling Notification ################
resource "aws_autoscaling_notification" "notifications" {
  group_names   = [aws_autoscaling_group.asg.id]
  notifications = var.notifications
  topic_arn     = aws_sns_topic.sns_topic.arn
}

############# Target Tracking Scaling Policies ###########
# TTS - Scaling Policy-1: Based on CPU Utilization
resource "aws_autoscaling_policy" "avg_cpu_policy" {
  name                      = local.autoscaling_policy_name
  # The policy type may be either "SimpleScaling", "StepScaling" or "TargetTrackingScaling". If this value isn't provided, AWS will default to "SimpleScaling."
  policy_type               = var.policy_type
  autoscaling_group_name    = aws_autoscaling_group.asg.id
  # CPU Utilization is above 50
  target_tracking_configuration {
    dynamic "predefined_metric_specification" {
      for_each = var.target_tracking_configuration.predefined_metric_specification == null ? [] : [var.target_tracking_configuration.predefined_metric_specification]
      content {
        predefined_metric_type = predefined_metric_specification.value.predefined_metric_type
      }
    }
    target_value     = var.target_tracking_configuration.target_value
    disable_scale_in = var.target_tracking_configuration.disable_scale_in
  }
}