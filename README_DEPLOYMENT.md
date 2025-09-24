# VectorDB Flask Application - Deployment Guide

This guide provides complete instructions for deploying the VectorDB Flask application with Supervisor and Nginx on a Linux server.

## Architecture Overview

```
Internet → Nginx (Port 80) → Flask App (Port 5000) → VectorDB (FAISS)
```

- **Nginx**: Web server and reverse proxy
- **Supervisor**: Process manager for Flask application
- **Flask**: Web application with city-to-state lookup
- **FAISS**: Vector database for similarity search

## Prerequisites

- Ubuntu 18.04+ or similar Linux distribution
- Python 3.8+
- sudo privileges
- Internet connection for downloading dependencies

## Quick Deployment

### 1. Clone and Setup

```bash
# Clone your repository
git clone <your-repo-url>
cd c2s

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Run Deployment Script

```bash
# Make scripts executable
chmod +x setup_deployment.sh
chmod +x manage_services.sh

# Run full deployment
./setup_deployment.sh
```

The deployment script will:
- Install Supervisor and Nginx
- Configure both services
- Start the Flask application
- Set up log directories
- Test the deployment

## Manual Deployment Steps

If you prefer manual setup:

### 1. Install Dependencies

```bash
# Update system
sudo apt-get update

# Install Python dependencies
sudo apt-get install -y python3-pip python3-venv

# Install Supervisor
sudo apt-get install -y supervisor

# Install Nginx
sudo apt-get install -y nginx
```

### 2. Setup Python Environment

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python packages
pip install --upgrade pip
pip install -r requirements.txt
```

### 3. Configure Supervisor

```bash
# Copy Supervisor configuration
sudo cp vectordb_supervisor.conf /etc/supervisor/conf.d/

# Reload Supervisor configuration
sudo supervisorctl reread
sudo supervisorctl update
```

### 4. Configure Nginx

```bash
# Copy Nginx configuration
sudo cp nginx_vectordb.conf /etc/nginx/sites-available/vectordb

# Enable the site
sudo ln -sf /etc/nginx/sites-available/vectordb /etc/nginx/sites-enabled/

# Remove default site
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t
```

### 5. Start Services

```bash
# Start Supervisor
sudo systemctl start supervisor
sudo systemctl enable supervisor

# Start Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Start Flask application
sudo supervisorctl start vectordb_flask
```

## Service Management

Use the management script for easy service control:

```bash
# Start services
./manage_services.sh start

# Stop services
./manage_services.sh stop

# Restart services
./manage_services.sh restart

# Check status
./manage_services.sh status

# View logs
./manage_services.sh logs

# Check health
./manage_services.sh health

# Update application
./manage_services.sh update
```

## Monitoring and Logs

### Application Logs

```bash
# View real-time logs
sudo supervisorctl tail -f vectordb_flask

# View log files
tail -f /var/log/vectordb/supervisor.log
tail -f /var/log/vectordb/error.log
```

### Nginx Logs

```bash
# Access logs
sudo tail -f /var/log/nginx/vectordb_access.log

# Error logs
sudo tail -f /var/log/nginx/vectordb_error.log
```

### Health Monitoring

```bash
# Check application health
curl http://localhost/health

# Check service status
sudo supervisorctl status vectordb_flask
sudo systemctl status nginx
```

## 🌐 Accessing the Application

- **Main Application**: http://your-server-ip
- **Health Check**: http://your-server-ip/health
- **API Endpoints**:
  - `POST /search` - Single city search
  - `POST /search_multiple` - Multiple results search

## Configuration Files

### Supervisor Configuration (`vectordb_supervisor.conf`)

Key settings:
- **Command**: Gunicorn with 2 workers
- **Port**: 5000 (internal)
- **Logs**: `/var/log/vectordb/`
- **Auto-restart**: Enabled

### Nginx Configuration (`nginx_vectordb.conf`)

Key settings:
- **Listen**: Port 80
- **Proxy**: Pass to 127.0.0.1:5000
- **Gzip**: Enabled for compression
- **Security**: Headers configured

## Troubleshooting

### Common Issues

1. **Application won't start**
   ```bash
   # Check Supervisor logs
   sudo supervisorctl tail vectordb_flask stderr
   
   # Check if port is in use
   sudo netstat -tlnp | grep :5000
   ```

2. **Nginx 502 Bad Gateway**
   ```bash
   # Check if Flask app is running
   sudo supervisorctl status vectordb_flask
   
   # Check Nginx error logs
   sudo tail -f /var/log/nginx/error.log
   ```

3. **Model loading issues**
   ```bash
   # Check if model files exist
   ls -la .cache/
   
   # Check application logs
   sudo supervisorctl tail vectordb_flask stdout
   ```

### Performance Tuning

1. **Increase Gunicorn workers** (in `vectordb_supervisor.conf`):
   ```bash
   --workers 4  # Adjust based on CPU cores
   ```

2. **Enable Nginx caching** (in `nginx_vectordb.conf`):
   ```nginx
   proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=vectordb:10m;
   ```

3. **Optimize system resources**:
   ```bash
   # Increase file limits
   echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
   echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf
   ```

## Security Considerations

1. **Firewall Configuration**:
   ```bash
   # Allow only HTTP/HTTPS
   sudo ufw allow 80
   sudo ufw allow 443
   sudo ufw enable
   ```

2. **SSL/HTTPS Setup** (using Let's Encrypt):
   ```bash
   # Install Certbot
   sudo apt-get install certbot python3-certbot-nginx
   
   # Get SSL certificate
   sudo certbot --nginx -d your-domain.com
   ```

3. **Application Security**:
   - Nginx security headers are configured
   - Input validation in Flask application
   - Rate limiting can be added to Nginx

## Scaling and Production

### Load Balancing

For multiple application instances:

```nginx
upstream vectordb_backend {
    server 127.0.0.1:5000;
    server 127.0.0.1:5001;
    server 127.0.0.1:5002;
}

server {
    location / {
        proxy_pass http://vectordb_backend;
    }
}
```

### Monitoring

Consider adding:
- **Prometheus** for metrics
- **Grafana** for dashboards
- **ELK Stack** for log aggregation

## Support

If you encounter issues:

1. Check the logs first
2. Verify all services are running
3. Test the health endpoint
4. Review configuration files
5. Check system resources (CPU, memory, disk)

## 📝 Maintenance

### Regular Tasks

1. **Update dependencies**:
   ```bash
   ./manage_services.sh update
   ```

2. **Rotate logs**:
   ```bash
   sudo logrotate -f /etc/logrotate.d/vectordb
   ```

3. **Monitor disk space**:
   ```bash
   df -h
   du -sh /var/log/vectordb/
   ```

4. **Backup configuration**:
   ```bash
   sudo cp -r /etc/supervisor/conf.d/ /backup/
   sudo cp -r /etc/nginx/sites-available/ /backup/
   ```

This deployment provides a robust, production-ready setup for your VectorDB Flask application.