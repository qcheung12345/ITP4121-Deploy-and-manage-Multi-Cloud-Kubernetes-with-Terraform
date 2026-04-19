resource "random_password" "postgres" {
  length  = 20
  special = false
}

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "Allow PostgreSQL from EKS nodes"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-rds-sg"
  })
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-db-subnets"
  subnet_ids = aws_subnet.private[*].id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-db-subnets"
  })
}

resource "aws_db_instance" "postgres" {
  identifier             = local.db_identifier
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  db_name                = var.db_name
  username               = var.db_username
  password               = random_password.postgres.result
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible      = false
  multi_az                 = false
  storage_encrypted        = true
  backup_retention_period  = 7
  skip_final_snapshot      = true
  deletion_protection      = false
  auto_minor_version_upgrade = true

  tags = merge(var.tags, {
    Name = local.db_identifier
  })
}
