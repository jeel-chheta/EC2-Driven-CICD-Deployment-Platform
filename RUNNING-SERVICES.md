# 🚀 EC2 CI/CD Platform - Running Services

## ✅ Status: All Services Running

Your DevOps platform is now running successfully on Docker!

---

## 📋 Service Overview

| Service | Container | Status | Port Mapping |
|---------|-----------|--------|--------------|
| **Frontend** | `frontend` | ✅ Running | `http://localhost:3000` → Port 80 |
| **Backend API** | `backend` | ✅ Running | `http://localhost:5000` |
| **NGINX Proxy** | `nginx` | ✅ Running | `http://localhost:80` |
| **PostgreSQL** | `postgres` | ✅ Healthy | `localhost:5432` |

---

## 🌐 Access URLs

### Main Application
- **Frontend (via NGINX)**: http://localhost/
- **API Health Check**: http://localhost/api/health
- **API Users Endpoint**: http://localhost/api/users

### Direct Access
- **Frontend Direct**: http://localhost:3000
- **Backend Direct**: http://localhost:5000
- **PostgreSQL**: `localhost:5432`

---

## 🔧 Database Connection Details

```
Host: localhost
Port: 5432
Database: appdb
Username: appuser
Password: securepassword123
```

---

## 📊 Quick Commands

### View All Running Containers
```bash
docker-compose ps
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f postgres
docker-compose logs -f nginx
```

### Stop All Services
```bash
docker-compose down
```

### Stop and Remove Volumes
```bash
docker-compose down -v
```

### Restart Services
```bash
docker-compose restart
```

### Rebuild and Restart
```bash
docker-compose up --build -d
```

---

## 🧪 Test the Application

### Test Backend Health
```powershell
Invoke-WebRequest -Uri "http://localhost/api/health" -UseBasicParsing
```

### Test Users API
```powershell
Invoke-WebRequest -Uri "http://localhost/api/users" -UseBasicParsing
```

### Test Frontend
```powershell
Invoke-WebRequest -Uri "http://localhost/" -UseBasicParsing
```

---

## 📝 Sample Data

The database has been initialized with 8 sample users:
- John Doe (john.doe@example.com)
- Jane Smith (jane.smith@example.com)
- Bob Johnson (bob.johnson@example.com)
- Alice Williams (alice.williams@example.com)
- Charlie Brown (charlie.brown@example.com)
- Diana Prince (diana.prince@example.com)
- Ethan Hunt (ethan.hunt@example.com)
- Fiona Green (fiona.green@example.com)

---

## 🔍 Troubleshooting

### Check Container Status
```bash
docker ps -a
```

### View Container Logs
```bash
docker logs <container_name>
```

### Restart a Specific Service
```bash
docker-compose restart <service_name>
```

### Access Container Shell
```bash
docker exec -it <container_name> sh
```

---

## 🎯 Next Steps

1. **Access the Frontend**: Open http://localhost/ in your browser
2. **Test the API**: Use the endpoints listed above
3. **Monitor Logs**: Use `docker-compose logs -f` to watch real-time logs
4. **Explore the Database**: Connect using the credentials above

---

**Last Updated**: 2026-01-21 10:04 IST
**Status**: ✅ All Systems Operational
