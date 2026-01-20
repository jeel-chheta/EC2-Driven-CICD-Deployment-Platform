#!/bin/bash

###############################################################################
# Health Check Script
# This script performs comprehensive health checks on the deployed application
###############################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_URL="${BACKEND_URL:-http://localhost/api}"
FRONTEND_URL="${FRONTEND_URL:-http://localhost}"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Health Check Script${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Track overall health
OVERALL_HEALTH=0

# Function to check endpoint
check_endpoint() {
    local name=$1
    local url=$2
    local expected_status=${3:-200}
    
    echo -e "${YELLOW}Checking $name...${NC}"
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    
    if [ "$response" = "$expected_status" ]; then
        echo -e "${GREEN}✅ $name: OK (HTTP $response)${NC}"
        return 0
    else
        echo -e "${RED}❌ $name: FAILED (HTTP $response, expected $expected_status)${NC}"
        OVERALL_HEALTH=1
        return 1
    fi
}

# Function to check response time
check_response_time() {
    local name=$1
    local url=$2
    local max_time=${3:-2}
    
    echo -e "${YELLOW}Checking $name response time...${NC}"
    
    response_time=$(curl -s -o /dev/null -w "%{time_total}" "$url" 2>/dev/null)
    response_time_ms=$(echo "$response_time * 1000" | bc)
    max_time_ms=$(echo "$max_time * 1000" | bc)
    
    if (( $(echo "$response_time < $max_time" | bc -l) )); then
        echo -e "${GREEN}✅ $name response time: ${response_time_ms}ms (< ${max_time_ms}ms)${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  $name response time: ${response_time_ms}ms (> ${max_time_ms}ms)${NC}"
        return 0  # Warning, not failure
    fi
}

# Function to check JSON response
check_json_response() {
    local name=$1
    local url=$2
    local expected_field=$3
    
    echo -e "${YELLOW}Checking $name JSON response...${NC}"
    
    response=$(curl -s "$url" 2>/dev/null)
    
    if echo "$response" | grep -q "$expected_field"; then
        echo -e "${GREEN}✅ $name: Valid JSON response${NC}"
        return 0
    else
        echo -e "${RED}❌ $name: Invalid JSON response (missing field: $expected_field)${NC}"
        OVERALL_HEALTH=1
        return 1
    fi
}

# Function to check Docker containers
check_containers() {
    echo -e "${YELLOW}Checking Docker containers...${NC}"
    
    local containers=("nginx_prod" "postgres_prod")
    local active_env=$(curl -s http://localhost/deployment-status | grep -o 'blue\|green' || echo 'blue')
    
    containers+=("backend_$active_env" "frontend_$active_env")
    
    local all_healthy=0
    
    for container in "${containers[@]}"; do
        if docker ps --filter "name=$container" --filter "status=running" | grep -q "$container"; then
            # Check health status if available
            health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "none")
            
            if [ "$health" = "healthy" ] || [ "$health" = "none" ]; then
                echo -e "${GREEN}✅ Container $container: Running${NC}"
            else
                echo -e "${YELLOW}⚠️  Container $container: Running but health status is $health${NC}"
            fi
        else
            echo -e "${RED}❌ Container $container: Not running${NC}"
            all_healthy=1
            OVERALL_HEALTH=1
        fi
    done
    
    return $all_healthy
}

# Function to check disk space
check_disk_space() {
    echo -e "${YELLOW}Checking disk space...${NC}"
    
    disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$disk_usage" -lt 80 ]; then
        echo -e "${GREEN}✅ Disk usage: ${disk_usage}% (< 80%)${NC}"
        return 0
    elif [ "$disk_usage" -lt 90 ]; then
        echo -e "${YELLOW}⚠️  Disk usage: ${disk_usage}% (Warning: > 80%)${NC}"
        return 0
    else
        echo -e "${RED}❌ Disk usage: ${disk_usage}% (Critical: > 90%)${NC}"
        OVERALL_HEALTH=1
        return 1
    fi
}

# Function to check memory usage
check_memory() {
    echo -e "${YELLOW}Checking memory usage...${NC}"
    
    mem_usage=$(free | awk 'NR==2 {printf "%.0f", $3/$2 * 100}')
    
    if [ "$mem_usage" -lt 80 ]; then
        echo -e "${GREEN}✅ Memory usage: ${mem_usage}% (< 80%)${NC}"
        return 0
    elif [ "$mem_usage" -lt 90 ]; then
        echo -e "${YELLOW}⚠️  Memory usage: ${mem_usage}% (Warning: > 80%)${NC}"
        return 0
    else
        echo -e "${RED}❌ Memory usage: ${mem_usage}% (Critical: > 90%)${NC}"
        OVERALL_HEALTH=1
        return 1
    fi
}

# Main health check flow
main() {
    echo -e "${BLUE}Running comprehensive health checks...${NC}"
    echo ""
    
    # Check frontend
    echo -e "${BLUE}Frontend Checks:${NC}"
    check_endpoint "Frontend" "$FRONTEND_URL" 200
    check_response_time "Frontend" "$FRONTEND_URL" 2
    echo ""
    
    # Check backend API
    echo -e "${BLUE}Backend API Checks:${NC}"
    check_endpoint "Backend Health" "$BACKEND_URL/health" 200
    check_json_response "Backend Health" "$BACKEND_URL/health" "status"
    check_response_time "Backend Health" "$BACKEND_URL/health" 1
    echo ""
    
    check_endpoint "Backend Users API" "$BACKEND_URL/users" 200
    check_json_response "Backend Users API" "$BACKEND_URL/users" "email"
    echo ""
    
    # Check infrastructure
    echo -e "${BLUE}Infrastructure Checks:${NC}"
    check_containers
    echo ""
    
    check_disk_space
    check_memory
    echo ""
    
    # Check deployment status
    echo -e "${BLUE}Deployment Status:${NC}"
    active_env=$(curl -s http://localhost/deployment-status | grep -o 'blue\|green' || echo 'unknown')
    echo -e "${GREEN}Active Environment: $active_env${NC}"
    echo ""
    
    # Summary
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if [ $OVERALL_HEALTH -eq 0 ]; then
        echo -e "${GREEN}  ✅ ALL HEALTH CHECKS PASSED${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        exit 0
    else
        echo -e "${RED}  ❌ SOME HEALTH CHECKS FAILED${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        exit 1
    fi
}

# Run main function
main
