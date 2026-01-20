# Deployment Procedures

This document outlines the complete deployment procedures for the EC2-Driven CI/CD platform.

## Table of Contents

- [Deployment Overview](#deployment-overview)
- [CI Pipeline (GitHub Actions)](#ci-pipeline-github-actions)
- [CD Pipeline (Jenkins)](#cd-pipeline-jenkins)
- [Manual Deployment](#manual-deployment)
- [Rollback Procedures](#rollback-procedures)
- [Blue-Green Deployment](#blue-green-deployment)
- [Zero-Downtime Deployment](#zero-downtime-deployment)

## Deployment Overview

### Deployment Flow

```
Developer → Git Push → GitHub Actions (CI) → Docker Images → Jenkins (CD) → EC2 Production
```

### Responsibility Split

**GitHub Actions (CI)**
- Code validation
- Dependency installation
- Test execution
- Docker image building
- Image tagging and pushing
- Security scanning

**Jenkins (CD)**
- Image pulling
- Blue-green deployment
- Health checks
- Traffic switching
- Rollback on failure
- Cleanup

## CI Pipeline (GitHub Actions)

### Trigger CI Pipeline

The CI pipeline automatically triggers on:
- Push to `main` branch
- Pull request to `main` branch

### Manual Trigger

```bash
# Push to main branch
git add .
git commit -m "feat: new feature"
git push origin main
```

### Monitor CI Pipeline

1. Go to GitHub repository
2. Click **"Actions"** tab
3. Select the latest workflow run
4. View job details and logs

### CI Pipeline Stages

1. **Backend CI**
   - Checkout code
   - Install dependencies
   - Run tests
   - Build Docker image
   - Push to Docker Hub

2. **Frontend CI**
   - Checkout code
   - Install dependencies
   - Run tests
   - Build application
   - Build Docker image
   - Push to Docker Hub

3. **Security Scan**
   - Scan Docker images for vulnerabilities
   - Generate security reports

### Expected CI Output

```
✅ Backend CI - Passed
✅ Frontend CI - Passed
✅ Security Scan - Passed

Images pushed:
- your-username/ec2-cicd-backend:abc1234
- your-username/ec2-cicd-backend:latest
- your-username/ec2-cicd-frontend:abc1234
- your-username/ec2-cicd-frontend:latest
```

## CD Pipeline (Jenkins)

### Trigger CD Pipeline

#### Automatic (Recommended)

Set up GitHub webhook to trigger Jenkins on successful CI:
- See [Jenkins Setup Guide](./JENKINS-SETUP.md#configure-github-webhook-optional)

#### Manual

1. Go to Jenkins dashboard
2. Select `ec2-deployment-pipeline`
3. Click **"Build Now"**

### Monitor CD Pipeline

1. Go to Jenkins job page
2. Click on build number in "Build History"
3. Click **"Console Output"**
4. Watch deployment progress in real-time

### CD Pipeline Stages

1. **Preparation**
   - Determine current environment (blue/green)
   - Set target environment

2. **Pull Docker Images**
   - Authenticate with Docker Hub
   - Pull latest images

3. **Deploy Green Environment**
   - Start new containers
   - Wait for initialization

4. **Health Check - Green**
   - Verify backend health
   - Verify frontend health
   - Retry up to 12 times

5. **Smoke Tests**
   - Test API endpoints
   - Verify functionality

6. **Switch Traffic to Green**
   - Update NGINX configuration
   - Reload NGINX
   - Route traffic to new environment

7. **Verify Traffic Switch**
   - Confirm traffic routing
   - Check deployment version header

8. **Stop Blue Environment**
   - Gracefully stop old containers
   - Keep for quick rollback

9. **Cleanup**
   - Remove dangling images
   - Clean old image versions

### Expected CD Output

```
🚀 Starting deployment pipeline
Current Environment: blue
Target Environment: green

📦 Pulling latest Docker images
✅ Images pulled

🚀 Deploying to green environment
✅ Containers started

🏥 Running health checks on green environment
✅ Health checks passed

🧪 Running smoke tests on green environment
✅ Smoke tests passed

🔄 Switching traffic from blue to green
✅ Traffic switched to green

✅ Verifying traffic is routing to green
✅ Traffic successfully routed to green

🔵 Stopping blue environment
✅ blue environment stopped

🧹 Cleaning up old Docker images
✅ Cleanup complete

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✅ DEPLOYMENT SUCCESSFUL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Manual Deployment

For emergency deployments or testing:

### Step 1: SSH into EC2

```bash
ssh -i your-key.pem ec2-user@your-ec2-public-ip
```

### Step 2: Navigate to Application Directory

```bash
cd /home/ec2-user/app
```

### Step 3: Pull Latest Code (Optional)

```bash
git pull origin main
```

### Step 4: Set Environment Variables

```bash
export BACKEND_IMAGE=your-username/ec2-cicd-backend:latest
export FRONTEND_IMAGE=your-username/ec2-cicd-frontend:latest
```

### Step 5: Run Deployment Script

```bash
./deployment/deploy.sh
```

### Step 6: Verify Deployment

```bash
./deployment/health-check.sh
```

## Rollback Procedures

### Automatic Rollback

Jenkins automatically rolls back if:
- Health checks fail
- Smoke tests fail
- Traffic switch fails
- Any deployment stage fails

### Manual Rollback

If you need to manually rollback:

```bash
# SSH into EC2
ssh -i your-key.pem ec2-user@your-ec2-public-ip

# Navigate to app directory
cd /home/ec2-user/app

# Run rollback script
./deployment/rollback.sh
```

### Rollback Process

1. Confirms current environment
2. Starts previous environment
3. Runs health checks
4. Restores NGINX configuration
5. Switches traffic back
6. Stops failed environment

### Expected Rollback Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Rollback Script
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current Active Environment: green
Rolling back to: blue

Are you sure you want to rollback? (yes/no): yes

🔄 Starting rollback process...

🚀 Starting blue environment...
⏳ Waiting for containers to start...

🏥 Checking health of blue environment...
✅ Health checks passed

🔄 Restoring NGINX configuration...
✅ NGINX configuration restored

🔍 Verifying traffic routing...
✅ Traffic successfully routed to blue

🛑 Stopping green environment...
✅ Failed environment stopped

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✅ ROLLBACK SUCCESSFUL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Active Environment: blue
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Blue-Green Deployment

### What is Blue-Green Deployment?

Blue-green deployment is a technique that reduces downtime and risk by running two identical production environments:
- **Blue**: Current production environment
- **Green**: New version being deployed

### How It Works

1. **Blue is live** - Serving all production traffic
2. **Deploy to Green** - New version deployed to green environment
3. **Test Green** - Health checks and smoke tests on green
4. **Switch traffic** - NGINX routes traffic from blue to green
5. **Green is live** - Green now serves all traffic
6. **Keep Blue** - Blue kept running for quick rollback
7. **Next deployment** - Blue becomes the new target

### Benefits

- **Zero downtime** - Traffic switches instantly
- **Quick rollback** - Switch back to blue if issues occur
- **Testing in production** - Test green before switching traffic
- **Reduced risk** - Old version always available

### Verify Current Environment

```bash
# Check deployment status
curl http://your-ec2-ip/deployment-status

# Check deployment version header
curl -I http://your-ec2-ip/ | grep X-Deployment-Version
```

## Zero-Downtime Deployment

### Achieving Zero Downtime

Our deployment achieves zero downtime through:

1. **Blue-Green Strategy**
   - New version deployed alongside old version
   - No interruption to running services

2. **Health Checks**
   - New version fully tested before receiving traffic
   - Failed deployments never reach users

3. **Instant Traffic Switch**
   - NGINX reload is instant
   - No connection drops

4. **Graceful Shutdown**
   - Old containers stopped after traffic switch
   - Existing connections allowed to complete

### Deployment Timeline

```
Time    Action                          Downtime
------  ------------------------------  ---------
T+0     Start green deployment          0s
T+10    Green containers running        0s
T+40    Health checks complete          0s
T+50    Smoke tests complete            0s
T+55    NGINX reload (traffic switch)   0s
T+60    Blue containers stop            0s

Total downtime: 0 seconds
```

### Monitoring During Deployment

```bash
# Terminal 1: Watch container status
watch -n 1 'docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'

# Terminal 2: Monitor health endpoint
watch -n 1 'curl -s http://localhost/api/health | jq'

# Terminal 3: Check deployment version
watch -n 1 'curl -sI http://localhost/ | grep X-Deployment-Version'

# Terminal 4: Monitor NGINX logs
docker logs -f nginx_prod
```

## Deployment Checklist

### Pre-Deployment

- [ ] All tests passing in CI
- [ ] Docker images built and pushed
- [ ] Environment variables configured
- [ ] Database migrations prepared (if any)
- [ ] Backup created
- [ ] Team notified

### During Deployment

- [ ] Monitor Jenkins pipeline
- [ ] Watch health checks
- [ ] Verify smoke tests
- [ ] Confirm traffic switch
- [ ] Check application functionality

### Post-Deployment

- [ ] Verify application is accessible
- [ ] Run health check script
- [ ] Check logs for errors
- [ ] Monitor resource usage
- [ ] Verify database connectivity
- [ ] Test critical user flows
- [ ] Update deployment documentation

## Emergency Procedures

### Application Down

```bash
# 1. Check container status
docker ps -a

# 2. Check logs
docker-compose -f docker-compose.prod.yml logs --tail=100

# 3. Restart all services
docker-compose -f docker-compose.prod.yml restart

# 4. If still down, rollback
./deployment/rollback.sh
```

### Database Issues

```bash
# 1. Check database container
docker ps | grep postgres

# 2. Check database logs
docker logs postgres_prod

# 3. Connect to database
docker exec -it postgres_prod psql -U appuser -d appdb

# 4. Verify tables
\dt

# 5. Check connections
SELECT count(*) FROM pg_stat_activity;
```

### High Resource Usage

```bash
# 1. Check resource usage
docker stats

# 2. Check disk space
df -h

# 3. Clean up Docker
docker system prune -f

# 4. Restart services if needed
docker-compose -f docker-compose.prod.yml restart
```

## Best Practices

1. **Always test locally first**
   ```bash
   docker-compose up --build
   ```

2. **Deploy during low-traffic periods**
   - Schedule deployments for off-peak hours
   - Notify users of maintenance window (if needed)

3. **Monitor after deployment**
   - Watch logs for 15-30 minutes
   - Check error rates
   - Monitor performance metrics

4. **Keep rollback ready**
   - Previous environment always available
   - Rollback script tested and ready

5. **Document changes**
   - Update CHANGELOG
   - Document configuration changes
   - Note any manual steps required

## Next Steps

- [Troubleshooting Guide](./TROUBLESHOOTING.md)
- [AWS Setup Guide](./AWS-SETUP.md)
- [Jenkins Setup Guide](./JENKINS-SETUP.md)
