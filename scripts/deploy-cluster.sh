#!/bin/bash
set -e

# Talos Homelab Cluster Deployment Script
# This script automates the complete E2E deployment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Talos Homelab Cluster Deployment"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
log_info "Checking prerequisites..."

if ! command -v tofu &> /dev/null; then
    log_error "OpenTofu not found. Please install: https://opentofu.org/docs/intro/install/"
    exit 1
fi

if ! command -v talosctl &> /dev/null; then
    log_error "talosctl not found. Please install: https://www.talos.dev/latest/introduction/getting-started/"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    log_error "kubectl not found. Please install: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

if ! command -v ansible &> /dev/null; then
    log_error "Ansible not found. Please install: https://docs.ansible.com/ansible/latest/installation_guide/"
    exit 1
fi

log_info "All prerequisites found!"
echo ""

# Step 1: Provision infrastructure
log_info "Step 1: Provisioning infrastructure with OpenTofu..."
cd "$PROJECT_ROOT/infrastructure"

if [ ! -f "creds.auto.tfvars" ]; then
    log_error "creds.auto.tfvars not found. Please create it with your credentials."
    exit 1
fi

if [ ! -f "machines.auto.tfvars" ]; then
    log_error "machines.auto.tfvars not found. Please create it with your machine configuration."
    exit 1
fi

log_info "Initializing OpenTofu..."
tofu init

log_info "Planning infrastructure changes..."
tofu plan -out=tfplan

read -p "Apply these changes? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    log_warn "Deployment cancelled by user"
    exit 0
fi

log_info "Applying infrastructure..."
tofu apply tfplan
rm -f tfplan

log_info "Infrastructure provisioned successfully!"
echo ""

# Step 2: Wait for VMs to boot
log_info "Step 2: Waiting for VMs to boot..."
log_warn "Waiting 60 seconds for VMs to fully start..."
sleep 60

echo ""

# Step 3: Configure Talos
log_info "Step 3: Configuring Talos Linux with Ansible..."
cd "$PROJECT_ROOT/ansible"

if [ ! -f "inventory/hosts.yml" ]; then
    log_error "Ansible inventory not found. OpenTofu should have generated it."
    exit 1
fi

log_info "Running Ansible playbook..."
ansible-playbook playbooks/talos-bootstrap.yml -i inventory/hosts.yml

echo ""

# Step 4: Verify deployment
log_info "Step 4: Verifying deployment..."

log_info "Cluster nodes:"
kubectl get nodes -o wide

echo ""
log_info "All pods:"
kubectl get pods -A

echo ""
log_info "=========================================="
log_info "Deployment Complete!"
log_info "=========================================="
echo ""
echo "Cluster Information:"
echo "  - Kubeconfig: ~/.kube/config"
echo "  - Talosconfig: ~/.talos/config"
echo "  - API Endpoint: Check 'tofu output cluster_endpoints'"
echo ""
echo "Useful commands:"
echo "  kubectl get nodes"
echo "  kubectl get pods -A"
echo "  talosctl health"
echo "  talosctl dashboard"
echo ""
