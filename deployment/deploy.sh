#!/bin/bash

###############################################################################
# Blue-Green Deployment Script
# This script performs a zero-downtime deployment using blue-green strategy
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEPLOY_DIR="/home/ec2-user/app"
BACKEND_IMAGE="${BACKEND_IMAGE:-backend:latest}"
FRONTEND_IMAGE="${FRONTEND_IMAGE:-frontend:latest}"
MAX_HEALTH_RETRIES=12
HEALTH_CHECK_INTERVAL=10

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Blue-Green Deployment Script${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Function to determine current active environment
get_active_environment() {
    local active_env=$(curl -s http://localhost/deployment-status | grep -o 'blue\|green' || echo 'blue')
    echo "$active_env"
}

# Function to get target environment
get_target_environment() {
    local current=$1
    if [ "$current" = "blue" ]; then
        echo "green"
    else
        echo "blue"
    fi
}

# Function to perform health check
health_check() {
    local env=$1
    local retry=0
    
    echo -e "${YELLOW}🏥 Performing health checks on $env environment...${NC}"
    
    while [ $retry -lt $MAX_HEALTH_RETRIES ]; do
        # Check backend
        if docker exec "backend_$env" node -e "require('http').get('http://localhost:5000/api/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})" 2>/dev/null; then
            # Check frontend
            if docker exec "frontend_$env" wget --quiet --tries=1 --spider http://localhost/ 2>/dev/null; then
                echo -e "${GREEN}✅ Health checks passed${NC}"
                return 0
            fi
        fi
        
        retry=$((retry + 1))
        echo -e "${YELLOW}⏳ Health check attempt $retry/$MAX_HEALTH_RETRIES failed, retrying in ${HEALTH_CHECK_INTERVAL}s...${NC}"
        sleep $HEALTH_CHECK_INTERVAL
    done
    
    echo -e "${RED}❌ Health checks failed after $MAX_HEALTH_RETRIES attempts${NC}"
    return 1
}

# Function to switch traffic
switch_traffic() {
    local from_env=$1
    local to_env=$2
    
    echo -e "${YELLOW}🔄 Switching traffic from $from_env to $to_env...${NC}"
    
    # Backup current NGINX config
    cp nginx/nginx.prod.conf nginx/nginx.prod.conf.backup
    
    # Update NGINX config
    sed -i "s/server frontend_$from_env:80;/# server frontend_$from_env:80;/" nginx/nginx.prod.conf
    sed -i "s/# server frontend_$to_env:80;/server frontend_$to_env:80;/" nginx/nginx.prod.conf
    sed -i "s/server backend_$from_env:5000;/# server backend_$from_env:5000;/" nginx/nginx.prod.conf
    sed -i "s/# server backend_$to_env:5000;/server backend_$to_env:5000;/" nginx/nginx.prod.conf
    sed -i "s/X-Deployment-Version \"$from_env\"/X-Deployment-Version \"$to_env\"/" nginx/nginx.prod.conf
    
    # Test and reload NGINX
    if docker exec nginx_prod nginx -t 2>/dev/null; then
        docker exec nginx_prod nginx -s reload
        echo -e "${GREEN}✅ Traffic switched to $to_env${NC}"
        sleep 5
        return 0
    else
        echo -e "${RED}❌ NGINX configuration test failed${NC}"
        # Restore backup
        cp nginx/nginx.prod.conf.backup nginx/nginx.prod.conf
        return 1
    fi
}

# Function to verify traffic routing
verify_traffic() {
    local expected_env=$1
    
    echo -e "${YELLOW}🔍 Verifying traffic routing...${NC}"
    
    local deployment_version=$(curl -s -I http://localhost/ | grep -i "X-Deployment-Version" | awk '{print $2}' | tr -d '\r')
    
    if [ "$deployment_version" = "$expected_env" ]; then
        echo -e "${GREEN}✅ Traffic successfully routed to $expected_env${NC}"
        return 0
    else
        echo -e "${RED}❌ Traffic routing verification failed (expected: $expected_env, got: $deployment_version)${NC}"
        return 1
    fi
}

# Main deployment flow
main() {
    cd "$DEPLOY_DIR" || exit 1
    
    # Determine environments
    CURRENT_ENV=$(get_active_environment)
    TARGET_ENV=$(get_target_environment "$CURRENT_ENV")
    
    echo -e "${BLUE}Current Environment: $CURRENT_ENV${NC}"
    echo -e "${BLUE}Target Environment: $TARGET_ENV${NC}"
    echo ""
    
    # Pull latest images
    echo -e "${YELLOW}📦 Pulling latest Docker images...${NC}"
    docker pull "$BACKEND_IMAGE"
    docker pull "$FRONTEND_IMAGE"
    echo -e "${GREEN}✅ Images pulled${NC}"
    echo ""
    
    # Deploy to target environment
    echo -e "${YELLOW}🚀 Deploying to $TARGET_ENV environment...${NC}"
    export BACKEND_IMAGE
    export FRONTEND_IMAGE
    
    docker-compose -f docker-compose.prod.yml --profile "$TARGET_ENV" up -d "backend_$TARGET_ENV" "frontend_$TARGET_ENV"
    
    echo -e "${GREEN}✅ Containers started${NC}"
    echo ""
    
    # Wait for containers to initialize
    echo -e "${YELLOW}⏳ Waiting for containers to initialize...${NC}"
    sleep 15
    
    # Health checks
    if ! health_check "$TARGET_ENV"; then
        echo -e "${RED}❌ Deployment failed: Health checks did not pass${NC}"
        echo -e "${YELLOW}🔄 Stopping failed deployment...${NC}"
        docker-compose -f docker-compose.prod.yml stop "backend_$TARGET_ENV" "frontend_$TARGET_ENV"
        exit 1
    fi
    echo ""
    
    # Switch traffic
    if ! switch_traffic "$CURRENT_ENV" "$TARGET_ENV"; then
        echo -e "${RED}❌ Deployment failed: Traffic switch failed${NC}"
        echo -e "${YELLOW}🔄 Stopping failed deployment...${NC}"
        docker-compose -f docker-compose.prod.yml stop "backend_$TARGET_ENV" "frontend_$TARGET_ENV"
        exit 1
    fi
    echo ""
    
    # Verify traffic routing
    if ! verify_traffic "$TARGET_ENV"; then
        echo -e "${RED}❌ Deployment failed: Traffic verification failed${NC}"
        echo -e "${YELLOW}🔄 Rolling back...${NC}"
        switch_traffic "$TARGET_ENV" "$CURRENT_ENV"
        docker-compose -f docker-compose.prod.yml stop "backend_$TARGET_ENV" "frontend_$TARGET_ENV"
        exit 1
    fi
    echo ""
    
    # Stop old environment
    echo -e "${YELLOW}🛑 Stopping $CURRENT_ENV environment...${NC}"
    docker-compose -f docker-compose.prod.yml stop "backend_$CURRENT_ENV" "frontend_$CURRENT_ENV"
    echo -e "${GREEN}✅ Old environment stopped${NC}"
    echo ""
    
    # Cleanup
    echo -e "${YELLOW}🧹 Cleaning up old images...${NC}"
    docker image prune -f
    echo -e "${GREEN}✅ Cleanup complete${NC}"
    echo ""
    
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ✅ DEPLOYMENT SUCCESSFUL${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  Active Environment: $TARGET_ENV${NC}"
    echo -e "${GREEN}  Backend Image: $BACKEND_IMAGE${NC}"
    echo -e "${GREEN}  Frontend Image: $FRONTEND_IMAGE${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Run main function
main
