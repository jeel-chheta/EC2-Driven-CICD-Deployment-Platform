# AWS EC2 Setup Guide

This guide walks you through setting up an AWS EC2 instance for the CI/CD deployment platform.

## Prerequisites

- AWS Account with EC2 access
- AWS CLI installed (optional)
- SSH key pair for EC2 access

## Step 1: Launch EC2 Instance

### Using AWS Console

1. **Navigate to EC2 Dashboard**
   - Go to AWS Console → EC2 → Instances → Launch Instance

2. **Configure Instance**
   - **Name**: `cicd-deployment-server`
   - **AMI**: Amazon Linux 2023 (64-bit x86)
   - **Instance Type**: `t3.medium` (2 vCPU, 4 GB RAM)
     - For production: `t3.large` or higher recommended
   - **Key Pair**: Create new or select existing key pair
   - **Storage**: 30 GB gp3 SSD

3. **Network Settings**
   - **VPC**: Default or custom VPC
   - **Auto-assign Public IP**: Enable
   - **Security Group**: Create new (see below)

### Using AWS CLI

```bash
# Create security group
aws ec2 create-security-group \
  --group-name cicd-deployment-sg \
  --description "Security group for CI/CD deployment platform"

# Launch instance
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.medium \
  --key-name your-key-pair \
  --security-group-ids sg-xxxxxxxxx \
  --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":30,"VolumeType":"gp3"}}]' \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cicd-deployment-server}]'
```

## Step 2: Configure Security Group

### Required Inbound Rules

| Type | Protocol | Port Range | Source | Description |
|------|----------|------------|--------|-------------|
| SSH | TCP | 22 | Your IP/32 | SSH access (restrict to your IP) |
| HTTP | TCP | 80 | 0.0.0.0/0 | Application HTTP access |
| HTTPS | TCP | 443 | 0.0.0.0/0 | Application HTTPS access (future) |
| Custom TCP | TCP | 8080 | Your IP/32 | Jenkins UI (restrict to your IP) |
| Custom TCP | TCP | 50000 | Your IP/32 | Jenkins agent communication |

### Using AWS Console

1. Go to EC2 → Security Groups
2. Select your security group
3. Click "Edit inbound rules"
4. Add rules as per table above
5. Save rules

### Using AWS CLI

```bash
# Get your public IP
MY_IP=$(curl -s https://checkip.amazonaws.com)

# Add SSH rule
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxxx \
  --protocol tcp \
  --port 22 \
  --cidr ${MY_IP}/32

# Add HTTP rule
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxxx \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

# Add HTTPS rule
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxxx \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

# Add Jenkins UI rule
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxxx \
  --protocol tcp \
  --port 8080 \
  --cidr ${MY_IP}/32

# Add Jenkins agent rule
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxxx \
  --protocol tcp \
  --port 50000 \
  --cidr ${MY_IP}/32
```

## Step 3: Connect to EC2 Instance

### Get Instance Public IP

```bash
# Using AWS Console
# EC2 → Instances → Select instance → Copy Public IPv4 address

# Using AWS CLI
aws ec2 describe-instances \
  --instance-ids i-xxxxxxxxx \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text
```

### SSH Connection

```bash
# Set correct permissions for key file
chmod 400 your-key.pem

# Connect to instance
ssh -i your-key.pem ec2-user@your-ec2-public-ip
```

## Step 4: Install Dependencies

Once connected to EC2, run the following commands:

```bash
# Update system packages
sudo yum update -y

# Install Docker
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Git
sudo yum install git -y

# Install Java 17 (for Jenkins)
sudo yum install java-17-amazon-corretto-devel -y

# Log out and log back in for docker group to take effect
exit
ssh -i your-key.pem ec2-user@your-ec2-public-ip

# Verify installations
docker --version
docker-compose --version
git --version
java -version
```

## Step 5: Clone Repository

```bash
# Create application directory
mkdir -p ~/app
cd ~/app

# Clone your repository
git clone https://github.com/your-username/your-repo.git .

# Or upload files manually using SCP
# scp -i your-key.pem -r ./local-project-dir ec2-user@your-ec2-ip:~/app
```

## Step 6: Configure Environment Variables

```bash
# Copy environment template
cp .env.example .env

# Edit environment file
nano .env

# Update the following:
# - POSTGRES_PASSWORD (use strong password)
# - DOCKERHUB_USERNAME
# - DOCKERHUB_TOKEN
# - BACKEND_IMAGE
# - FRONTEND_IMAGE
```

## Step 7: Initial Deployment

```bash
# Make deployment scripts executable
chmod +x deployment/*.sh
chmod +x jenkins/*.sh

# Start the application
docker-compose -f docker-compose.prod.yml up -d

# Check container status
docker ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f
```

## Step 8: Verify Deployment

```bash
# Check health endpoint
curl http://localhost/api/health

# Expected response:
# {"status":"healthy","timestamp":"...","database":"connected"}

# Access application
# Open browser: http://your-ec2-public-ip
```

## Step 9: Set Up Jenkins

```bash
# Run Jenkins setup script
cd ~/app
./jenkins/setup-jenkins.sh

# Follow the on-screen instructions
# Access Jenkins at: http://your-ec2-public-ip:8080
```

## Security Hardening (Recommended)

### 1. Enable Firewall

```bash
# Install and configure firewalld
sudo yum install firewalld -y
sudo systemctl start firewalld
sudo systemctl enable firewalld

# Allow required ports
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

### 2. Set Up SSL/TLS (Optional)

```bash
# Install Certbot for Let's Encrypt
sudo yum install certbot -y

# Obtain SSL certificate (requires domain name)
sudo certbot certonly --standalone -d your-domain.com

# Update NGINX configuration to use SSL
# Edit nginx/nginx.prod.conf to add SSL configuration
```

### 3. Regular Updates

```bash
# Create update script
cat > ~/update-system.sh << 'EOF'
#!/bin/bash
sudo yum update -y
docker image prune -f
EOF

chmod +x ~/update-system.sh

# Add to crontab (weekly updates)
crontab -e
# Add: 0 2 * * 0 /home/ec2-user/update-system.sh
```

### 4. Backup Strategy

```bash
# Create backup script
cat > ~/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/ec2-user/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup database
docker exec postgres_prod pg_dump -U appuser appdb > $BACKUP_DIR/db_backup_$DATE.sql

# Backup application files
tar -czf $BACKUP_DIR/app_backup_$DATE.tar.gz ~/app

# Keep only last 7 backups
find $BACKUP_DIR -type f -mtime +7 -delete
EOF

chmod +x ~/backup.sh

# Add to crontab (daily backups)
crontab -e
# Add: 0 3 * * * /home/ec2-user/backup.sh
```

## Monitoring

### CloudWatch Integration

```bash
# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U ./amazon-cloudwatch-agent.rpm

# Configure CloudWatch agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
```

### Application Monitoring

```bash
# Run health checks
./deployment/health-check.sh

# View container logs
docker-compose -f docker-compose.prod.yml logs -f

# Monitor resource usage
docker stats
```

## Troubleshooting

### Cannot Connect to Instance

1. Check security group rules
2. Verify instance is running
3. Check key file permissions (`chmod 400`)
4. Verify correct public IP address

### Docker Permission Denied

```bash
# Add user to docker group
sudo usermod -aG docker ec2-user

# Log out and log back in
exit
ssh -i your-key.pem ec2-user@your-ec2-ip
```

### Application Not Accessible

1. Check if containers are running: `docker ps`
2. Check security group allows port 80
3. Check NGINX logs: `docker logs nginx_prod`
4. Verify health endpoint: `curl http://localhost/api/health`

## Cost Optimization

### 1. Use Reserved Instances

For long-term deployments, consider Reserved Instances for cost savings.

### 2. Auto-Scaling (Optional)

Set up Auto Scaling Groups for handling variable load.

### 3. Monitoring Costs

- Use AWS Cost Explorer
- Set up billing alerts
- Monitor data transfer costs

## Next Steps

- [Jenkins Setup Guide](./JENKINS-SETUP.md)
- [Deployment Procedures](./DEPLOYMENT.md)
- [Troubleshooting Guide](./TROUBLESHOOTING.md)
