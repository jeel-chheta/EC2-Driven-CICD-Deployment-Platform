# Troubleshooting Guide

This guide helps you diagnose and fix common issues with the EC2-Driven CI/CD deployment platform.

## Table of Contents

- [Quick Diagnostics](#quick-diagnostics)
- [CI Pipeline Issues](#ci-pipeline-issues)
- [CD Pipeline Issues](#cd-pipeline-issues)
- [Application Issues](#application-issues)
- [Database Issues](#database-issues)
- [Docker Issues](#docker-issues)
- [NGINX Issues](#nginx-issues)
- [Network Issues](#network-issues)
- [Performance Issues](#performance-issues)

## Quick Diagnostics

Run these commands first to get an overview:

```bash
# Check all containers
docker ps -a

# Check container health
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Run health check script
./deployment/health-check.sh

# Check logs
docker-compose -f docker-compose.prod.yml logs --tail=50

# Check disk space
df -h

# Check memory
free -m

# Check system load
uptime
```

## CI Pipeline Issues

### Issue: GitHub Actions Workflow Fails

**Symptoms:**
- Red X on GitHub commit
- Workflow shows failed status

**Diagnosis:**
```bash
# Check GitHub Actions logs
# Go to: GitHub → Actions → Select failed workflow → View logs
```

**Common Causes & Solutions:**

#### 1. Tests Failing

```bash
# Run tests locally
cd backend
npm test

cd ../frontend
npm test

# Fix failing tests and push
git add .
git commit -m "fix: resolve failing tests"
git push origin main
```

#### 2. Docker Build Fails

```bash
# Test Docker build locally
docker build -t test-backend ./backend
docker build -t test-frontend ./frontend

# Check Dockerfile syntax
# Fix any errors and push
```

#### 3. Docker Hub Authentication Fails

**Check:**
- Verify `DOCKERHUB_USERNAME` secret is set in GitHub
- Verify `DOCKERHUB_TOKEN` secret is set in GitHub
- Ensure Docker Hub token has write permissions

**Fix:**
```bash
# GitHub → Settings → Secrets and variables → Actions
# Update DOCKERHUB_USERNAME and DOCKERHUB_TOKEN
```

#### 4. Node Modules Installation Fails

```bash
# Delete package-lock.json and regenerate
cd backend
rm package-lock.json
npm install
git add package-lock.json
git commit -m "fix: regenerate package-lock.json"
git push origin main
```

### Issue: Security Scan Fails

**Symptoms:**
- Trivy scan reports vulnerabilities

**Solutions:**

```bash
# Update dependencies
cd backend
npm audit fix
npm update

cd ../frontend
npm audit fix
npm update

# Commit and push
git add .
git commit -m "fix: update dependencies for security"
git push origin main
```

## CD Pipeline Issues

### Issue: Jenkins Pipeline Fails

**Symptoms:**
- Jenkins build shows red status
- Deployment doesn't complete

**Diagnosis:**
```bash
# Check Jenkins console output
# Jenkins → Job → Build # → Console Output

# SSH into EC2 and check
ssh -i your-key.pem ec2-user@your-ec2-ip
cd /home/ec2-user/app
docker ps -a
```

**Common Causes & Solutions:**

#### 1. Docker Pull Fails

**Error:** `Error response from daemon: pull access denied`

**Fix:**
```bash
# Verify Docker Hub credentials in Jenkins
# Manage Jenkins → Credentials → Check dockerhub-credentials

# Test Docker login manually
docker login -u your-username

# Update Jenkins credentials if needed
```

#### 2. Health Checks Fail

**Error:** `Health checks failed after 12 attempts`

**Diagnosis:**
```bash
# Check container logs
docker logs backend_green
docker logs frontend_green

# Check container status
docker ps -a | grep green

# Manual health check
docker exec backend_green node -e "require('http').get('http://localhost:5000/api/health', (r) => {console.log(r.statusCode)})"
```

**Common Fixes:**

**Database Connection Issue:**
```bash
# Check database is running
docker ps | grep postgres

# Check database logs
docker logs postgres_prod

# Restart database
docker-compose -f docker-compose.prod.yml restart postgres

# Wait for database to be ready
sleep 10

# Retry deployment
```

**Container Not Starting:**
```bash
# Check container logs for errors
docker logs backend_green --tail=100

# Common issues:
# - Missing environment variables
# - Port already in use
# - Insufficient memory

# Fix and redeploy
```

#### 3. NGINX Reload Fails

**Error:** `nginx: configuration file /etc/nginx/nginx.conf test failed`

**Diagnosis:**
```bash
# Test NGINX configuration
docker exec nginx_prod nginx -t

# Check NGINX logs
docker logs nginx_prod
```

**Fix:**
```bash
# Restore backup configuration
cd /home/ec2-user/app
cp nginx/nginx.prod.conf.backup nginx/nginx.prod.conf

# Reload NGINX
docker exec nginx_prod nginx -s reload

# Verify
docker exec nginx_prod nginx -t
```

#### 4. Insufficient Disk Space

**Error:** `no space left on device`

**Diagnosis:**
```bash
# Check disk usage
df -h

# Check Docker disk usage
docker system df
```

**Fix:**
```bash
# Clean up Docker
docker system prune -f

# Remove old images
docker images | grep '<none>' | awk '{print $3}' | xargs docker rmi -f

# Remove old containers
docker container prune -f

# Remove unused volumes
docker volume prune -f

# If still low, increase EBS volume size in AWS
```

## Application Issues

### Issue: Application Not Accessible

**Symptoms:**
- Cannot access http://your-ec2-ip
- Browser shows "Connection refused" or timeout

**Diagnosis:**
```bash
# 1. Check if containers are running
docker ps

# 2. Check from EC2 instance
curl http://localhost/api/health

# 3. Check security group
# AWS Console → EC2 → Security Groups → Check port 80 is open

# 4. Check NGINX
docker logs nginx_prod
```

**Solutions:**

#### From EC2 Works, External Doesn't

```bash
# Issue: Security group not configured
# Fix: Add inbound rule for port 80
# AWS Console → EC2 → Security Groups → Edit inbound rules
# Add: HTTP, TCP, 80, 0.0.0.0/0
```

#### From EC2 Doesn't Work

```bash
# Check NGINX is running
docker ps | grep nginx

# If not running, start it
docker-compose -f docker-compose.prod.yml up -d nginx

# Check NGINX configuration
docker exec nginx_prod nginx -t

# Check NGINX logs
docker logs nginx_prod --tail=50
```

### Issue: 502 Bad Gateway

**Symptoms:**
- NGINX returns 502 error
- Application was working, now shows error

**Diagnosis:**
```bash
# Check upstream services
docker ps | grep -E "backend|frontend"

# Check NGINX logs
docker logs nginx_prod --tail=50

# Check backend logs
docker logs backend_blue --tail=50
docker logs backend_green --tail=50
```

**Solutions:**

```bash
# 1. Restart backend services
docker-compose -f docker-compose.prod.yml restart backend_blue

# 2. Check backend health
curl http://localhost:5000/api/health

# 3. If backend is down, check logs
docker logs backend_blue --tail=100

# 4. Restart all services if needed
docker-compose -f docker-compose.prod.yml restart
```

### Issue: Slow Response Times

**Symptoms:**
- Application loads slowly
- API requests timeout

**Diagnosis:**
```bash
# Check resource usage
docker stats

# Check system resources
top
free -m
df -h

# Check database connections
docker exec postgres_prod psql -U appuser -d appdb -c "SELECT count(*) FROM pg_stat_activity;"
```

**Solutions:**

```bash
# 1. Restart services to clear memory
docker-compose -f docker-compose.prod.yml restart

# 2. Check for memory leaks in logs
docker logs backend_blue | grep -i "memory\|heap"

# 3. Scale up EC2 instance if needed
# AWS Console → EC2 → Instance → Actions → Instance Settings → Change Instance Type

# 4. Optimize database queries
# Review slow query logs
```

## Database Issues

### Issue: Database Connection Refused

**Symptoms:**
- Backend logs show "ECONNREFUSED"
- Health check fails with database error

**Diagnosis:**
```bash
# Check if database is running
docker ps | grep postgres

# Check database logs
docker logs postgres_prod --tail=50

# Try to connect
docker exec -it postgres_prod psql -U appuser -d appdb
```

**Solutions:**

```bash
# 1. Restart database
docker-compose -f docker-compose.prod.yml restart postgres

# 2. Check environment variables
docker exec postgres_prod env | grep POSTGRES

# 3. Verify database exists
docker exec postgres_prod psql -U appuser -l

# 4. If database doesn't exist, recreate
docker-compose -f docker-compose.prod.yml down postgres
docker volume rm ec2-driven-cicd-deployment-platform_postgres_data
docker-compose -f docker-compose.prod.yml up -d postgres
```

### Issue: Database Data Lost

**Symptoms:**
- Users table is empty
- Data disappeared after restart

**Diagnosis:**
```bash
# Check if volume exists
docker volume ls | grep postgres

# Check volume mount
docker inspect postgres_prod | grep -A 10 Mounts
```

**Solutions:**

```bash
# 1. Check if init script ran
docker logs postgres_prod | grep "init.sql"

# 2. Manually run init script
docker exec -i postgres_prod psql -U appuser -d appdb < database/init.sql

# 3. Verify data
docker exec postgres_prod psql -U appuser -d appdb -c "SELECT * FROM users;"

# 4. Restore from backup (if available)
docker exec -i postgres_prod psql -U appuser -d appdb < backup.sql
```

## Docker Issues

### Issue: Container Keeps Restarting

**Symptoms:**
- Container status shows "Restarting"
- Container exits immediately after start

**Diagnosis:**
```bash
# Check container status
docker ps -a | grep <container-name>

# Check logs
docker logs <container-name> --tail=100

# Check exit code
docker inspect <container-name> | grep -A 5 State
```

**Solutions:**

```bash
# 1. Check for application errors in logs
docker logs <container-name>

# 2. Run container interactively to debug
docker run -it --entrypoint /bin/sh <image-name>

# 3. Check resource limits
docker stats <container-name>

# 4. Remove and recreate container
docker-compose -f docker-compose.prod.yml stop <service-name>
docker-compose -f docker-compose.prod.yml rm -f <service-name>
docker-compose -f docker-compose.prod.yml up -d <service-name>
```

### Issue: Cannot Remove Container

**Symptoms:**
- `docker rm` fails
- Container stuck in removing state

**Solutions:**
```bash
# 1. Force remove
docker rm -f <container-name>

# 2. Stop Docker service and restart
sudo systemctl stop docker
sudo systemctl start docker

# 3. Restart EC2 instance (last resort)
sudo reboot
```

### Issue: Image Pull Rate Limit

**Symptoms:**
- Error: "toomanyrequests: You have reached your pull rate limit"

**Solutions:**
```bash
# 1. Login to Docker Hub
docker login

# 2. Use authenticated pulls in Jenkins
# Ensure dockerhub-credentials are configured

# 3. Use Docker Hub Pro account (higher limits)

# 4. Cache images locally
# Don't pull if image already exists
```

## NGINX Issues

### Issue: NGINX Configuration Test Fails

**Symptoms:**
- `nginx -t` shows errors
- NGINX won't reload

**Diagnosis:**
```bash
# Test configuration
docker exec nginx_prod nginx -t

# Check configuration file
docker exec nginx_prod cat /etc/nginx/conf.d/default.conf
```

**Solutions:**
```bash
# 1. Restore backup
cp nginx/nginx.prod.conf.backup nginx/nginx.prod.conf

# 2. Restart NGINX container
docker-compose -f docker-compose.prod.yml restart nginx

# 3. Verify syntax locally
# Use online NGINX config tester or local NGINX installation
```

### Issue: NGINX Not Routing to Correct Backend

**Symptoms:**
- Old version still serving requests
- Deployment version header incorrect

**Diagnosis:**
```bash
# Check deployment version
curl -I http://localhost/ | grep X-Deployment-Version

# Check NGINX upstream configuration
docker exec nginx_prod cat /etc/nginx/conf.d/default.conf | grep upstream
```

**Solutions:**
```bash
# 1. Manually update NGINX config
nano nginx/nginx.prod.conf

# Update upstream servers to point to correct environment

# 2. Reload NGINX
docker exec nginx_prod nginx -s reload

# 3. Verify
curl -I http://localhost/ | grep X-Deployment-Version
```

## Network Issues

### Issue: Containers Cannot Communicate

**Symptoms:**
- Backend cannot connect to database
- Frontend cannot reach backend

**Diagnosis:**
```bash
# Check network
docker network ls
docker network inspect ec2-driven-cicd-deployment-platform_app-network

# Test connectivity
docker exec backend_blue ping postgres
docker exec frontend_blue ping backend_blue
```

**Solutions:**
```bash
# 1. Recreate network
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d

# 2. Check DNS resolution
docker exec backend_blue nslookup postgres

# 3. Verify all containers on same network
docker inspect backend_blue | grep NetworkMode
docker inspect postgres_prod | grep NetworkMode
```

### Issue: Port Already in Use

**Symptoms:**
- Error: "port is already allocated"
- Container won't start

**Diagnosis:**
```bash
# Check what's using the port
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :5000
```

**Solutions:**
```bash
# 1. Stop conflicting service
sudo systemctl stop <service-name>

# 2. Change port in docker-compose.yml (if needed)

# 3. Kill process using port
sudo kill -9 <PID>

# 4. Restart Docker
sudo systemctl restart docker
```

## Performance Issues

### Issue: High CPU Usage

**Diagnosis:**
```bash
# Check container CPU usage
docker stats

# Check system CPU
top

# Check specific container
docker top <container-name>
```

**Solutions:**
```bash
# 1. Restart high-CPU containers
docker-compose -f docker-compose.prod.yml restart <service>

# 2. Check for infinite loops in logs
docker logs <container-name> | tail -100

# 3. Scale up EC2 instance
# AWS Console → EC2 → Change Instance Type

# 4. Optimize application code
# Review and optimize CPU-intensive operations
```

### Issue: High Memory Usage

**Diagnosis:**
```bash
# Check memory usage
free -m
docker stats

# Check for memory leaks
docker logs backend_blue | grep -i "heap\|memory"
```

**Solutions:**
```bash
# 1. Restart containers
docker-compose -f docker-compose.prod.yml restart

# 2. Increase container memory limits
# Edit docker-compose.prod.yml
# Add: mem_limit: 1g

# 3. Scale up EC2 instance

# 4. Fix memory leaks in application
```

## Emergency Recovery

### Complete System Failure

```bash
# 1. SSH into EC2
ssh -i your-key.pem ec2-user@your-ec2-ip

# 2. Stop all containers
docker stop $(docker ps -aq)

# 3. Restart Docker
sudo systemctl restart docker

# 4. Start from scratch
cd /home/ec2-user/app
docker-compose -f docker-compose.prod.yml up -d

# 5. If still failing, restore from backup
# Restore database
docker exec -i postgres_prod psql -U appuser -d appdb < backup.sql

# 6. Verify
./deployment/health-check.sh
```

### Data Corruption

```bash
# 1. Stop application
docker-compose -f docker-compose.prod.yml down

# 2. Restore database from backup
docker volume rm ec2-driven-cicd-deployment-platform_postgres_data
docker-compose -f docker-compose.prod.yml up -d postgres
sleep 10
docker exec -i postgres_prod psql -U appuser -d appdb < backup.sql

# 3. Restart application
docker-compose -f docker-compose.prod.yml up -d

# 4. Verify
./deployment/health-check.sh
```

## Getting Help

### Collect Diagnostic Information

```bash
# Create diagnostic report
cat > diagnostic-report.sh << 'EOF'
#!/bin/bash
echo "=== System Information ==="
uname -a
uptime
free -m
df -h

echo -e "\n=== Docker Information ==="
docker --version
docker-compose --version
docker ps -a
docker images

echo -e "\n=== Container Logs ==="
docker-compose -f docker-compose.prod.yml logs --tail=50

echo -e "\n=== Network Information ==="
docker network ls
docker network inspect ec2-driven-cicd-deployment-platform_app-network

echo -e "\n=== Health Check ==="
curl -s http://localhost/api/health | jq
EOF

chmod +x diagnostic-report.sh
./diagnostic-report.sh > diagnostic-report.txt
```

### Contact Support

When reporting issues, include:
- Diagnostic report
- Steps to reproduce
- Expected vs actual behavior
- Recent changes made
- Error messages and logs

## Preventive Measures

### Regular Maintenance

```bash
# Weekly tasks
# 1. Update system packages
sudo yum update -y

# 2. Clean Docker
docker system prune -f

# 3. Backup database
./backup.sh

# 4. Check disk space
df -h

# 5. Review logs for errors
docker-compose -f docker-compose.prod.yml logs --tail=100 | grep -i error
```

### Monitoring Setup

```bash
# Set up monitoring alerts
# 1. Disk space alerts
# 2. Memory usage alerts
# 3. Container health alerts
# 4. Application error alerts

# Use CloudWatch or third-party monitoring tools
```

## Additional Resources

- [AWS EC2 Setup Guide](./AWS-SETUP.md)
- [Jenkins Setup Guide](./JENKINS-SETUP.md)
- [Deployment Procedures](./DEPLOYMENT.md)
- [Docker Documentation](https://docs.docker.com/)
- [NGINX Documentation](https://nginx.org/en/docs/)
