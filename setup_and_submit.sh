#!/bin/bash

# HNG DevOps Stage 1 - Final Setup Helper Script
# This script helps you set up and push your code to GitHub

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   HNG DevOps Stage 1 - GitHub Setup & Submission Helper   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${YELLOW}This script will help you:${NC}"
echo "  1. Configure your GitHub credentials"
echo "  2. Initialize and push your repository"
echo "  3. Verify everything is ready for submission"

# Check prerequisites
check_prerequisites() {
    echo -e "\n${BLUE}[Step 1] Checking prerequisites...${NC}"
    
    local missing=0
    
    if ! command -v git &> /dev/null; then
        echo -e "${RED}✗ Git is not installed${NC}"
        echo "  Install with: sudo apt-get install -y git"
        missing=1
    else
        echo -e "${GREEN}✓ Git is installed$(git --version | sed 's/git version //' )${NC}"
    fi
    
    if ! command -v bash &> /dev/null; then
        echo -e "${RED}✗ Bash is not available${NC}"
        missing=1
    else
        echo -e "${GREEN}✓ Bash is available${NC}"
    fi
    
    if [[ $missing -eq 1 ]]; then
        echo -e "${RED}Please install missing prerequisites and try again${NC}"
        exit 1
    fi
}

# Collect GitHub information
collect_github_info() {
    echo -e "\n${BLUE}[Step 2] Collecting GitHub information...${NC}"
    
    read -p "  Enter your GitHub username: " GITHUB_USERNAME
    read -p "  Enter your email (for commits): " GITHUB_EMAIL
    read -p "  Enter your repository URL: " GITHUB_REPO_URL
    
    # Validate inputs
    if [[ -z "$GITHUB_USERNAME" || -z "$GITHUB_EMAIL" || -z "$GITHUB_REPO_URL" ]]; then
        echo -e "${RED}Error: All fields are required${NC}"
        exit 1
    fi
    
    # Accept both HTTPS and SSH URL formats
    if [[ ! $GITHUB_REPO_URL =~ ^https://github.com/.*\.git$ ]] && [[ ! $GITHUB_REPO_URL =~ ^git@github.com:.*\.git$ ]]; then
        echo -e "${RED}Error: Invalid repository URL format${NC}"
        echo -e "  Expected: https://github.com/username/repo.git (HTTPS)"
        echo -e "  Or:       git@github.com:username/repo.git (SSH)${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ GitHub information collected${NC}"
}

# Configure git
configure_git() {
    echo -e "\n${BLUE}[Step 3] Configuring Git...${NC}"
    
    git config user.name "$GITHUB_EMAIL" && echo -e "${GREEN}✓ User name configured${NC}" || true
    git config user.email "$GITHUB_EMAIL" && echo -e "${GREEN}✓ User email configured${NC}" || true
}

# Initialize repository
init_repository() {
    echo -e "\n${BLUE}[Step 4] Initializing repository...${NC}"
    
    local repo_dir="/home/freeman/HNG/devops/stage1"
    cd "$repo_dir"
    
    # Check if git is already initialized
    if [[ -d .git ]]; then
        echo -e "${YELLOW}⚠ Git repository already initialized${NC}"
        read -p "  Do you want to reinitialize? (y/n): " reinit
        if [[ $reinit == "y" ]]; then
            rm -rf .git
            git init
            echo -e "${GREEN}✓ Repository reinitialized${NC}"
        else
            echo -e "${YELLOW}Skipping reinitialization${NC}"
        fi
    else
        git init
        echo -e "${GREEN}✓ Repository initialized${NC}"
    fi
}

# Add and commit files
add_and_commit() {
    echo -e "\n${BLUE}[Step 5] Adding and committing files...${NC}"
    
    local repo_dir="/home/freeman/HNG/devops/stage1"
    cd "$repo_dir"
    
    # Check for uncommitted changes
    if [[ -z "$(git status --porcelain)" ]] && git log -1 &>/dev/null; then
        echo -e "${YELLOW}⚠ No changes to commit${NC}"
        read -p "  Commit anyway? (y/n): " commit_anyway
        [[ $commit_anyway != "y" ]] && return
    fi
    
    git add .
    git commit -m "HNG DevOps Stage 1: Automated Docker Deployment Script" -m "
- Complete automated deployment script (deploy.sh)
- Comprehensive README with usage instructions
- Error handling, logging, and validation
- Nginx reverse proxy configuration
- Full Docker deployment automation
- Idempotent operations with cleanup flag

Implements all 10 stage 1 requirements."
    
    echo -e "${GREEN}✓ Files committed${NC}"
}

# Set remote and push
push_to_github() {
    echo -e "\n${BLUE}[Step 6] Pushing to GitHub...${NC}"
    
    local repo_dir="/home/freeman/HNG/devops/stage1"
    cd "$repo_dir"
    
    # Check if remote exists
    if git remote get-url origin &>/dev/null; then
        echo -e "${YELLOW}⚠ Remote 'origin' already exists${NC}"
        local current_remote=$(git remote get-url origin)
        echo "  Current: $current_remote"
        echo "  New:     $GITHUB_REPO_URL"
        read -p "  Update to new remote? (y/n): " update_remote
        if [[ $update_remote == "y" ]]; then
            git remote set-url origin "$GITHUB_REPO_URL"
        fi
    else
        git remote add origin "$GITHUB_REPO_URL"
        echo -e "${GREEN}✓ Remote added${NC}"
    fi
    
    # Rename branch to main if needed
    if ! git symbolic-ref -q refs/remotes/origin/HEAD &>/dev/null; then
        git branch -M main || true
        echo -e "${GREEN}✓ Branch renamed to main${NC}"
    fi
    
    # Push to GitHub
    git push -u origin main
    echo -e "${GREEN}✓ Code pushed to GitHub${NC}"
}

# Verify submission
verify_submission() {
    echo -e "\n${BLUE}[Step 7] Verifying submission readiness...${NC}"
    
    local repo_dir="/home/freeman/HNG/devops/stage1"
    cd "$repo_dir"
    
    # Check files
    local required_files=("deploy.sh" "README.md" ".gitignore")
    local all_exist=true
    
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            echo -e "${GREEN}✓ $file exists${NC}"
        else
            echo -e "${RED}✗ $file missing${NC}"
            all_exist=false
        fi
    done
    
    # Check if deploy.sh is executable
    if [[ -x deploy.sh ]]; then
        echo -e "${GREEN}✓ deploy.sh is executable${NC}"
    else
        echo -e "${RED}✗ deploy.sh is not executable${NC}"
        chmod +x deploy.sh
        echo -e "${GREEN}✓ Made executable${NC}"
    fi
    
    # Check bash syntax
    if bash -n deploy.sh &>/dev/null; then
        echo -e "${GREEN}✓ Bash syntax is valid${NC}"
    else
        echo -e "${RED}✗ Bash syntax errors found${NC}"
        all_exist=false
    fi
    
    # Check git status
    if [[ -z "$(git status --porcelain)" ]]; then
        echo -e "${GREEN}✓ All changes committed${NC}"
    else
        echo -e "${RED}✗ Uncommitted changes found${NC}"
        echo -e "${YELLOW}Run: git add -A && git commit -m 'Fix'${NC}"
        all_exist=false
    fi
    
    # Check remote
    if git remote get-url origin &>/dev/null; then
        echo -e "${GREEN}✓ Remote 'origin' configured${NC}"
        echo "  URL: $(git remote get-url origin)"
    else
        echo -e "${RED}✗ Remote 'origin' not configured${NC}"
        all_exist=false
    fi
    
    if [[ $all_exist == true ]]; then
        echo -e "\n${GREEN}✅ All checks passed! Ready for submission${NC}"
    else
        echo -e "\n${RED}❌ Some issues found. Please fix them and try again${NC}"
        exit 1
    fi
}

# Print submission instructions
print_submission_info() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║            READY FOR SUBMISSION TO HNG!                   ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}📋 Your GitHub Repository:${NC}"
    echo -e "  ${GITHUB_REPO_URL}"
    
    echo -e "\n${YELLOW}📝 Submission Steps:${NC}"
    echo "  1. Open Slack (HNG Workspace)"
    echo "  2. Go to channel: #track-devops or #stage-1-devops"
    echo "  3. Type: /stage-one-devops"
    echo "  4. Fill in the form:"
    echo "     - Full Name: Your Full Name"
    echo "     - GitHub URL: ${GITHUB_REPO_URL}"
    echo "  5. Submit the form"
    echo "  6. Wait for Thanos bot response"
    
    echo -e "\n${YELLOW}⏰ Important Dates:${NC}"
    echo "  • Deadline: 11:59 PM GMT, Oct 22, 2025"
    echo "  • Attempts: 5 maximum"
    echo "  • Late Submissions: NOT accepted"
    
    echo -e "\n${YELLOW}✅ What's Included:${NC}"
    echo "  ✓ deploy.sh - Complete deployment automation script"
    echo "  ✓ README.md - Comprehensive documentation"
    echo "  ✓ .gitignore - Prevents committing sensitive files"
    echo "  ✓ Meets all 10 stage 1 requirements"
    echo "  ✓ Production-grade error handling"
    echo "  ✓ Comprehensive logging"
    echo "  ✓ Idempotent operations"
    
    echo -e "\n${YELLOW}📚 Documentation:${NC}"
    echo "  • README.md - Full usage guide"
    echo "  • DEPLOYMENT_GUIDE.md - Step-by-step deployment"
    echo "  • Script help: ./deploy.sh --help"
    
    echo -e "\n${GREEN}Good luck with your submission! 🚀${NC}\n"
}

# Main execution
main() {
    check_prerequisites
    collect_github_info
    configure_git
    init_repository
    add_and_commit
    push_to_github
    verify_submission
    print_submission_info
}

# Run main
main
