resource "aws_security_group" "security_group_public" {
  name   = "security-group-terraform-public"
  vpc_id = var.vpc_id

  tags = {
    Name = "security-group-${var.tag_name}"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_SHH_ipv4_public" {
  security_group_id = aws_security_group.security_group_public.id
  cidr_ipv4         = "0.0.0.0/0"
  description       = "egress"
  ip_protocol       = "-1"
  from_port         = 0
  to_port           = 0
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.security_group_public.id
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow HTTP traffic"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_iam_role" "cluster_rule" {
  name               = "${var.cluster_name}-${var.tag_name}"
  assume_role_policy = <<POLICY
    {
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "eks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
    }    
 POLICY
}
resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSVPCResourceController" {
  role       = aws_iam_role.cluster_rule.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}
resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy" {
  role       = aws_iam_role.cluster_rule.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_cloudwatch_log_group" "cluster-log" {
  name              = "/aws/eks/${var.cluster_name}-log-${var.tag_name}/cluster"
  retention_in_days = var.retention_days
}

resource "aws_eks_cluster" "cluster" {
  name                      = "${var.cluster_name}-${var.tag_name}"
  role_arn                  = aws_iam_role.cluster_rule.arn
  enabled_cluster_log_types = ["api", "audit"]

  vpc_config {
    # ou aws_subnet.nomeDaSuaSubnet[*].id 
    subnet_ids         = var.subnet_public_ids
    security_group_ids = [aws_security_group.security_group_public.id]
  }

  depends_on = [
    aws_cloudwatch_log_group.cluster-log,
    aws_iam_role_policy_attachment.cluster-AmazonEKSVPCResourceController,
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
  ]
}

resource "aws_iam_role" "node" {
  name               = "${var.cluster_name}-role-node-${var.tag_name}"
  assume_role_policy = <<POLICY
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
  POLICY
}
resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}
resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}
resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_eks_node_group" "node-1" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "node-1"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_public_ids
  instance_types  = ["t3.micro"]

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
  ]
}

