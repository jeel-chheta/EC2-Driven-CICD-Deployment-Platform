@echo off
echo ========================================
echo Starting EC2 CI/CD Platform Locally
echo ========================================
echo.

cd /d "%~dp0"

echo Checking Docker...
docker --version
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Docker is not installed or not running
    echo Please start Docker Desktop and try again
    pause
    exit /b 1
)

echo.
echo Starting services with Docker Compose...
docker-compose up --build

pause
