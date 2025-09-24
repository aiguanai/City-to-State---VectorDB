#!/bin/bash

# VectorDB Flask Application Deployment Script
# This script sets up the complete deployment with Supervisor and Nginx

set -e  # Exit on any error

echo "🚀 Starting VectorDB Flask Application Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Get the current directory
PROJECT_DIR=$(pwd)
print_status "Project directory: $PROJECT_DIR"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    print_error "Virtual environment not found. Please create it first with: python3 -m venv venv"
    exit 1
fi

# Activate virtual environment
print_status "Activating virtual environment..."
source venv/bin/activate

# Install/upgrade dependencies
print_status "Installing/upgrading Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Create log directories
print_status "Creating log directories..."
sudo mkdir -p /var/log/vectordb
sudo mkdir -p /var/log/nginx
sudo chown -R $USER:$USER /var/log/vectordb

# Install Supervisor if not installed
if ! command -v supervisord &> /dev/null; then
    print_status "Installing Supervisor..."
    sudo apt-get update
    sudo apt-get install -y supervisor
fi

# Install Nginx if not installed
if ! command -v nginx &> /dev/null; then
    print_status "Installing Nginx..."
    sudo apt-get update
    sudo apt-get install -y nginx
fi

# Copy Supervisor configuration
print_status "Setting up Supervisor configuration..."
# Replace placeholders in supervisor config
sed "s|PROJECT_DIR|$PROJECT_DIR|g; s|USER_NAME|$USER|g" vectordb_supervisor.conf > /tmp/vectordb_supervisor.conf
sudo cp /tmp/vectordb_supervisor.conf /etc/supervisor/conf.d/vectordb_supervisor.conf
sudo supervisorctl reread
sudo supervisorctl update

# Copy Nginx configuration
print_status "Setting up Nginx configuration..."
# Replace placeholders in nginx config
sed "s|PROJECT_DIR|$PROJECT_DIR|g" nginx_vectordb.conf > /tmp/nginx_vectordb.conf
sudo cp /tmp/nginx_vectordb.conf /etc/nginx/sites-available/vectordb
sudo ln -sf /etc/nginx/sites-available/vectordb /etc/nginx/sites-enabled/

# Remove default Nginx site if it exists
if [ -f "/etc/nginx/sites-enabled/default" ]; then
    print_status "Removing default Nginx site..."
    sudo rm /etc/nginx/sites-enabled/default
fi

# Test Nginx configuration
print_status "Testing Nginx configuration..."
sudo nginx -t

# Start services
print_status "Starting services..."

# Start Supervisor
sudo systemctl start supervisor
sudo systemctl enable supervisor

# Start Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Start the Flask application via Supervisor
print_status "Starting VectorDB Flask application..."
sudo supervisorctl start vectordb_flask

# Wait a moment for the application to start
sleep 5

# Check if the application is running
if sudo supervisorctl status vectordb_flask | grep -q "RUNNING"; then
    print_success "VectorDB Flask application is running!"
else
    print_error "Failed to start VectorDB Flask application"
    sudo supervisorctl status vectordb_flask
    exit 1
fi

# Check if Nginx is running
if sudo systemctl is-active --quiet nginx; then
    print_success "Nginx is running!"
else
    print_error "Nginx failed to start"
    sudo systemctl status nginx
    exit 1
fi

# Test the application
print_status "Testing the application..."
sleep 2

# Check if the application responds
if curl -s http://localhost/health > /dev/null; then
    print_success "Application is responding to health checks!"
else
    print_warning "Application health check failed, but services are running"
fi

# Display status
echo ""
print_success "🎉 Deployment completed successfully!"
echo ""
echo "📋 Service Status:"
echo "=================="
sudo supervisorctl status vectordb_flask
sudo systemctl status nginx --no-pager -l
echo ""
echo "🌐 Application URLs:"
echo "==================="
echo "Main Application: http://localhost"
echo "Health Check: http://localhost/health"
echo ""
echo "📁 Important Files:"
echo "=================="
echo "Supervisor Config: /etc/supervisor/conf.d/vectordb_supervisor.conf"
echo "Nginx Config: /etc/nginx/sites-available/vectordb"
echo "Application Logs: /var/log/vectordb/"
echo "Nginx Logs: /var/log/nginx/"
echo ""
echo "🔧 Management Commands:"
echo "======================"
echo "Restart Flask App: sudo supervisorctl restart vectordb_flask"
echo "Restart Nginx: sudo systemctl restart nginx"
echo "View Flask Logs: sudo supervisorctl tail -f vectordb_flask"
echo "View Nginx Logs: sudo tail -f /var/log/nginx/vectordb_access.log"
echo ""
print_success "Your VectorDB Flask application is now live! 🚀"
