#!/bin/bash

################################################################################
# HNG DevOps Stage 1: Automated Deployment Bash Script
# Description: Production-grade Bash script for automated Docker application
#              deployment on remote Linux servers
# Author: DevOps Intern
# Date: October 2025
################################################################################

set -euo pipefail

################################################################################
# GLOBAL VARIABLES
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/deploy_$(date +%Y%m%d_%H%M%S).log"
CLEANUP_FLAG=false
DEBUG_MODE="${DEBUG:-false}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Deployment configuration
GIT_REPO=""
GIT_PAT=""
GIT_BRANCH="main"
REMOTE_USER=""
REMOTE_IP=""
SSH_KEY=""
APP_PORT=""
LOCAL_REPO_NAME=""
NGINX_CONFIG_PATH="/etc/nginx/sites-available"
NGINX_ENABLED_PATH="/etc/nginx/sites-enabled"

################################################################################
# LOGGING FUNCTIONS
################################################################################

# Initialize logging
init_logging() {
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "Deployment Script Started"
    log_info "Date: $(date '+%Y-%m-%d %H:%M:%S')"
    log_info "Log File: $LOG_FILE"
    log_info "═══════════════════════════════════════════════════════════════"
}

log_info() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[${timestamp}] INFO:${NC} $*" | tee -a "$LOG_FILE"
}

log_success() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[${timestamp}] SUCCESS:${NC} $*" | tee -a "$LOG_FILE"
}

log_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[${timestamp}] ERROR:${NC} $*" | tee -a "$LOG_FILE" >&2
}

log_warning() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[${timestamp}] WARNING:${NC} $*" | tee -a "$LOG_FILE"
}

################################################################################
# ERROR HANDLING & CLEANUP
################################################################################

# Trap function for unexpected errors
trap 'handle_error $? $LINENO' ERR
trap 'handle_cleanup' EXIT

handle_error() {
    local exit_code=$1
    local line_number=$2
    log_error "Script failed at line ${line_number} with exit code ${exit_code}"
    log_info "Deployment FAILED"
    exit "$exit_code"
}

handle_cleanup() {
    if [[ $CLEANUP_FLAG == true ]]; then
        log_info "Performing cleanup operations..."
        cleanup_deployment
    fi
}

################################################################################
# VALIDATION FUNCTIONS
################################################################################

validate_git_url() {
    local url=$1
    if [[ $url =~ ^https?://.*\.git$ ]] || [[ $url =~ ^git@.*:.*\.git$ ]]; then
        return 0
    else
        log_error "Invalid Git URL format: $url"
        return 1
    fi
}

validate_ip_address() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        # Check if each octet is valid (0-255)
        local IFS='.'
        local -a octets=($ip)
        for octet in "${octets[@]}"; do
            if ((octet > 255)); then
                log_error "Invalid IP address: $ip (octet $octet > 255)"
                return 1
            fi
        done
        return 0
    else
        log_error "Invalid IP address format: $ip"
        return 1
    fi
}

validate_ssh_key() {
    local key_path=$1
    if [[ -f $key_path ]]; then
        if [[ ! -r $key_path ]]; then
            log_error "SSH key is not readable: $key_path"
            return 1
        fi
        return 0
    else
        log_error "SSH key file does not exist: $key_path"
        return 1
    fi
}

validate_port() {
    local port=$1
    if [[ $port =~ ^[0-9]+$ ]] && ((port >= 1 && port <= 65535)); then
        return 0
    else
        log_error "Invalid port number: $port (must be 1-65535)"
        return 1
    fi
}

################################################################################
# INPUT COLLECTION
################################################################################

collect_parameters() {
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "Collecting deployment parameters..."
    log_info "═══════════════════════════════════════════════════════════════"

    # Git Repository URL
    while [[ -z $GIT_REPO ]]; do
        read -p "Enter Git Repository URL (HTTPS or SSH): " GIT_REPO
        if ! validate_git_url "$GIT_REPO"; then
            GIT_REPO=""
            echo "Please enter a valid Git URL (must end with .git)"
        fi
    done
    log_success "Git Repository: $GIT_REPO"

    # Personal Access Token
    while [[ -z $GIT_PAT ]]; do
        read -sp "Enter Personal Access Token (PAT): " GIT_PAT
        echo ""
        [[ -z $GIT_PAT ]] && echo "PAT cannot be empty"
    done
    log_success "Personal Access Token: [HIDDEN]"

    # Git Branch (optional, defaults to main)
    read -p "Enter Git Branch (default: main): " GIT_BRANCH
    GIT_BRANCH=${GIT_BRANCH:-main}
    log_success "Git Branch: $GIT_BRANCH"

    # Remote Server - Username
    while [[ -z $REMOTE_USER ]]; do
        read -p "Enter Remote Server Username: " REMOTE_USER
        [[ -z $REMOTE_USER ]] && echo "Username cannot be empty"
    done
    log_success "Remote User: $REMOTE_USER"

    # Remote Server - IP Address
    while [[ -z $REMOTE_IP ]]; do
        read -p "Enter Remote Server IP Address: " REMOTE_IP
        if ! validate_ip_address "$REMOTE_IP"; then
            REMOTE_IP=""
            echo "Please enter a valid IP address"
        fi
    done
    log_success "Remote Server IP: $REMOTE_IP"

    # SSH Key Path
    while [[ -z $SSH_KEY ]]; do
        read -p "Enter SSH Key Path (default: ~/.ssh/id_rsa): " SSH_KEY
        SSH_KEY=${SSH_KEY:-~/.ssh/id_rsa}
        SSH_KEY="${SSH_KEY/#~/$HOME}"  # Expand tilde
        if ! validate_ssh_key "$SSH_KEY"; then
            SSH_KEY=""
            echo "Please enter a valid SSH key path"
        fi
    done
    log_success "SSH Key: $SSH_KEY"

    # Application Port
    while [[ -z $APP_PORT ]]; do
        read -p "Enter Application Port (internal container port): " APP_PORT
        if ! validate_port "$APP_PORT"; then
            APP_PORT=""
            echo "Please enter a valid port (1-65535)"
        fi
    done
    log_success "Application Port: $APP_PORT"

    log_info "All parameters collected successfully"
}

################################################################################
# GIT OPERATIONS
################################################################################

clone_or_update_repository() {
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "Stage 2: Clone/Update Repository"
    log_info "═══════════════════════════════════════════════════════════════"

    # Extract repository name from URL
    LOCAL_REPO_NAME=$(basename "$GIT_REPO" .git)

    # Handle HTTPS URL with PAT
    if [[ $GIT_REPO =~ ^https:// ]]; then
        # Extract domain and path from HTTPS URL
        local url_without_https=${GIT_REPO#https://}
        GIT_REPO_WITH_PAT="https://${GIT_PAT}@${url_without_https}"
    else
        # For SSH, use as-is (SSH key should be used)
        GIT_REPO_WITH_PAT="$GIT_REPO"
    fi

    if [[ -d $LOCAL_REPO_NAME ]]; then
        log_info "Repository directory already exists: $LOCAL_REPO_NAME"
        log_info "Pulling latest changes..."
        cd "$LOCAL_REPO_NAME"
        git fetch origin
        git checkout "$GIT_BRANCH"
        git pull origin "$GIT_BRANCH"
        cd - > /dev/null
        log_success "Repository updated successfully"
    else
        log_info "Cloning repository: $GIT_REPO_WITH_PAT"
        git clone -b "$GIT_BRANCH" "$GIT_REPO_WITH_PAT" "$LOCAL_REPO_NAME" 2>&1 | tee -a "$LOG_FILE"
        log_success "Repository cloned successfully"
    fi
}

################################################################################
# VERIFY LOCAL DIRECTORY
################################################################################

verify_local_directory() {
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "Stage 3: Verify Local Directory"
    log_info "═══════════════════════════════════════════════════════════════"

    if [[ ! -d $LOCAL_REPO_NAME ]]; then
        log_error "Repository directory not found: $LOCAL_REPO_NAME"
        exit 1
    fi

    cd "$LOCAL_REPO_NAME"
    log_info "Changed to directory: $(pwd)"

    if [[ ! -f Dockerfile ]] && [[ ! -f docker-compose.yml ]]; then
        log_error "Neither Dockerfile nor docker-compose.yml found in $(pwd)"
        log_error "This directory does not appear to be a Docker project"
        cd - > /dev/null
        exit 1
    fi

    if [[ -f Dockerfile ]]; then
        log_success "Found Dockerfile"
    fi

    if [[ -f docker-compose.yml ]]; then
        log_success "Found docker-compose.yml"
    fi

    cd - > /dev/null
    log_success "Local directory verification passed"
}

################################################################################
# SSH CONNECTIVITY CHECK
################################################################################

check_ssh_connectivity() {
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "Stage 4: SSH Connectivity Check"
    log_info "═══════════════════════════════════════════════════════════════"

    local ssh_options="-o StrictHostKeyChecking=no -o ConnectTimeout=10 -i $SSH_KEY"

    log_info "Testing SSH connection to $REMOTE_USER@$REMOTE_IP..."

    if ssh $ssh_options "$REMOTE_USER@$REMOTE_IP" "echo 'SSH connection successful'" 2>&1 | tee -a "$LOG_FILE"; then
        log_success "SSH connectivity verified"
    else
        log_error "Failed to establish SSH connection"
        exit 1
    fi
}

################################################################################
# REMOTE ENVIRONMENT PREPARATION
################################################################################

prepare_remote_environment() {
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "Stage 5: Prepare Remote Environment"
    log_info "═══════════════════════════════════════════════════════════════"

    local ssh_options="-o StrictHostKeyChecking=no -i $SSH_KEY"
    local ssh_cmd="ssh $ssh_options $REMOTE_USER@$REMOTE_IP"

    log_info "Updating system packages..."
    $ssh_cmd "sudo apt-get update" 2>&1 | tee -a "$LOG_FILE"

    log_info "Installing Docker..."
    $ssh_cmd "
        if ! command -v docker &> /dev/null; then
            sudo apt-get install -y docker.io
            log_success 'Docker installed'
        else
            echo 'Docker already installed'
        fi
    " 2>&1 | tee -a "$LOG_FILE"

    log_info "Installing Docker Compose..."
    $ssh_cmd "
        if ! command -v docker-compose &> /dev/null; then
            sudo curl -L 'https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-\$(uname -s)-\$(uname -m)' -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
        else
            echo 'Docker Compose already installed'
        fi
    " 2>&1 | tee -a "$LOG_FILE"

    log_info "Installing Nginx..."
    $ssh_cmd "
        if ! command -v nginx &> /dev/null; then
            sudo apt-get install -y nginx
        else
            echo 'Nginx already installed'
        fi
    " 2>&1 | tee -a "$LOG_FILE"

    log_info "Adding user to Docker group..."
    $ssh_cmd "
        if ! groups $REMOTE_USER | grep -q docker; then
            sudo usermod -aG docker $REMOTE_USER
        else
            echo 'User already in docker group'
        fi
    " 2>&1 | tee -a "$LOG_FILE"

    log_info "Enabling and starting Docker service..."
    $ssh_cmd "
        sudo systemctl enable docker
        sudo systemctl start docker
    " 2>&1 | tee -a "$LOG_FILE"

    log_info "Enabling and starting Nginx service..."
    $ssh_cmd "
        sudo systemctl enable nginx
        sudo systemctl start nginx
    " 2>&1 | tee -a "$LOG_FILE"

    log_info "Verifying installations..."
    $ssh_cmd "
        echo '=== Docker Version ==='
        docker --version
        echo '=== Docker Compose Version ==='
        docker-compose --version
        echo '=== Nginx Version ==='
        nginx -v
    " 2>&1 | tee -a "$LOG_FILE"

    log_success "Remote environment preparation completed"
}

################################################################################
# DEPLOY APPLICATION
################################################################################

deploy_application() {
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "Stage 6: Deploy Dockerized Application"
    log_info "═══════════════════════════════════════════════════════════════"

    local ssh_options="-o StrictHostKeyChecking=no -i $SSH_KEY"
    local ssh_cmd="ssh $ssh_options $REMOTE_USER@$REMOTE_IP"
    local scp_cmd="scp -r -i $SSH_KEY -o StrictHostKeyChecking=no"
    local deploy_dir="/home/$REMOTE_USER/app_deployment"

    log_info "Creating deployment directory on remote server..."
    $ssh_cmd "mkdir -p $deploy_dir" 2>&1 | tee -a "$LOG_FILE"

    log_info "Transferring project files to remote server..."
    $scp_cmd "$LOCAL_REPO_NAME/" "$REMOTE_USER@$REMOTE_IP:$deploy_dir/$LOCAL_REPO_NAME/" 2>&1 | tee -a "$LOG_FILE"
    log_success "Files transferred successfully"

    log_info "Building and running Docker containers..."
    $ssh_cmd "
        cd $deploy_dir/$LOCAL_REPO_NAME
        
        # Stop and remove old containers if they exist
        if docker ps -a --format '{{.Names}}' | grep -q '^${LOCAL_REPO_NAME}'; then
            echo 'Stopping existing container...'
            docker stop ${LOCAL_REPO_NAME} || true
            docker rm ${LOCAL_REPO_NAME} || true
        fi

        # Check if using docker-compose
        if [[ -f docker-compose.yml ]]; then
            echo 'Using docker-compose for deployment...'
            docker-compose down || true
            docker-compose up -d
        else
            echo 'Using Dockerfile for deployment...'
            docker build -t ${LOCAL_REPO_NAME}:latest .
            docker run -d \
                --name ${LOCAL_REPO_NAME} \
                -p 127.0.0.1:${APP_PORT}:${APP_PORT} \
                ${LOCAL_REPO_NAME}:latest
        fi
    " 2>&1 | tee -a "$LOG_FILE"

    log_success "Application deployment completed"
}

################################################################################
# VALIDATE CONTAINER HEALTH
################################################################################

validate_container_health() {
    log_info "Validating container health..."

    local ssh_options="-o StrictHostKeyChecking=no -i $SSH_KEY"
    local ssh_cmd="ssh $ssh_options $REMOTE_USER@$REMOTE_IP"

    log_info "Checking container status..."
    $ssh_cmd "
        if docker ps --format '{{.Names}}' | grep -q '^${LOCAL_REPO_NAME}'; then
            echo 'Container is running'
            docker ps --filter name=${LOCAL_REPO_NAME}
            docker logs --tail 20 ${LOCAL_REPO_NAME}
        else
            echo 'Container is not running'
            exit 1
        fi
    " 2>&1 | tee -a "$LOG_FILE"

    log_success "Container health validation passed"
}

################################################################################
# CONFIGURE NGINX REVERSE PROXY
################################################################################

configure_nginx() {
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "Stage 7: Configure Nginx Reverse Proxy"
    log_info "═══════════════════════════════════════════════════════════════"

    local ssh_options="-o StrictHostKeyChecking=no -i $SSH_KEY"
    local ssh_cmd="ssh $ssh_options $REMOTE_USER@$REMOTE_IP"

    # Generate Nginx configuration
    local nginx_config="
server {
    listen 80;
    server_name _;

    client_max_body_size 100M;

    location / {
        proxy_pass http://127.0.0.1:${APP_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check endpoint (optional)
    location /health {
        access_log off;
        return 200 \"healthy\n\";
        add_header Content-Type text/plain;
    }
}
"

    log_info "Creating Nginx configuration..."
    $ssh_cmd "
        sudo bash -c 'cat > /etc/nginx/sites-available/${LOCAL_REPO_NAME} << 'EOF'
${nginx_config}
EOF'
    " 2>&1 | tee -a "$LOG_FILE"

    log_info "Enabling Nginx site..."
    $ssh_cmd "
        if [[ ! -L /etc/nginx/sites-enabled/${LOCAL_REPO_NAME} ]]; then
            sudo ln -s /etc/nginx/sites-available/${LOCAL_REPO_NAME} /etc/nginx/sites-enabled/
        fi
    " 2>&1 | tee -a "$LOG_FILE"

    log_info "Testing Nginx configuration..."
    $ssh_cmd "sudo nginx -t" 2>&1 | tee -a "$LOG_FILE"

    log_info "Reloading Nginx..."
    $ssh_cmd "sudo systemctl reload nginx" 2>&1 | tee -a "$LOG_FILE"

    log_success "Nginx reverse proxy configured successfully"
}

################################################################################
# FINAL VALIDATION
################################################################################

validate_deployment() {
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "Stage 8: Final Validation"
    log_info "═══════════════════════════════════════════════════════════════"

    local ssh_options="-o StrictHostKeyChecking=no -i $SSH_KEY"
    local ssh_cmd="ssh $ssh_options $REMOTE_USER@$REMOTE_IP"

    log_info "Verifying Docker service..."
    $ssh_cmd "sudo systemctl is-active docker" 2>&1 | tee -a "$LOG_FILE"
    log_success "Docker service is running"

    log_info "Verifying container is active..."
    $ssh_cmd "
        if docker ps --format '{{.Names}}' | grep -q '^${LOCAL_REPO_NAME}'; then
            echo 'Container is active'
        else
            echo 'Container is not active'
            exit 1
        fi
    " 2>&1 | tee -a "$LOG_FILE"
    log_success "Container is active"

    log_info "Verifying Nginx is running..."
    $ssh_cmd "sudo systemctl is-active nginx" 2>&1 | tee -a "$LOG_FILE"
    log_success "Nginx is running"

    log_info "Testing application endpoint locally on remote server..."
    $ssh_cmd "
        sleep 5  # Wait for container to be fully ready
        curl -s -o /dev/null -w 'HTTP Status: %{http_code}\n' http://127.0.0.1:${APP_PORT} || echo 'Direct port test failed'
        curl -s -o /dev/null -w 'HTTP Status: %{http_code}\n' http://127.0.0.1/ || echo 'Nginx proxy test failed'
    " 2>&1 | tee -a "$LOG_FILE"

    log_success "Application endpoint is accessible"

    log_info "Deployment Summary:"
    log_info "  - Remote Server: $REMOTE_USER@$REMOTE_IP"
    log_info "  - Application: $LOCAL_REPO_NAME"
    log_info "  - Internal Port: $APP_PORT"
    log_info "  - Nginx Port: 80"
    log_info "  - Access: http://$REMOTE_IP"

    log_success "Final validation completed successfully"
}

################################################################################
# CLEANUP FUNCTION
################################################################################

cleanup_deployment() {
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "Cleanup: Removing Deployed Resources"
    log_info "═══════════════════════════════════════════════════════════════"

    local ssh_options="-o StrictHostKeyChecking=no -i $SSH_KEY"
    local ssh_cmd="ssh $ssh_options $REMOTE_USER@$REMOTE_IP"

    read -p "Are you sure you want to remove all deployed resources? (yes/no): " confirm
    if [[ $confirm != "yes" ]]; then
        log_info "Cleanup cancelled"
        return
    fi

    log_info "Removing Docker containers and images..."
    $ssh_cmd "
        docker stop ${LOCAL_REPO_NAME} || true
        docker rm ${LOCAL_REPO_NAME} || true
        docker rmi ${LOCAL_REPO_NAME}:latest || true
    " 2>&1 | tee -a "$LOG_FILE"

    log_info "Removing Nginx configuration..."
    $ssh_cmd "
        sudo rm -f /etc/nginx/sites-enabled/${LOCAL_REPO_NAME}
        sudo rm -f /etc/nginx/sites-available/${LOCAL_REPO_NAME}
        sudo systemctl reload nginx
    " 2>&1 | tee -a "$LOG_FILE"

    log_info "Removing deployment directory..."
    $ssh_cmd "rm -rf /home/$REMOTE_USER/app_deployment" 2>&1 | tee -a "$LOG_FILE"

    log_success "Cleanup completed"
}

################################################################################
# MAIN EXECUTION
################################################################################

main() {
    init_logging

    log_info "Parsing command-line arguments..."
    while [[ $# -gt 0 ]]; do
        case $1 in
            --cleanup)
                CLEANUP_FLAG=true
                shift
                ;;
            --debug)
                DEBUG_MODE=true
                set -x
                shift
                ;;
            *)
                log_error "Unknown argument: $1"
                print_usage
                exit 1
                ;;
        esac
    done

    log_info "═══════════════════════════════════════════════════════════════"
    log_info "AUTOMATED DEPLOYMENT SCRIPT"
    log_info "═══════════════════════════════════════════════════════════════"

    # Stage 1: Collect Parameters
    log_info "Stage 1: Collecting Parameters"
    collect_parameters

    # Stage 2: Clone/Update Repository
    clone_or_update_repository

    # Stage 3: Verify Local Directory
    verify_local_directory

    # Stage 4: SSH Connectivity Check
    check_ssh_connectivity

    # Stage 5: Prepare Remote Environment
    prepare_remote_environment

    # Stage 6: Deploy Application
    deploy_application

    # Validate Container Health
    validate_container_health

    # Stage 7: Configure Nginx
    configure_nginx

    # Stage 8: Final Validation
    validate_deployment

    log_info "═══════════════════════════════════════════════════════════════"
    log_success "🎉 DEPLOYMENT COMPLETED SUCCESSFULLY 🎉"
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "Log file saved to: $LOG_FILE"
}

print_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
    --cleanup       Remove all deployed resources from remote server
    --debug         Enable debug mode (set -x)
    -h, --help      Show this help message

DESCRIPTION:
    This script automates the deployment of Dockerized applications
    to remote Linux servers with full automation of setup, deployment,
    and configuration.

INTERACTIVE PROMPTS:
    1. Git Repository URL (HTTPS with PAT or SSH)
    2. Personal Access Token (for HTTPS repos)
    3. Git Branch (optional, defaults to main)
    4. Remote Server Username
    5. Remote Server IP Address
    6. SSH Key Path
    7. Application Port

REQUIREMENTS:
    - Bash 4.0+
    - Git
    - SSH access to remote server
    - Docker repository with Dockerfile or docker-compose.yml

EXAMPLE:
    # Normal deployment
    ./deploy.sh

    # Cleanup previous deployment
    ./deploy.sh --cleanup

    # Debug mode
    ./deploy.sh --debug

EOF
}

# Check if help flag is provided
if [[ $# -gt 0 ]] && [[ $1 == "-h" || $1 == "--help" ]]; then
    print_usage
    exit 0
fi

# Run main function
main "$@"
