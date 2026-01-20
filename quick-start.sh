#!/bin/bash

###############################################################################
# Quick Start Script for EC2-Driven CI/CD Deployment Platform
# This script helps you get started with local development
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  EC2-Driven CI/CD Deployment Platform - Quick Start${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    echo -e "${YELLOW}Please install Docker: https://docs.docker.com/get-docker/${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Docker is installed${NC}"
fi

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed${NC}"
    echo -e "${YELLOW}Please install Docker Compose: https://docs.docker.com/compose/install/${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Docker Compose is installed${NC}"
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker is not running${NC}"
    echo -e "${YELLOW}Please start Docker and try again${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Docker is running${NC}"
fi

echo ""

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file from template...${NC}"
    cp .env.example .env
    echo -e "${GREEN}✅ .env file created${NC}"
    echo -e "${YELLOW}⚠️  Please update .env with your configuration${NC}"
else
    echo -e "${GREEN}✅ .env file already exists${NC}"
fi

echo ""

# Ask user what they want to do
echo -e "${BLUE}What would you like to do?${NC}"
echo ""
echo "1) Start local development environment"
echo "2) View project documentation"
echo "3) Run health checks"
echo "4) Stop all services"
echo "5) Clean up Docker resources"
echo "6) Exit"
echo ""
read -p "Enter your choice (1-6): " choice

case $choice in
    1)
        echo ""
        echo -e "${YELLOW}🚀 Starting local development environment...${NC}"
        echo ""
        
        # Build and start services
        docker-compose up --build -d
        
        echo ""
        echo -e "${GREEN}✅ Services started successfully!${NC}"
        echo ""
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}  Application is running!${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${GREEN}Frontend:${NC}      http://localhost"
        echo -e "${GREEN}Backend API:${NC}   http://localhost/api"
        echo -e "${GREEN}Health Check:${NC}  http://localhost/api/health"
        echo -e "${GREEN}Users API:${NC}     http://localhost/api/users"
        echo ""
        echo -e "${YELLOW}View logs:${NC}     docker-compose logs -f"
        echo -e "${YELLOW}Stop services:${NC} docker-compose down"
        echo ""
        
        # Wait a bit for services to start
        echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
        sleep 10
        
        # Check health
        echo -e "${YELLOW}🏥 Checking application health...${NC}"
        if curl -s http://localhost/api/health > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Application is healthy!${NC}"
        else
            echo -e "${YELLOW}⚠️  Application is starting... Please wait a moment and check http://localhost${NC}"
        fi
        ;;
        
    2)
        echo ""
        echo -e "${BLUE}📚 Project Documentation${NC}"
        echo ""
        echo "Main Documentation:"
        echo "  - README.md                    - Project overview and quick start"
        echo "  - PROJECT-SUMMARY.md           - Complete project summary"
        echo ""
        echo "Setup Guides:"
        echo "  - docs/AWS-SETUP.md            - AWS EC2 setup instructions"
        echo "  - docs/JENKINS-SETUP.md        - Jenkins configuration guide"
        echo "  - docs/DEPLOYMENT.md           - Deployment procedures"
        echo "  - docs/TROUBLESHOOTING.md      - Troubleshooting guide"
        echo ""
        ;;
        
    3)
        echo ""
        echo -e "${YELLOW}🏥 Running health checks...${NC}"
        echo ""
        
        # Check if services are running
        if ! docker-compose ps | grep -q "Up"; then
            echo -e "${RED}❌ Services are not running${NC}"
            echo -e "${YELLOW}Start services first with: docker-compose up -d${NC}"
            exit 1
        fi
        
        # Check frontend
        echo -e "${YELLOW}Checking frontend...${NC}"
        if curl -s http://localhost > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Frontend is accessible${NC}"
        else
            echo -e "${RED}❌ Frontend is not accessible${NC}"
        fi
        
        # Check backend health
        echo -e "${YELLOW}Checking backend health...${NC}"
        if curl -s http://localhost/api/health > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Backend is healthy${NC}"
            curl -s http://localhost/api/health | grep -o '"status":"[^"]*"' || true
        else
            echo -e "${RED}❌ Backend is not healthy${NC}"
        fi
        
        # Check users API
        echo -e "${YELLOW}Checking users API...${NC}"
        if curl -s http://localhost/api/users > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Users API is working${NC}"
        else
            echo -e "${RED}❌ Users API is not working${NC}"
        fi
        
        echo ""
        ;;
        
    4)
        echo ""
        echo -e "${YELLOW}🛑 Stopping all services...${NC}"
        docker-compose down
        echo -e "${GREEN}✅ All services stopped${NC}"
        echo ""
        ;;
        
    5)
        echo ""
        echo -e "${YELLOW}🧹 Cleaning up Docker resources...${NC}"
        echo ""
        
        # Stop services
        docker-compose down
        
        # Remove dangling images
        docker image prune -f
        
        # Remove unused volumes (be careful!)
        read -p "Remove unused volumes? This will delete data (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            docker volume prune -f
            echo -e "${GREEN}✅ Volumes removed${NC}"
        fi
        
        echo ""
        echo -e "${GREEN}✅ Cleanup complete${NC}"
        echo ""
        ;;
        
    6)
        echo ""
        echo -e "${BLUE}Goodbye! 👋${NC}"
        echo ""
        exit 0
        ;;
        
    *)
        echo ""
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Need help? Check the documentation in the docs/ folder${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
