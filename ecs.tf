# Variables
variable "nginx_image" {
  description = "The latest nginx Docker image URI"
  type        = string
  default     = "026550735179.dkr.ecr.ap-northeast-1.amazonaws.com/hello-world:latest"
}

variable "ecr_repository_uri_for_example1" {
  description = "ECR repository URI for example1"
  type        = string
  default     = "026550735179.dkr.ecr.ap-northeast-1.amazonaws.com/hello-world" # Replace with the actual ECR URI for example1
}

variable "ecr_repository_uri_for_example2" {
  description = "ECR repository URI for example2"
  type        = string
  default     = "026550735179.dkr.ecr.ap-northeast-1.amazonaws.com/hello-world" # Replace with the actual ECR URI for example2
}

# ... (previous code)

# ECS Resources
resource "aws_ecs_cluster" "example" {
  name = "example"
}

resource "aws_security_group" "nginx" {
  name        = "examplenginx-sg"
  description = "nginx security group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_ecs_task_definition" "examplegw" {
  family                   = "examplegw"
  cpu                      = "8192"
  memory                   = "16384"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = module.ecs_task_role.iam_role_arn
  execution_role_arn       = module.ecs_task_execution_role.iam_role_arn
  container_definitions = jsonencode([{
    name  = "nginx-container"
    image = var.nginx_image
    portMappings = [
      {
        containerPort = 80,
        hostPort      = 80,
      },
    ]
    # ... (other container settings) ...
  }])
}

resource "aws_ecs_service" "examplegw" {
  name                              = "examplegw"
  cluster                           = aws_ecs_cluster.example.arn
  task_definition                   = aws_ecs_task_definition.examplegw.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  platform_version                  = "1.4.0"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.nginx.id]

    subnets = module.vpc.private_subnets
  }

  service_registries {
    registry_arn = aws_service_discovery_service.examplegw.arn
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.example.arn
    container_name   = "nginx-container"
    container_port   = 80
  }
}

resource "aws_ecs_task_definition" "example1" {
  family                   = "example1"
  cpu                      = "8192"
  memory                   = "16384"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = module.ecs_task_role.iam_role_arn
  execution_role_arn       = module.ecs_task_execution_role.iam_role_arn
  container_definitions = jsonencode([{
    name  = "nginx-container"
    image = "${var.ecr_repository_uri_for_example1}:latest"
    portMappings = [
      {
        containerPort = 80,
        hostPort      = 80,
      },
    ]
    # ... (other container settings) ...
  }])
}

resource "aws_ecs_service" "example1" {
  name                              = "example1"
  cluster                           = aws_ecs_cluster.example.arn
  task_definition                   = aws_ecs_task_definition.example1.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  platform_version                  = "1.4.0"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.nginx.id]

    subnets = module.vpc.private_subnets
  }

  service_registries {
    registry_arn = aws_service_discovery_service.example1.arn
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.example.arn
    container_name   = "nginx-container"
    container_port   = 80
  }
}

resource "aws_ecs_task_definition" "example2" {
  family                   = "example2"
  cpu                      = "8192"
  memory                   = "16384"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = module.ecs_task_role.iam_role_arn
  execution_role_arn       = module.ecs_task_execution_role.iam_role_arn
  container_definitions = jsonencode([{
    name  = "nginx-container"
    image = "${var.ecr_repository_uri_for_example2}:latest"
    portMappings = [
      {
        containerPort = 80,
        hostPort      = 80,
      },
    ]
    # ... (other container settings) ...
  }])
}

resource "aws_ecs_service" "example2" {
  name                              = "example2"
  cluster                           = aws_ecs_cluster.example.arn
  task_definition                   = aws_ecs_task_definition.example2.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  platform_version                  = "1.4.0"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.nginx.id]

    subnets = module.vpc.private_subnets
  }

  service_registries {
    registry_arn = aws_service_discovery_service.example2.arn
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.example.arn
    container_name   = "nginx-container"
    container_port   = 80
  }
}

# AppMesh Resources
resource "aws_appmesh_mesh" "example" {
  name = "example"
}

resource "aws_appmesh_virtual_gateway" "example" {
  name      = "example"
  mesh_name = aws_appmesh_mesh.example.name

  spec {
    listener {
      port_mapping {
        port     = 9080
        protocol = "http"
      }
    }
  }
}

resource "aws_appmesh_gateway_route" "example" {
  name                 = "example"
  mesh_name            = aws_appmesh_mesh.example.name
  virtual_gateway_name = aws_appmesh_virtual_gateway.example.name

  spec {
    http_route {
      action {
        target {
          virtual_service {
            virtual_service_name = aws_appmesh_virtual_service.example.name
          }
        }
      }

      match {
        prefix = "/"
      }
    }
  }
}

resource "aws_appmesh_virtual_service" "example" {
  name      = "example"
  mesh_name = aws_appmesh_mesh.example.id

  spec {
    provider {
      virtual_router {
        virtual_router_name = aws_appmesh_virtual_router.example.name
      }
    }
  }
}

resource "aws_appmesh_virtual_router" "example" {
  name      = "example"
  mesh_name = aws_appmesh_mesh.example.id

  spec {
    listener {
      port_mapping {
        port     = 80
        protocol = "http"
      }
    }
  }
}

resource "aws_appmesh_route" "example" {
  name                = "example"
  mesh_name           = aws_appmesh_mesh.example.id
  virtual_router_name = aws_appmesh_virtual_router.example.name

  spec {
    http_route {
      match {
        prefix = "/"
      }

      action {
        weighted_target {
          virtual_node = aws_appmesh_virtual_node.example1.name
          weight       = 95
        }

        weighted_target {
          virtual_node = aws_appmesh_virtual_node.example2.name
          weight       = 5
        }
      }
    }
  }
}

resource "aws_appmesh_virtual_node" "example1" {
  name      = "example1"
  mesh_name = aws_appmesh_mesh.example.id

  spec {
    listener {
      port_mapping {
        port     = 80
        protocol = "http"
      }
      health_check {
        protocol            = "http"
        path                = "/"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout_millis      = 2000
        interval_millis     = 5000
      }
    }

    service_discovery {
      aws_cloud_map {
        namespace_name = aws_service_discovery_private_dns_namespace.example.name
        service_name   = "example1"
      }
    }

    logging {
      access_log {
        file {
          path = "/dev/stdout"
        }
      }
    }
  }
}

resource "aws_appmesh_virtual_node" "example2" {
  name      = "example2"
  mesh_name = aws_appmesh_mesh.example.id

  spec {
    listener {
      port_mapping {
        port     = 80
        protocol = "http"
      }
      health_check {
        protocol            = "http"
        path                = "/"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout_millis      = 2000
        interval_millis     = 5000
      }
    }

    service_discovery {
      aws_cloud_map {
        namespace_name = aws_service_discovery_private_dns_namespace.example.name
        service_name   = "example2"
      }
    }

    logging {
      access_log {
        file {
          path = "/dev/stdout"
        }
      }
    }
  }
}

resource "aws_appmesh_virtual_node" "example_backend" {
  name      = "example-backend"
  mesh_name = aws_appmesh_mesh.example.id

  spec {
    listener {
      port_mapping {
        port     = 80
        protocol = "http"
      }
      health_check {
        protocol            = "http"
        path                = "/"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout_millis      = 2000
        interval_millis     = 5000
      }
    }

    service_discovery {
      aws_cloud_map {
        namespace_name = aws_service_discovery_private_dns_namespace.example.name
        service_name   = "example-backend" # Update with the correct service name
      }
    }

    logging {
      access_log {
        file {
          path = "/dev/stdout"
        }
      }
    }
  }
}

# CloudWatch Alarms for ECS Metrics
resource "aws_sns_topic" "ecs_alerts" {
  name = "ecs-alerts"
}

# Outputs
output "ecs_cluster_example_name" {
  value = aws_ecs_cluster.example.name
}

output "ecs_service_examplegw_name" {
  value = aws_ecs_service.examplegw.name
}

output "ecs_service_example1_name" {
  value = aws_ecs_service.example1.name
}

output "ecs_service_example2_name" {
  value = aws_ecs_service.example2.name
}

# Move data "template_file" block to the end
data "template_file" "container_definition_examplegw" {
  template = file("./container_definitions/examplegw.tpl")
  vars = {
    appmesh_virtual_node_name = "mesh/${aws_appmesh_mesh.example.name}/virtualGateway/${aws_appmesh_virtual_gateway.example.name}"
  }
}

