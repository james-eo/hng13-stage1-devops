# DEPLOYMENT & SUBMISSION GUIDE

**HNG DevOps Stage 1 - Quick Start**

---

## 🎯 Quick Summary

This guide provides step-by-step instructions for:

1. Setting up your GitHub repository
2. Preparing your Docker project
3. Running the deployment script
4. Submitting to HNG

---

## Part 1: GitHub Repository Setup

### Step 1.1: Create a New Repository on GitHub

1. Go to https://github.com/new
2. **Repository name:** `hng-devops-stage1` (or any name you prefer)
3. **Description:** "Automated Docker deployment script for HNG DevOps internship"
4. Select **Public** (HNG will need to access it)
5. Initialize with README (optional, we'll overwrite it)
6. Click **Create repository**

### Step 1.2: Get Your Repository URL

After creating the repo, you'll see a screen like this:

```
HTTPS:  https://github.com/YOUR_USERNAME/hng-devops-stage1.git
SSH:    git@github.com:YOUR_USERNAME/hng-devops-stage1.git
```

**Copy the HTTPS URL** - you'll need it in the next step.

---

## Part 2: Prepare Your Local Repository

### Step 2.1: Initialize Git in Your Project

```bash
# Navigate to the project directory
cd /home/freeman/HNG/devops/stage1

# Initialize git repository
git init

# Configure git (use your GitHub username and email)
git config user.name "Your Name"
git config user.email "your.email@example.com"

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: HNG DevOps Stage 1 deployment script"

# Add remote repository (replace URL with yours)
git remote add origin https://github.com/YOUR_USERNAME/hng-devops-stage1.git

# Rename branch to main (GitHub default)
git branch -M main

# Push to GitHub
git push -u origin main
```

### Step 2.2: Verify on GitHub

1. Go to your repository URL: `https://github.com/YOUR_USERNAME/hng-devops-stage1`
2. Verify you see:
   - `deploy.sh`
   - `README.md`
   - `.gitignore`

✅ You should see all three files listed!

---

## Part 3: Test the Script (Recommended)

### Option A: Dry Run Without Deployment

Test the script's help and basic functionality:

```bash
cd /home/freeman/HNG/devops/stage1

# Show help
./deploy.sh --help

# This should display usage information
```

### Option B: Full Deployment Test (Recommended)

If you have a test server available:

```bash
./deploy.sh
```

Then provide test values:

- Git repo: A test Docker project
- PAT: Your GitHub token
- Branch: main
- Remote user: ubuntu (or your server user)
- Server IP: Your test server IP
- SSH key: Your SSH key path
- Port: 3000 (or your app port)

Monitor the output for any errors. All logs are saved to `logs/deploy_*.log`

---

## Part 4: Prepare for Submission

### Before You Submit - Checklist

- [ ] Script is executable (`chmod +x deploy.sh`)
- [ ] Files are pushed to GitHub
- [ ] README.md is readable on GitHub
- [ ] `.gitignore` prevents sensitive files from being committed
- [ ] Script has been reviewed for correctness
- [ ] All 10 requirements are implemented:
  - [ ] 1. User input collection and validation
  - [ ] 2. Git repository clone/pull with PAT
  - [ ] 3. Verify Dockerfile/docker-compose.yml
  - [ ] 4. SSH connection establishment
  - [ ] 5. Remote environment preparation (Docker, Compose, Nginx)
  - [ ] 6. Application deployment with containers
  - [ ] 7. Nginx reverse proxy configuration
  - [ ] 8. Deployment validation and health checks
  - [ ] 9. Comprehensive logging and error handling
  - [ ] 10. Idempotency and cleanup flag

### Verify Your GitHub Repository

```bash
# View your repo status
cd /home/freeman/HNG/devops/stage1
git status

# View commit history
git log --oneline

# View remote URL
git remote -v
```

Example output should show:

```
origin  https://github.com/YOUR_USERNAME/hng-devops-stage1.git (fetch)
origin  https://github.com/YOUR_USERNAME/hng-devops-stage1.git (push)
```

---

## Part 5: Submit via Slack

### 5.1: Prepare Your Information

Have ready:

- **Full Name:** Your complete name (as it should appear)
- **GitHub URL:** `https://github.com/YOUR_USERNAME/hng-devops-stage1`

### 5.2: Submit Using Slack Command

1. **Open Slack**
2. **Navigate to channel:** `#track-devops` or `#stage-1-devops` (check HNG Slack workspace)
3. **Type the command:**
   ```
   /stage-one-devops
   ```
4. **Fill in the form:**
   - Full Name: `Your Full Name`
   - GitHub Repository URL: `https://github.com/YOUR_USERNAME/hng-devops-stage1`
5. **Submit the form**

### 5.3: Track Your Submission

1. **Look for Thanos bot response** in Slack
2. **Check the message for:**
   - ✅ Success message (your deployment was accepted)
   - ❌ Error message (fix the issue and resubmit)

**Keep track of your attempts** (max 5 allowed)

---

## Part 6: If You Get an Error

### Common Submission Errors

**Error: "Repository not found"**

- ✅ Verify the GitHub URL is correct
- ✅ Make sure the repo is public
- ✅ Check that files are actually pushed to GitHub

**Error: "Missing files"**

- ✅ Ensure `deploy.sh` and `README.md` are in the repo root
- ✅ Run: `git push` to ensure latest changes are uploaded

**Error: "Script not executable"**

- ✅ Run: `chmod +x deploy.sh`
- ✅ Commit and push:
  ```bash
  git add deploy.sh
  git commit -m "Make script executable"
  git push
  ```

**Error: "Script validation failed"**

- ✅ Check bash syntax: `bash -n deploy.sh`
- ✅ Review README.md for completeness
- ✅ Test locally if possible

---

## Part 7: After Successful Submission

### If Accepted ✅

🎉 **Congratulations!**

Your deployment:

1. Was evaluated by the Thanos bot
2. Passed all validation checks
3. Qualifies for the next stage

**Next Steps:**

- Check HNG Slack for stage 2 details
- Review feedback from Thanos bot
- Prepare for next stage

### If Rejected ❌

**Don't worry!** You have up to 5 attempts.

1. **Check the error message** from Thanos bot
2. **Make corrections** based on the error
3. **Test locally** with the fixed script
4. **Commit and push** the changes:
   ```bash
   git add deploy.sh
   git commit -m "Fix: [description of fix]"
   git push
   ```
5. **Resubmit** using `/stage-one-devops` command

---

## Quick Reference: Common Commands

### Git Operations

```bash
# Check status
cd /home/freeman/HNG/devops/stage1
git status

# Add changes
git add deploy.sh README.md

# Commit
git commit -m "Your commit message"

# Push to GitHub
git push

# View log
git log --oneline
```

### Script Management

```bash
# Make executable
chmod +x deploy.sh

# Test syntax
bash -n deploy.sh

# Show help
./deploy.sh --help

# View logs
ls -la logs/
tail -f logs/deploy_*.log
```

### GitHub Operations

```bash
# Copy your repo URL
echo "https://github.com/YOUR_USERNAME/hng-devops-stage1"

# Verify repo access
curl -s https://api.github.com/repos/YOUR_USERNAME/hng-devops-stage1 | grep -o '"name":[^,]*'
```

---

## Troubleshooting Quick Guide

### Issue: "Permission denied" when running script

**Solution:**

```bash
chmod +x /home/freeman/HNG/devops/stage1/deploy.sh
```

### Issue: Git command not found

**Solution:**

```bash
# Install git
sudo apt-get install -y git

# Configure git
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

### Issue: SSH connection fails during deployment

**Solution:**

```bash
# Verify SSH key exists
ls -la ~/.ssh/id_rsa

# Generate new key if needed
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# Test SSH connection
ssh -i ~/.ssh/id_rsa username@server_ip
```

### Issue: Cannot push to GitHub

**Solution:**

```bash
# Check remote URL
git remote -v

# If wrong, update it
git remote set-url origin https://github.com/YOUR_USERNAME/hng-devops-stage1.git

# Retry push
git push -u origin main
```

---

## 📋 Final Checklist Before Submission

- [ ] All files in `/home/freeman/HNG/devops/stage1/`
- [ ] `deploy.sh` is executable (`chmod +x deploy.sh`)
- [ ] `README.md` is comprehensive and clear
- [ ] `.gitignore` is in place
- [ ] Git repository initialized and pushed
- [ ] GitHub repository is public
- [ ] Repository URL is in correct format: `https://github.com/USERNAME/REPO`
- [ ] All 10 task requirements implemented
- [ ] Script tested locally (if possible)
- [ ] Error handling and logging implemented
- [ ] Logs directory will be created at runtime
- [ ] Ready to submit via Slack

---

## 🎯 Success Criteria

Your submission will be evaluated on:

1. ✅ **Functionality** - Script performs all 10 required tasks
2. ✅ **Reliability** - Error handling and validation working
3. ✅ **Documentation** - Clear README with usage instructions
4. ✅ **Code Quality** - Clean, readable, POSIX-compliant bash
5. ✅ **Security** - No hardcoded credentials, proper handling of tokens
6. ✅ **Idempotency** - Safe to run multiple times
7. ✅ **Logging** - Comprehensive audit trail of all operations

---

## 📞 Getting Help

If you encounter issues:

1. **Check the README.md** - Comprehensive troubleshooting section
2. **Review your logs** - Check `logs/deploy_*.log` for details
3. **Test with --debug flag** - `./deploy.sh --debug` for verbose output
4. **Check HNG Slack** - Ask in #devops or #help channels
5. **Review error messages** - Thanos bot provides specific feedback

---

## ⏰ Important Dates

- **Deadline:** 11:59 PM GMT, October 22, 2025
- **Attempts Allowed:** 5
- **Late Submissions:** ❌ Not Accepted

**You have limited time! Submit as soon as you're ready.**

---

## 🚀 Ready to Submit?

1. ✅ Verify all requirements met
2. ✅ Push code to GitHub
3. ✅ Go to Slack channel
4. ✅ Run `/stage-one-devops`
5. ✅ Fill in your details
6. ✅ Submit form
7. ✅ Wait for Thanos bot response
8. ✅ Check results and proceed!

---

**Good luck! You've got this! 🎉**

Remember: The script is production-grade and handles all the automation for you. Just provide the correct inputs and let the script do its magic!
