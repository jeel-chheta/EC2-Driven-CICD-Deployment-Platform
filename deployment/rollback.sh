#!/bin/bash

###############################################################################
# Rollback Script
# This script rolls back to the previous deployment environment
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DEPLOY_DIR="/home/ec2-user/app"

echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${RED}  Rollback Script${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Function to determine current active environment
get_active_environment() {
    local active_env=$(curl -s http://localhost/deployment-status | grep -o 'blue\|green' || echo 'blue')
    echo "$active_env"
}

# Function to get previous environment
get_previous_environment() {
    local current=$1
    if [ "$current" = "blue" ]; then
        echo "green"
    else
        echo "blue"
    fi
}

# Main rollback flow
main() {
    cd "$DEPLOY_DIR" || exit 1
    
    CURRENT_ENV=$(get_active_environment)
    PREVIOUS_ENV=$(get_previous_environment "$CURRENT_ENV")
    
    echo -e "${YELLOW}Current Active Environment: $CURRENT_ENV${NC}"
    echo -e "${YELLOW}Rolling back to: $PREVIOUS_ENV${NC}"
    echo ""
    
    # Confirm rollback
    read -p "Are you sure you want to rollback? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo -e "${BLUE}Rollback cancelled${NC}"
        exit 0
    fi
    
    echo ""
    echo -e "${YELLOW}🔄 Starting rollback process...${NC}"
    echo ""
    
    # Start previous environment if not running
    echo -e "${YELLOW}🚀 Starting $PREVIOUS_ENV environment...${NC}"
    docker-compose -f docker-compose.prod.yml up -d "backend_$PREVIOUS_ENV" "frontend_$PREVIOUS_ENV"
    
    echo -e "${YELLOW}⏳ Waiting for containers to start...${NC}"
    sleep 15
    
    # Health check on previous environment
    echo -e "${YELLOW}🏥 Checking health of $PREVIOUS_ENV environment...${NC}"
    
    if docker exec "backend_$PREVIOUS_ENV" node -e "require('http').get('http://localhost:5000/api/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})" 2>/dev/null; then
        if docker exec "frontend_$PREVIOUS_ENV" wget --quiet --tries=1 --spider http://localhost/ 2>/dev/null; then
            echo -e "${GREEN}✅ Health checks passed${NC}"
        else
            echo -e "${RED}❌ Frontend health check failed${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Backend health check failed${NC}"
        exit 1
    fi
    echo ""
    
    # Restore NGINX configuration
    echo -e "${YELLOW}🔄 Restoring NGINX configuration...${NC}"
    
    if [ -f nginx/nginx.prod.conf.backup ]; then
        cp nginx/nginx.prod.conf.backup nginx/nginx.prod.conf
    else
        # Manually switch back
        sed -i "s/server frontend_$CURRENT_ENV:80;/# server frontend_$CURRENT_ENV:80;/" nginx/nginx.prod.conf
        sed -i "s/# server frontend_$PREVIOUS_ENV:80;/server frontend_$PREVIOUS_ENV:80;/" nginx/nginx.prod.conf
        sed -i "s/server backend_$CURRENT_ENV:5000;/# server backend_$CURRENT_ENV:5000;/" nginx/nginx.prod.conf
        sed -i "s/# server backend_$PREVIOUS_ENV:5000;/server backend_$PREVIOUS_ENV:5000;/" nginx/nginx.prod.conf
        sed -i "s/X-Deployment-Version \"$CURRENT_ENV\"/X-Deployment-Version \"$PREVIOUS_ENV\"/" nginx/nginx.prod.conf
    fi
    
    # Reload NGINX
    if docker exec nginx_prod nginx -t 2>/dev/null; then
        docker exec nginx_prod nginx -s reload
        echo -e "${GREEN}✅ NGINX configuration restored${NC}"
    else
        echo -e "${RED}❌ NGINX configuration test failed${NC}"
        exit 1
    fi
    echo ""
    
    # Verify traffic routing
    echo -e "${YELLOW}🔍 Verifying traffic routing...${NC}"
    sleep 5
    
    deployment_version=$(curl -s -I http://localhost/ | grep -i "X-Deployment-Version" | awk '{print $2}' | tr -d '\r')
    
    if [ "$deployment_version" = "$PREVIOUS_ENV" ]; then
        echo -e "${GREEN}✅ Traffic successfully routed to $PREVIOUS_ENV${NC}"
    else
        echo -e "${RED}❌ Traffic routing verification failed${NC}"
        exit 1
    fi
    echo ""
    
    # Stop current (failed) environment
    echo -e "${YELLOW}🛑 Stopping $CURRENT_ENV environment...${NC}"
    docker-compose -f docker-compose.prod.yml stop "backend_$CURRENT_ENV" "frontend_$CURRENT_ENV"
    echo -e "${GREEN}✅ Failed environment stopped${NC}"
    echo ""
    
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ✅ ROLLBACK SUCCESSFUL${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  Active Environment: $PREVIOUS_ENV${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Run main function
main
