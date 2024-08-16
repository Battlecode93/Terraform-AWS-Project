 **Terraform Infrastructure on AWS**

## **Project Overview**
This project demonstrates how to use Terraform to provision and manage a fully functional AWS infrastructure. The infrastructure includes a Virtual Private Cloud (VPC), public subnets, security groups, an Application Load Balancer (ALB), EC2 instances, an S3 bucket, and additional components necessary for running a highly available and secure web application. This README provides a step-by-step guide to the project's architecture, setup, deployment process, and suggestions for advanced configurations.

## **Architecture**
The architecture created by this Terraform project includes:
- **VPC:** A Virtual Private Cloud that forms the network foundation.
- **Public Subnets:** Two public subnets in different availability zones.
- **Internet Gateway:** Allows internet access to resources within the public subnets.
- **Route Table and Associations:** Manages routing between the subnets and the internet.
- **Security Groups:** Separate security groups for the ALB and web servers to control inbound and outbound traffic.
- **Application Load Balancer (ALB):** Distributes traffic between EC2 instances across different availability zones.
- **EC2 Instances:** Two web servers running in different availability zones with a preconfigured user data script.
- **S3 Bucket:** For storing static content or logs.
- **Target Groups:** For routing traffic from the ALB to the EC2 instances.

## **Source Code Overview**

### **Provider Configuration (`provider.tf`)**
Defines the AWS provider, specifying the region and AWS profile to be used.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.62.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "Corey"
}
```

### **Infrastructure Resources (`main.tf`)**
This file contains the main resources for the infrastructure:

#### **Application Load Balancer (ALB)**
```hcl
resource "aws_lb" "MyALB" {
  name               = "MyALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-security-group.id]
  subnets            = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]

  tags = {
    Name = "web"
  }
}
```

#### **EC2 Instances**
- **First Instance**
```hcl
resource "aws_instance" "WebServer1" {
  ami                    = "ami-04a81a99f5ec58529"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.websg.id]
  subnet_id              = aws_subnet.subnet-1.id
  user_data              = file("userdata.sh")

  tags = {
    Name = "WebServer1"
  }
}
```

- **Second Instance**
```hcl
resource "aws_instance" "WebServer2" {
  ami                    = "ami-04a81a99f5ec58529"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.websg.id]
  subnet_id              = aws_subnet.subnet-2.id
  user_data              = file("userdata1.sh")

  tags = {
    Name = "WebServer2"
  }
}
```

### **Variables Configuration (`variables.tf`)**
Variables are used to define configurable parameters, improving maintainability and reusability.

```hcl
variable "cidr" {
  default = "10.0.0.0/16"
}

variable "subnet-1-cidr" {
  default = "10.0.0.0/24"
}

variable "subnet-2-cidr" {
  default = "10.0.1.0/24"
}
```

## **Setup and Deployment**

### **1. Initialize Terraform**
Initialize the Terraform working directory, download the necessary provider plugins, and configure the backend if applicable.

```bash
terraform init
```

### **2. Plan the Infrastructure**
Generate and review an execution plan that shows the resources Terraform will create or modify.

```bash
terraform plan
```

### **3. Apply the Changes**
Provision the infrastructure based on the execution plan.

```bash
terraform apply
```

### **4. Test the Setup**
After Terraform provisions the resources, you can test the setup by accessing the DNS name provided by the ALB. Ensure that traffic is distributed across both EC2 instances.

### **5. Destroy the Infrastructure**
When you no longer need the infrastructure, use the following command to clean up all resources.

```bash
terraform destroy
```

## **Advanced Configuration Options**

### **1. **Private Subnets and NAT Gateway:****
For a more secure setup, place your EC2 instances in private subnets. Use a NAT Gateway in the public subnet to allow instances to access the internet for updates without being exposed directly.

### **2. **Global Scaling with CloudFront:****
Add Amazon CloudFront as a content delivery network (CDN) in front of your ALB to enhance performance and reach a global audience. CloudFront also provides native HTTPS support, improving security.

### **3. **Domain Name Management with Route 53:****
Use Amazon Route 53 to manage DNS records for your domain. This allows you to route traffic to your infrastructure using a custom domain name.

### **4. **Data Backup with RDS:****
Integrate an Amazon RDS MySQL database for persistent data storage. This adds a reliable and managed database service to your architecture, suitable for applications requiring data persistence.

## **Conclusion**
This Terraform project demonstrates how to create and manage a robust AWS infrastructure. By following the steps outlined above, you can deploy a highly available, secure, and scalable web application. The use of advanced configurations such as private subnets, NAT Gateways, CloudFront, Route 53, and RDS further enhances the architecture, making it suitable for production environments.

