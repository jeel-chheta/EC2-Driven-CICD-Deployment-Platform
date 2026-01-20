#!/bin/bash

###############################################################################
# Jenkins Setup Script for AWS EC2 (Amazon Linux 2023)
# This script automates the installation and configuration of Jenkins
###############################################################################

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Jenkins Installation Script for EC2"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "⚠️  Please do not run this script as root. Run as ec2-user."
    exit 1
fi

echo ""
echo "📦 Step 1: Installing Java 17"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo yum install -y java-17-amazon-corretto-devel
java -version

echo ""
echo "📦 Step 2: Adding Jenkins Repository"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

echo ""
echo "📦 Step 3: Installing Jenkins"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo yum install -y jenkins

echo ""
echo "🔧 Step 4: Configuring Jenkins"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Add jenkins user to docker group
sudo usermod -aG docker jenkins

# Set Jenkins to use more memory
sudo sed -i 's/JENKINS_JAVA_OPTIONS="-Djava.awt.headless=true"/JENKINS_JAVA_OPTIONS="-Djava.awt.headless=true -Xmx2048m -Xms512m"/' /usr/lib/systemd/system/jenkins.service

# Reload systemd
sudo systemctl daemon-reload

echo ""
echo "🚀 Step 5: Starting Jenkins"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo systemctl start jenkins
sudo systemctl enable jenkins

echo ""
echo "⏳ Waiting for Jenkins to start (this may take a minute)..."
sleep 30

# Check if Jenkins is running
if sudo systemctl is-active --quiet jenkins; then
    echo "✅ Jenkins is running"
else
    echo "❌ Jenkins failed to start. Check logs with: sudo journalctl -u jenkins"
    exit 1
fi

echo ""
echo "🔑 Step 6: Retrieving Initial Admin Password"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
INITIAL_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Jenkins Installation Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Open Jenkins in your browser:"
echo "   http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo ""
echo "2. Use this initial admin password:"
echo "   ${INITIAL_PASSWORD}"
echo ""
echo "3. Install suggested plugins"
echo ""
echo "4. Create your admin user"
echo ""
echo "5. Install additional required plugins:"
echo "   - Docker Pipeline"
echo "   - Git Plugin"
echo "   - Pipeline Plugin"
echo ""
echo "6. Configure credentials:"
echo "   - Docker Hub credentials (ID: dockerhub-credentials)"
echo "   - GitHub credentials (ID: github-credentials)"
echo ""
echo "7. Create a new Pipeline job:"
echo "   - Name: ec2-deployment-pipeline"
echo "   - Type: Pipeline"
echo "   - Pipeline script from SCM"
echo "   - SCM: Git"
echo "   - Repository URL: <your-github-repo>"
echo "   - Script Path: jenkins/Jenkinsfile"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📚 Useful Commands:"
echo ""
echo "  Check Jenkins status:  sudo systemctl status jenkins"
echo "  Stop Jenkins:          sudo systemctl stop jenkins"
echo "  Start Jenkins:         sudo systemctl start jenkins"
echo "  Restart Jenkins:       sudo systemctl restart jenkins"
echo "  View logs:             sudo journalctl -u jenkins -f"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
