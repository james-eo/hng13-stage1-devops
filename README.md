# Automated Deployment Bash Script

**HNG DevOps Internship - Stage 1 Task**

A production-grade Bash script that automates the setup, deployment, and configuration of Dockerized applications on remote Linux servers.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [How It Works](#how-it-works)
- [Deployment Steps](#deployment-steps)
- [Troubleshooting](#troubleshooting)
- [Submission Instructions](#submission-instructions)

---

## Overview

This script (`deploy.sh`) is designed to completely automate the deployment workflow for Dockerized applications. It handles:

1. **Git Repository Management** - Clone/update repositories with authentication
2. **Remote Server Setup** - Install Docker, Docker Compose, and Nginx
3. **Application Deployment** - Build and run Docker containers
4. **Nginx Configuration** - Set up reverse proxy automatically
5. **Comprehensive Logging** - All actions logged with timestamps
6. **Error Handling** - Graceful error management with meaningful messages
7. **Idempotency** - Safe to re-run without breaking existing setups
8. **Validation** - Verification at every stage

---

## Features

✅ **Parameter Validation**

- Git URL validation
- IP address validation
- SSH key verification
- Port range validation
- Interactive input with error feedback

✅ **Git Operations**

- Supports HTTPS (with PAT) and SSH authentication
- Clone new repositories or pull latest changes
- Automatic branch switching

✅ **Remote Environment Setup**

- Automatic Docker installation
- Docker Compose installation
- Nginx installation
- Docker group configuration
- Service enablement and startup

✅ **Application Deployment**

- Support for both Dockerfile and docker-compose.yml
- SCP file transfer to remote server
- Automatic container cleanup before redeployment
- Health validation

✅ **Nginx Reverse Proxy**

- Dynamic configuration generation
- HTTP to container port proxying
- Health check endpoint
- Automatic configuration reload

✅ **Logging & Monitoring**

- Timestamped log files in `logs/` directory
- Color-coded console output
- Full deployment audit trail
- Per-stage logging

✅ **Error Handling**

- Trap functions for cleanup
- Meaningful exit codes
- Error recovery options
- Graceful failure messages

✅ **Idempotent Operations**

- Checks for existing installations before installing
- Stops/removes old containers before redeployment
- Prevents duplicate configurations
- Safe to run multiple times

---

## Requirements

### System Requirements

- **Local Machine:**

  - Bash 4.0 or higher
  - Git
  - SSH client
  - SCP/rsync

- **Remote Server:**
  - Ubuntu/Debian-based Linux
  - SSH access enabled
  - Sudo privileges
  - Internet connection for package installation

### Prerequisites

1. **Git Repository:**

   - Must contain `Dockerfile` or `docker-compose.yml`
   - Hosted on GitHub/GitLab/Bitbucket

2. **GitHub Personal Access Token (PAT):**

   - If using HTTPS clone
   - Create at: https://github.com/settings/tokens
   - Scopes needed: `repo` (full control of private repositories)

3. **SSH Key:**

   - Stored locally (typically `~/.ssh/id_rsa`)
   - Public key added to remote server's `~/.ssh/authorized_keys`

4. **Remote Server Access:**
   - SSH connectivity with provided credentials
   - Sudo access for package installation

---

## Installation

### 1. Clone/Download the Script

```bash
# Clone the repository containing the script
git clone <your-repo-url>
cd stage1
```

### 2. Make Script Executable

```bash
chmod +x deploy.sh
```

### 3. Verify Installation

```bash
./deploy.sh --help
```

You should see the usage information displayed.

---

## Usage

### Basic Deployment

```bash
./deploy.sh
```

The script will then prompt you for:

1. **Git Repository URL** - Full HTTPS or SSH URL (must end with `.git`)

   ```
   Example: https://github.com/username/project.git
   Example: git@github.com:username/project.git
   ```

2. **Personal Access Token (PAT)** - For HTTPS authentication

   ```
   Will be hidden as you type
   ```

3. **Git Branch** - Branch to deploy (default: `main`)

   ```
   Press Enter to use default 'main'
   ```

4. **Remote Server Username** - SSH username

   ```
   Example: ubuntu, ec2-user, root
   ```

5. **Remote Server IP Address** - Server's public IP

   ```
   Example: 192.168.1.100
   ```

6. **SSH Key Path** - Local path to SSH private key

   ```
   Default: ~/.ssh/id_rsa
   ```

7. **Application Port** - Internal container port
   ```
   Example: 3000, 8080, 5000
   ```

### Advanced Options

```bash
# Show help
./deploy.sh --help

# Enable debug mode (prints all commands executed)
./deploy.sh --debug

# Cleanup previous deployment (removes containers, configs, files)
./deploy.sh --cleanup
```

---

## How It Works

### Execution Flow

```
┌─────────────────────────────────────────────────────────┐
│ Stage 1: Input Collection & Validation                  │
│ - Collect all parameters from user                      │
│ - Validate formats (URLs, IPs, ports, etc.)            │
└─────────────────┬───────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────┐
│ Stage 2: Git Operations                                  │
│ - Clone repo with PAT or pull latest changes           │
│ - Switch to specified branch                           │
└─────────────────┬───────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────┐
│ Stage 3: Local Verification                             │
│ - Verify Dockerfile or docker-compose.yml exists       │
│ - Check project structure                              │
└─────────────────┬───────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────┐
│ Stage 4: SSH Connectivity Check                         │
│ - Verify connection to remote server                    │
│ - Test SSH key and credentials                         │
└─────────────────┬───────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────┐
│ Stage 5: Remote Environment Setup                       │
│ - Install Docker, Docker Compose, Nginx               │
│ - Configure Docker permissions                         │
│ - Start services                                       │
└─────────────────┬───────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────┐
│ Stage 6: Application Deployment                         │
│ - Transfer files to remote server                      │
│ - Stop old containers if exist                         │
│ - Build and run Docker containers                      │
└─────────────────┬───────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────┐
│ Stage 7: Nginx Configuration                            │
│ - Generate dynamic Nginx config                        │
│ - Set up reverse proxy                                 │
│ - Test and reload Nginx                               │
└─────────────────┬───────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────┐
│ Stage 8: Final Validation                              │
│ - Verify all services running                          │
│ - Test endpoint connectivity                           │
│ - Log deployment summary                              │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
         ✅ Deployment Complete
```

### Key Operations

**Local Operations:**

- Parameter collection and validation
- Git clone/pull with PAT authentication
- Dockerfile/docker-compose.yml verification

**Remote Operations:**

- SSH connection establishment
- Package installation (Docker, Docker Compose, Nginx)
- File transfer via SCP
- Container build and execution
- Nginx configuration and reload
- Health checks and validation

**Error Handling:**

- Each stage validates completion
- Trap functions catch unexpected errors
- Logs capture all output
- Graceful exit on failures

---

## Deployment Steps

### Step-by-Step Guide

#### 1. **Prepare Your Docker Project**

Ensure your project has either:

- `Dockerfile` (for single container)
- `docker-compose.yml` (for multi-container orchestration)

Example minimal Dockerfile:

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY . .
RUN npm install
EXPOSE 3000
CMD ["npm", "start"]
```

#### 2. **Set Up Remote Server**

```bash
# SSH into your remote server
ssh username@server_ip

# Create SSH key if not exists
ssh-keygen -t rsa -b 4096

# View public key to add to GitHub/GitLab
cat ~/.ssh/id_rsa.pub
```

#### 3. **Generate GitHub Personal Access Token**

- Go to https://github.com/settings/tokens
- Click "Generate new token"
- Select scopes: `repo` (full control of private repositories)
- Copy the token (you'll only see it once)

#### 4. **Run the Deployment Script**

```bash
# Navigate to script directory
cd /home/freeman/HNG/devops/stage1

# Run the script
./deploy.sh

# Follow the interactive prompts
```

#### 5. **Verify Deployment**

```bash
# SSH into remote server
ssh username@server_ip

# Check Docker containers
docker ps

# Check Nginx status
sudo systemctl status nginx

# View application logs
docker logs <container_name>

# Test the application
curl http://127.0.0.1:80
# or
curl http://your_server_ip
```

#### 6. **Monitor Logs**

```bash
# Local logs
cat logs/deploy_<YYYYMMDD_HHMMSS>.log

# Remote Docker logs
ssh username@server_ip "docker logs -f <container_name>"

# Remote Nginx logs
ssh username@server_ip "sudo tail -f /var/log/nginx/error.log"
```

---

## Troubleshooting

### Common Issues and Solutions

#### 1. **SSH Connection Failed**

**Error:**

```
ERROR: Failed to establish SSH connection
```

**Solutions:**

- Verify IP address is correct: `ping <server_ip>`
- Check SSH key permissions: `chmod 600 ~/.ssh/id_rsa`
- Verify public key on remote: `ssh-keygen -y -f ~/.ssh/id_rsa > /tmp/key.pub`
- Copy to remote: `ssh-copy-id -i ~/.ssh/id_rsa username@server_ip`
- Test directly: `ssh -i ~/.ssh/id_rsa username@server_ip`

#### 2. **Git Clone Failed - Authentication Error**

**Error:**

```
fatal: Authentication failed for 'https://...'
```

**Solutions:**

- Verify PAT is correct and not expired
- Check PAT has `repo` scope
- Ensure Git URL ends with `.git`
- For SSH: Verify GitHub SSH key is added

#### 3. **Dockerfile/docker-compose.yml Not Found**

**Error:**

```
ERROR: Neither Dockerfile nor docker-compose.yml found
```

**Solutions:**

- Verify files exist in repository root
- Check branch is correct
- Pull latest changes manually:
  ```bash
  cd <repo_name>
  git pull origin main
  ```

#### 4. **Docker Build Fails**

**Symptoms:**

- Container won't start
- Application port not responding

**Solutions:**

```bash
# SSH into remote server
ssh username@server_ip

# Check Docker logs
docker logs <container_name>

# Rebuild without cache
docker build --no-cache -t <app_name> .

# Check port binding
docker port <container_name>

# Test container directly
docker run -it <app_name> sh
```

#### 5. **Nginx Reverse Proxy Not Working**

**Error:**

```
502 Bad Gateway
```

**Solutions:**

```bash
# SSH into remote server
ssh username@server_ip

# Check Nginx status
sudo systemctl status nginx

# Test Nginx config
sudo nginx -t

# Check Nginx error log
sudo tail -20 /var/log/nginx/error.log

# Verify application is running on port
netstat -tlnp | grep <port>

# Test connection to app
curl http://127.0.0.1:<app_port>
```

#### 6. **Permission Denied on Docker Commands**

**Error:**

```
permission denied while trying to connect to Docker daemon
```

**Solutions:**

```bash
# SSH into remote server and restart session
ssh username@server_ip

# Apply Docker group changes
newgrp docker

# Or logout and login again
exit
```

#### 7. **Port Already in Use**

**Error:**

```
bind: address already in use
```

**Solutions:**

```bash
# Check what's using the port
sudo lsof -i :<port_number>

# Kill the process
sudo kill -9 <PID>

# Or use different port and re-run script
```

### Debug Mode

For detailed troubleshooting, run with debug enabled:

```bash
./deploy.sh --debug
```

This will print every command being executed, making it easier to identify failures.

### Log Files

All operations are logged to `logs/deploy_YYYYMMDD_HHMMSS.log`

```bash
# View current log
tail -f logs/deploy_*.log

# Search for errors
grep ERROR logs/deploy_*.log

# Full log history
ls -la logs/
```

---

## Script Features Breakdown

### 1. **Comprehensive Input Validation**

```bash
# Validates:
- Git URLs (HTTPS or SSH format)
- IP addresses (proper octets 0-255)
- Port numbers (1-65535)
- SSH key existence and readability
- Branch name format
```

### 2. **Secure Authentication**

```bash
# Handles:
- Hidden PAT input (no echo to terminal)
- SSH key-based authentication
- No hardcoded credentials
- Secure parameter passing to remote commands
```

### 3. **Idempotent Deployment**

```bash
# Ensures:
- Existing installations aren't duplicated
- Old containers are cleaned before redeployment
- Nginx configs are unique per app
- Services start cleanly
```

### 4. **Comprehensive Logging**

```bash
# Logs include:
- Timestamps for all operations
- Success/failure indicators
- Full command output
- Error messages with context
- Deployment summary
```

### 5. **Error Recovery**

```bash
# Features:
- Trap function for unexpected errors
- Graceful exit with meaningful codes
- Operation-specific error messages
- Cleanup on script termination
```

### 6. **Production Readiness**

```bash
# Includes:
- Color-coded output
- Progress indicators
- Health checks
- Service verification
- Endpoint testing
```

---

## File Structure

```
stage1/
├── deploy.sh                    # Main deployment script
├── README.md                    # This file
├── logs/                        # Created automatically
│   └── deploy_YYYYMMDD_HHMMSS.log  # Deployment logs
└── <cloned_repo>/               # Cloned application (created on run)
    ├── Dockerfile
    ├── docker-compose.yml
    └── ...
```

---

## Performance Considerations

- **First Run:** 5-15 minutes (package installation + Docker build)
- **Subsequent Runs:** 1-3 minutes (updates only + quicker build)
- **Transfer Speed:** Depends on project size and network connection
- **Docker Build:** Varies by Dockerfile complexity

---

## Security Considerations

⚠️ **Important Security Notes:**

1. **SSH Keys:**

   - Keep private keys secure (permissions: 600)
   - Never share or commit keys to Git
   - Use separate keys per server if possible

2. **Personal Access Token (PAT):**

   - Never commit to Git
   - Regenerate periodically
   - Use minimal required scopes
   - Can be revoked anytime

3. **Remote Server:**

   - Keep sudo access secure
   - Use firewall rules
   - Only expose necessary ports
   - Monitor server logs

4. **Script Usage:**
   - Review script contents before running
   - Use in trusted environments
   - Check logs for suspicious activity
   - Implement additional security layers as needed

---

## Submission Instructions

### Prerequisites Before Submission

1. ✅ Test the script locally
2. ✅ Successfully deploy to a test server
3. ✅ Verify all stages complete without errors
4. ✅ Confirm application is accessible
5. ✅ Check logs for any warnings

### Step-by-Step Submission

#### 1. **Prepare Your GitHub Repository**

Create a GitHub repository for this project:

```bash
# Navigate to your workspace
cd /home/freeman/HNG/devops/stage1

# Initialize git repo
git init

# Add files
git add deploy.sh README.md

# Commit
git commit -m "HNG DevOps Stage 1: Automated Deployment Script"

# Add remote (replace with your repo URL)
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git

# Create main branch and push
git branch -M main
git push -u origin main
```

#### 2. **Verify Repository Contents**

Your GitHub repo should contain:

```
your-repo/
├── deploy.sh          # Executable bash script
├── README.md          # Documentation
└── .gitignore         # Optional: exclude sensitive files
```

Sample `.gitignore`:

```
logs/
*.log
.env
.env.local
```

#### 3. **Test Before Submission**

```bash
# Clone your repo in a fresh directory
mkdir test_deployment
cd test_deployment
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
cd YOUR_REPO
chmod +x deploy.sh

# Run a test deployment
./deploy.sh
```

#### 4. **Submit via Slack**

**When you're ready to submit:**

1. Open Slack and go to **#track-devops** or **#stage-1-devops** channel
2. Use the `/stage-one-devops` slash command
3. Fill in the form with:
   - **Full Name:** Your full name
   - **GitHub Repository URL:** `https://github.com/YOUR_USERNAME/YOUR_REPO`

#### 5. **Verify Submission**

After submission:

1. Check Slack for **Thanos bot** response
2. Look for success or error message
3. If error, fix the issue and resubmit
4. Track your attempts (max 5 allowed)

---

## Important Notes

### ⏰ Deadline

- **Deadline:** 11:59 PM GMT, 22nd October 2025
- **Attempts:** 5 maximum
- **Late Submissions:** ❌ Not accepted

### 📋 Requirements Checklist

- [ ] Script is POSIX-compliant
- [ ] Script is executable (`chmod +x deploy.sh`)
- [ ] README.md explains usage
- [ ] Script handles all 10 task requirements
- [ ] Comprehensive error handling implemented
- [ ] Logging to timestamped files
- [ ] Idempotent operations
- [ ] Cleanup flag available
- [ ] No configuration management tools used
- [ ] Tested and verified working

### 🚀 Success Indicators

After successful deployment, you should see:

```
✅ Repository cloned/updated
✅ Local directory verified
✅ SSH connection established
✅ Remote environment prepared
✅ Docker containers running
✅ Nginx reverse proxy configured
✅ Application accessible on port 80
✅ All services healthy
✅ Deployment logs created
🎉 DEPLOYMENT COMPLETED SUCCESSFULLY
```

---

## Support & Resources

- **Task Video:** https://vt.tiktok.com/ZSUgAWyVj/
- **GitHub Docs:** https://docs.github.com
- **Docker Docs:** https://docs.docker.com
- **Nginx Docs:** https://nginx.org/en/docs/
- **Bash Guide:** https://www.gnu.org/software/bash/manual/

---

## License

This script is provided for HNG DevOps internship purposes.

---

## Version History

- **v1.0** - Initial release with complete Stage 1 requirements

---

**Last Updated:** October 22, 2025

**Good luck with your deployment! 🚀**
