#!/bin/bash

# VectorDB Flask Application Service Management Script
# This script provides easy commands to manage the VectorDB Flask application

set -e

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

# Function to show usage
show_usage() {
    echo "VectorDB Flask Application Service Manager"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start       Start the VectorDB Flask application"
    echo "  stop        Stop the VectorDB Flask application"
    echo "  restart     Restart the VectorDB Flask application"
    echo "  status      Show status of all services"
    echo "  logs        Show application logs"
    echo "  nginx-logs  Show Nginx logs"
    echo "  health      Check application health"
    echo "  update      Update application code and restart"
    echo "  deploy      Full deployment (setup + start)"
    echo "  help        Show this help message"
    echo ""
}

# Function to start services
start_services() {
    print_status "Starting VectorDB Flask application..."
    sudo supervisorctl start vectordb_flask
    
    print_status "Starting Nginx..."
    sudo systemctl start nginx
    
    sleep 3
    
    if sudo supervisorctl status vectordb_flask | grep -q "RUNNING"; then
        print_success "VectorDB Flask application started successfully!"
    else
        print_error "Failed to start VectorDB Flask application"
        sudo supervisorctl status vectordb_flask
        exit 1
    fi
    
    if sudo systemctl is-active --quiet nginx; then
        print_success "Nginx started successfully!"
    else
        print_error "Failed to start Nginx"
        sudo systemctl status nginx
        exit 1
    fi
}

# Function to stop services
stop_services() {
    print_status "Stopping VectorDB Flask application..."
    sudo supervisorctl stop vectordb_flask
    
    print_status "Stopping Nginx..."
    sudo systemctl stop nginx
    
    print_success "Services stopped successfully!"
}

# Function to restart services
restart_services() {
    print_status "Restarting VectorDB Flask application..."
    sudo supervisorctl restart vectordb_flask
    
    print_status "Restarting Nginx..."
    sudo systemctl restart nginx
    
    sleep 3
    
    if sudo supervisorctl status vectordb_flask | grep -q "RUNNING"; then
        print_success "VectorDB Flask application restarted successfully!"
    else
        print_error "Failed to restart VectorDB Flask application"
        sudo supervisorctl status vectordb_flask
        exit 1
    fi
    
    if sudo systemctl is-active --quiet nginx; then
        print_success "Nginx restarted successfully!"
    else
        print_error "Failed to restart Nginx"
        sudo systemctl status nginx
        exit 1
    fi
}

# Function to show status
show_status() {
    echo "📊 Service Status:"
    echo "=================="
    echo ""
    echo "🔹 VectorDB Flask Application:"
    sudo supervisorctl status vectordb_flask
    echo ""
    echo "🔹 Nginx:"
    sudo systemctl status nginx --no-pager -l
    echo ""
    echo "🔹 System Resources:"
    echo "Memory Usage:"
    free -h
    echo ""
    echo "Disk Usage:"
    df -h /
    echo ""
}

# Function to show logs
show_logs() {
    echo "📋 VectorDB Flask Application Logs:"
    echo "===================================="
    sudo supervisorctl tail -f vectordb_flask
}

# Function to show Nginx logs
show_nginx_logs() {
    echo "📋 Nginx Access Logs:"
    echo "====================="
    sudo tail -f /var/log/nginx/vectordb_access.log
}

# Function to check health
check_health() {
    print_status "Checking application health..."
    
    if curl -s http://localhost/health > /dev/null; then
        print_success "✅ Application is healthy and responding!"
        echo ""
        echo "Health Check Response:"
        curl -s http://localhost/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost/health
    else
        print_error "❌ Application health check failed!"
        echo "Please check the logs for more information."
    fi
}

# Function to update application
update_application() {
    print_status "Updating application code..."
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Install/upgrade dependencies
    print_status "Updating dependencies..."
    pip install --upgrade pip
    pip install -r requirements.txt
    
    # Restart the application
    print_status "Restarting application..."
    sudo supervisorctl restart vectordb_flask
    
    sleep 3
    
    if sudo supervisorctl status vectordb_flask | grep -q "RUNNING"; then
        print_success "Application updated and restarted successfully!"
    else
        print_error "Failed to restart application after update"
        sudo supervisorctl status vectordb_flask
        exit 1
    fi
}

# Function to deploy
deploy() {
    print_status "Running full deployment..."
    chmod +x setup_deployment.sh
    ./setup_deployment.sh
}

# Main script logic
case "${1:-help}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    nginx-logs)
        show_nginx_logs
        ;;
    health)
        check_health
        ;;
    update)
        update_application
        ;;
    deploy)
        deploy
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_usage
        exit 1
        ;;
esac
