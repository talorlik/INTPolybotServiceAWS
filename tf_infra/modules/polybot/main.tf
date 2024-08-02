locals {
  alb_name          = "${var.prefix}-${var.alb_name}-${var.env}"
  alb_listener_name = "${var.prefix}-${var.alb_listener_name}-${var.env}"
  alb_sg_name       = "${var.prefix}-${var.alb_sg_name}-${var.env}"
  tg_name           = "${var.prefix}-${var.tg_name}-${var.env}"
  polybot_sg_name   = "${var.prefix}-${var.polybot_sg_name}-${var.env}"
}
resource "aws_instance" "polybot_ec2" {
  for_each = { for az in var.azs : az => az }

  ami                         = var.ami
  instance_type               = var.instance_type
  availability_zone           = each.key
  vpc_security_group_ids      = [aws_security_group.polybot_ec2_sg.id]
  key_name                    = var.key_pair_name
  subnet_id                   = element(var.public_subnets, index(var.azs, each.key))
  iam_instance_profile        = var.iam_instance_profile_name
  user_data                   = file("${path.module}/deploy.sh")
  associate_public_ip_address = var.associate_public_ip_address
  ebs_optimized               = true

  root_block_device {
    iops        = try(var.root_block_device.iops, null)
    volume_size = try(var.root_block_device.volume_size, null)
    volume_type = try(var.root_block_device.volume_type, null)
  }

  tags = merge(
    {
      Name = "${var.prefix}-${var.instance_name}-${each.key}-${var.env}"
      App  = "talo-polybot"
    },
    var.tags
  )
}

locals {
  instance_ids = values(aws_instance.polybot_ec2)
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name    = local.alb_name
  vpc_id  = var.vpc_id
  subnets = var.public_subnets

  enable_deletion_protection = var.enable_deletion_protection

  ### ALB SG ###
  security_group_name = local.alb_sg_name
  security_group_ingress_rules = { for k, v in var.alb_security_group_ingress_rules : k => {
    description = v.description
    from_port   = v.from_port
    to_port     = v.to_port
    ip_protocol = v.ip_protocol
    cidr_ipv4   = v.cidr_ipv4
  } }
  security_group_egress_rules = { for k, v in var.alb_security_group_egress_rules : k => {
    description                  = v.description
    from_port                    = v.from_port
    to_port                      = v.to_port
    ip_protocol                  = v.ip_protocol
    referenced_security_group_id = aws_security_group.polybot_ec2_sg.id
  } }
  security_group_tags = merge(
    {
      Name = local.alb_sg_name
    },
    var.tags
  )

  client_keep_alive = var.client_keep_alive

  listeners = { for k, v in var.alb_listeners : k => {
    port            = v.port
    protocol        = v.protocol
    certificate_arn = var.certificate_arn
    forward = {
      target_group_key = v.forward.target_group_key
    }
    tags = merge(
      {
        Name = local.alb_listener_name
      },
      var.tags
    )
  } }

  target_groups = { for k, v in var.alb_target_groups : k => {
    name                              = local.tg_name
    target_id                         = local.instance_ids[0].id
    protocol                          = v.protocol
    protocol_version                  = v.protocol_version
    port                              = v.port
    target_type                       = v.target_type
    deregistration_delay              = v.deregistration_delay
    load_balancing_algorithm_type     = try(v.load_balancing_algorithm_type, null)
    load_balancing_anomaly_mitigation = try(v.load_balancing_anomaly_mitigation, null)
    load_balancing_cross_zone_enabled = v.load_balancing_cross_zone_enabled

    health_check = {
      enabled             = v.health_check.enabled
      interval            = v.health_check.interval
      path                = v.health_check.path
      port                = v.health_check.port
      healthy_threshold   = v.health_check.healthy_threshold
      unhealthy_threshold = v.health_check.unhealthy_threshold
      timeout             = v.health_check.timeout
      protocol            = v.health_check.protocol
      matcher             = v.health_check.matcher
    }

    tags = merge(
      {
        Name = local.tg_name
      },
      var.tags
    )
  } }

  additional_target_group_attachments = { for k, v in var.alb_additional_target_group_attachments : k => {
    target_group_key = v.target_group_key
    target_id        = local.instance_ids[1].id
    target_type      = v.target_type
    port             = v.port
  } }

  tags = merge(
    {
      Name = local.alb_name
    },
    var.tags
  )
}

resource "aws_security_group" "polybot_ec2_sg" {
  name   = local.polybot_sg_name
  vpc_id = var.vpc_id

  # Dynamic Ingress rules
  dynamic "ingress" {
    for_each = var.ec2_sg_ingress_rules
    content {
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = try(ingress.value.cidr_blocks, null)
      security_groups = try(length(ingress.value.security_groups) > 0 ? ingress.value.security_groups : (length(ingress.value.cidr_blocks) == 0 ? [module.alb.security_group_id] : []), null)
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
      Name = local.polybot_sg_name
    },
    var.tags
  )
}