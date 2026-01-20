# Jenkins Setup and Configuration Guide

This guide provides detailed instructions for setting up and configuring Jenkins on EC2 for the CI/CD deployment platform.

## Prerequisites

- EC2 instance running with Docker installed
- Java 17 installed
- Application repository cloned to `/home/ec2-user/app`

## Automated Installation

The quickest way to install Jenkins is using the provided setup script:

```bash
cd ~/app
chmod +x jenkins/setup-jenkins.sh
./jenkins/setup-jenkins.sh
```

The script will:
- Install Java 17
- Add Jenkins repository
- Install Jenkins
- Configure Jenkins service
- Start Jenkins
- Display initial admin password

## Manual Installation

If you prefer manual installation:

### Step 1: Install Java

```bash
sudo yum install java-17-amazon-corretto-devel -y
java -version
```

### Step 2: Add Jenkins Repository

```bash
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
```

### Step 3: Install Jenkins

```bash
sudo yum install jenkins -y
```

### Step 4: Configure Jenkins

```bash
# Add jenkins user to docker group
sudo usermod -aG docker jenkins

# Increase Jenkins memory
sudo sed -i 's/JENKINS_JAVA_OPTIONS="-Djava.awt.headless=true"/JENKINS_JAVA_OPTIONS="-Djava.awt.headless=true -Xmx2048m -Xms512m"/' /usr/lib/systemd/system/jenkins.service

# Reload systemd
sudo systemctl daemon-reload
```

### Step 5: Start Jenkins

```bash
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Check status
sudo systemctl status jenkins
```

### Step 6: Get Initial Password

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

## Initial Jenkins Configuration

### Step 1: Access Jenkins UI

1. Open browser and navigate to:
   ```
   http://your-ec2-public-ip:8080
   ```

2. Enter the initial admin password from previous step

### Step 2: Install Plugins

1. Select **"Install suggested plugins"**
2. Wait for installation to complete
3. Install additional required plugins:
   - Docker Pipeline
   - Git Plugin
   - Pipeline Plugin
   - Blue Ocean (optional, for better UI)
   - Credentials Binding Plugin

**To install additional plugins:**
- Manage Jenkins → Plugins → Available plugins
- Search for plugin name
- Check the box and click "Install"

### Step 3: Create Admin User

1. Fill in the admin user details:
   - Username: `admin`
   - Password: (choose a strong password)
   - Full name: Your name
   - Email: your-email@example.com

2. Click "Save and Continue"

### Step 4: Configure Jenkins URL

1. Verify the Jenkins URL:
   ```
   http://your-ec2-public-ip:8080
   ```

2. Click "Save and Finish"

## Configure Credentials

Jenkins needs credentials to access Docker Hub and GitHub.

### Step 1: Access Credentials Manager

Navigate to: **Manage Jenkins → Credentials → System → Global credentials (unrestricted)**

### Step 2: Add Docker Hub Credentials

1. Click **"Add Credentials"**
2. Configure:
   - **Kind**: Username with password
   - **Scope**: Global
   - **Username**: Your Docker Hub username
   - **Password**: Your Docker Hub access token
   - **ID**: `dockerhub-credentials`
   - **Description**: Docker Hub Credentials

3. Click **"Create"**

**To create Docker Hub access token:**
```bash
# Login to hub.docker.com
# Account Settings → Security → New Access Token
# Name: jenkins-ec2-deployment
# Permissions: Read, Write, Delete
# Copy the generated token
```

### Step 3: Add GitHub Credentials (Optional)

1. Click **"Add Credentials"**
2. Configure:
   - **Kind**: Username with password (or SSH Username with private key)
   - **Scope**: Global
   - **Username**: Your GitHub username
   - **Password**: GitHub Personal Access Token
   - **ID**: `github-credentials`
   - **Description**: GitHub Credentials

3. Click **"Create"**

**To create GitHub Personal Access Token:**
```bash
# Login to github.com
# Settings → Developer settings → Personal access tokens → Tokens (classic)
# Generate new token
# Scopes: repo, workflow
# Copy the generated token
```

### Step 4: Add Environment Variables

1. Click **"Add Credentials"**
2. Configure:
   - **Kind**: Secret text
   - **Scope**: Global
   - **Secret**: Your PostgreSQL password
   - **ID**: `postgres-password`
   - **Description**: PostgreSQL Password

3. Repeat for other secrets as needed

## Create Jenkins Pipeline Job

### Step 1: Create New Item

1. From Jenkins dashboard, click **"New Item"**
2. Enter name: `ec2-deployment-pipeline`
3. Select **"Pipeline"**
4. Click **"OK"**

### Step 2: Configure Pipeline

#### General Settings

- **Description**: `CI/CD deployment pipeline for EC2 platform`
- **Discard old builds**: Check
  - Days to keep builds: `30`
  - Max # of builds to keep: `10`

#### Build Triggers (Optional)

- **GitHub hook trigger for GITScm polling**: Check (if using GitHub webhooks)
- **Poll SCM**: `H/5 * * * *` (check every 5 minutes)

#### Pipeline Configuration

1. **Definition**: Pipeline script from SCM
2. **SCM**: Git
3. **Repository URL**: Your GitHub repository URL
   ```
   https://github.com/your-username/your-repo.git
   ```
4. **Credentials**: Select `github-credentials` (if private repo)
5. **Branch Specifier**: `*/main`
6. **Script Path**: `jenkins/Jenkinsfile`

### Step 3: Configure Environment Variables

Add the following environment variables to Jenkins:

**Manage Jenkins → System → Global properties → Environment variables**

| Name | Value |
|------|-------|
| `DOCKERHUB_USERNAME` | your-dockerhub-username |
| `DEPLOY_DIR` | /home/ec2-user/app |

### Step 4: Save Configuration

Click **"Save"** at the bottom of the page

## Test Jenkins Pipeline

### Manual Build

1. Go to pipeline job page
2. Click **"Build Now"**
3. Watch the build progress in **"Build History"**
4. Click on build number to view details
5. Click **"Console Output"** to see logs

### Expected Output

```
Started by user admin
Running in Durability level: MAX_SURVIVABILITY
[Pipeline] Start of Pipeline
[Pipeline] node
[Pipeline] {
[Pipeline] stage
[Pipeline] { (Preparation)
🚀 Starting deployment pipeline
Build Number: 1
Current Environment: blue
Target Environment: green
...
✅ DEPLOYMENT SUCCESSFUL
```

## Configure GitHub Webhook (Optional)

To trigger Jenkins builds automatically on GitHub push:

### Step 1: Get Jenkins URL

```bash
echo "http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080/github-webhook/"
```

### Step 2: Configure GitHub Webhook

1. Go to your GitHub repository
2. Settings → Webhooks → Add webhook
3. Configure:
   - **Payload URL**: Your Jenkins webhook URL from Step 1
   - **Content type**: application/json
   - **Which events**: Just the push event
   - **Active**: Check

4. Click **"Add webhook"**

### Step 3: Test Webhook

1. Make a commit and push to main branch
2. Check GitHub webhook delivery (should show green checkmark)
3. Check Jenkins for new build

## Jenkins Security Best Practices

### 1. Enable CSRF Protection

**Manage Jenkins → Security → CSRF Protection**
- Check "Prevent Cross Site Request Forgery exploits"

### 2. Configure Authorization

**Manage Jenkins → Security → Authorization**
- Select "Matrix-based security"
- Configure user permissions

### 3. Limit Build Executors

**Manage Jenkins → System → # of executors**
- Set to `2` (for t3.medium instance)

### 4. Enable Agent → Controller Security

**Manage Jenkins → Security → Agent → Controller Security**
- Enable "Agent → Controller Access Control"

### 5. Regular Backups

```bash
# Create Jenkins backup script
cat > ~/backup-jenkins.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/ec2-user/jenkins-backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Stop Jenkins
sudo systemctl stop jenkins

# Backup Jenkins home
sudo tar -czf $BACKUP_DIR/jenkins_home_$DATE.tar.gz /var/lib/jenkins

# Start Jenkins
sudo systemctl start jenkins

# Keep only last 7 backups
find $BACKUP_DIR -type f -mtime +7 -delete

echo "Jenkins backup completed: jenkins_home_$DATE.tar.gz"
EOF

chmod +x ~/backup-jenkins.sh

# Add to crontab (weekly backups)
crontab -e
# Add: 0 2 * * 0 /home/ec2-user/backup-jenkins.sh
```

## Monitoring Jenkins

### View Logs

```bash
# Real-time logs
sudo journalctl -u jenkins -f

# Last 100 lines
sudo journalctl -u jenkins -n 100

# Logs from specific time
sudo journalctl -u jenkins --since "1 hour ago"
```

### System Information

**Manage Jenkins → System Information**
- View Java version, environment variables, system properties

### Monitoring Plugins

Install monitoring plugins:
- **Monitoring**: System monitoring
- **Disk Usage Plugin**: Track disk usage
- **Build Monitor Plugin**: Visual build status

## Troubleshooting

### Jenkins Won't Start

```bash
# Check status
sudo systemctl status jenkins

# Check logs
sudo journalctl -u jenkins -n 50

# Common issues:
# 1. Port 8080 already in use
sudo netstat -tulpn | grep 8080

# 2. Java not found
java -version

# 3. Permissions issues
sudo chown -R jenkins:jenkins /var/lib/jenkins
```

### Build Fails with Docker Permission Denied

```bash
# Ensure jenkins user is in docker group
sudo usermod -aG docker jenkins

# Restart Jenkins
sudo systemctl restart jenkins
```

### Cannot Access Jenkins UI

1. Check security group allows port 8080
2. Check Jenkins is running: `sudo systemctl status jenkins`
3. Check firewall: `sudo firewall-cmd --list-all`
4. Try accessing from EC2 instance: `curl http://localhost:8080`

### Pipeline Fails to Clone Repository

1. Verify GitHub credentials are configured
2. Check repository URL is correct
3. For private repos, ensure credentials have repo access
4. Check Jenkins logs for specific error

## Advanced Configuration

### Jenkins Behind NGINX (Optional)

```nginx
# Add to nginx configuration
location /jenkins/ {
    proxy_pass http://localhost:8080/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

### Email Notifications

**Manage Jenkins → System → E-mail Notification**
- Configure SMTP server
- Test email configuration

### Slack Notifications

1. Install Slack Notification Plugin
2. Configure Slack workspace
3. Add Slack notifications to Jenkinsfile

## Performance Tuning

### Increase Memory

```bash
# Edit Jenkins service file
sudo nano /usr/lib/systemd/system/jenkins.service

# Update JENKINS_JAVA_OPTIONS
JENKINS_JAVA_OPTIONS="-Djava.awt.headless=true -Xmx4096m -Xms1024m"

# Reload and restart
sudo systemctl daemon-reload
sudo systemctl restart jenkins
```

### Cleanup Old Builds

**Manage Jenkins → System → Discard Old Builds**
- Set global defaults for build retention

## Next Steps

- [Deployment Procedures](./DEPLOYMENT.md)
- [Troubleshooting Guide](./TROUBLESHOOTING.md)
- [AWS Setup Guide](./AWS-SETUP.md)
