# Define the provider as AWS and set the region to ap-south-1 (Mumbai)
provider "aws" {
  region = "ap-south-1"  # Mumbai Region
}

# Create a VPC named 'practice-vpc'
resource "aws_vpc" "practice_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "practice-vpc"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.practice_vpc.id
  tags = {
    Name = "practice-vpc-igw"
  }
}

# Create two public subnets in different availability zones with non-overlapping CIDR blocks
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.practice_vpc.id
  cidr_block              = "10.0.1.0/24"  # First public subnet
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"
  tags = {
    Name = "public-subnet-a"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.practice_vpc.id
  cidr_block              = "10.0.2.0/24"  # Second public subnet
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1b"
  tags = {
    Name = "public-subnet-b"
  }
}

# Create a route table for the public subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.practice_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate the route table with the public subnets
resource "aws_route_table_association" "public_route_table_association_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_route_table_association_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create a Security Group to allow SSH and HTTP/HTTPS access
resource "aws_security_group" "allow_ssh_http" {
  vpc_id = aws_vpc.practice_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["223.177.182.37/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-ssh-http"
  }
}

# Define an EC2 instance
resource "aws_instance" "ubuntu_instance" {
  ami = "ami-0dee22c13ea7a9a67"  # Ubuntu 22.04 LTS AMI in ap-south-1 (Mumbai)
  instance_type = "t2.micro"

  subnet_id = aws_subnet.public_subnet_a.id  # Use one of the public subnets

  security_groups = [aws_security_group.allow_ssh_http.id]
  
  # Reference the existing key pair on AWS
  key_name = "server-001-key"  # Existing key pair on AWS

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
  }

  tags = {
    Name = "practice-ec2"
  }

  associate_public_ip_address = true
}

# Create an IAM role for EKS
resource "aws_iam_role" "eks_role" {
  name = "eks_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach EKS policies to the role
resource "aws_iam_role_policy_attachment" "eks_role_policy_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_role.name
}

resource "aws_iam_role_policy_attachment" "eks_role_policy_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_role.name
}

# Create EKS cluster
resource "aws_eks_cluster" "learnbay_cluster" {
  name     = "learnbay-cluster"
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.public_subnet_a.id,
      aws_subnet.public_subnet_b.id,
    ]
  }

  depends_on = [aws_internet_gateway.igw]
}

# Create Node Group for EKS
resource "aws_eks_node_group" "learnbay_node_group" {
  cluster_name    = aws_eks_cluster.learnbay_cluster.name
  node_group_name = "learnbay-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.public_subnet_a.id,aws_subnet.public_subnet_b.id]
  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  depends_on = [aws_eks_cluster.learnbay_cluster]
}

# Create IAM Role for EKS Node Group
resource "aws_iam_role" "eks_node_role" {
  name = "learnbay-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policies to the EKS Node Group role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_registries_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}


# Create ECR repository for the Python application
resource "aws_ecr_repository" "learnbay_python_app" {
  name = "learnbay-python-application"
  
  tags = {
    Name = "learnbay-python-application"
  }
}

# Output the public IP of the instance
output "instance_public_ip" {
  value = aws_instance.ubuntu_instance.public_ip
}

output "ecr_repository_uri" {
  value = aws_ecr_repository.learnbay_python_app.repository_url
}