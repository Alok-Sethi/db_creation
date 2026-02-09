#!/bin/bash
set -e

echo "========================================="
echo "DB Creation App - EC2 Setup Script"
echo "========================================="

# Update system
echo "[1/6] Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install dependencies
echo "[2/6] Installing Python, Git, and SQLite..."
sudo apt install -y python3 python3-pip python3-venv git sqlite3 tmux curl

# Clone repository
echo "[3/6] Cloning repository..."
cd /home/ubuntu
rm -rf db_creation 2>/dev/null || true
git clone https://github.com/Alok-Sethi/db_creation.git
cd db_creation

# Create virtual environment
echo "[4/6] Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Run SQLite script
echo "[5/6] Running standalone SQLite script..."
python3 Database/db_using_sqllite.py

# Display next steps
echo "[6/6] Setup complete!"
echo ""
echo "========================================="
echo "Next Steps:"
echo "========================================="
echo ""
echo "1. Start FastAPI server:"
echo "   bash /home/ubuntu/db_creation/start_fastapi.sh"
echo ""
echo "2. Access your app:"
echo "   http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8000/docs"
echo ""
echo "3. View logs:"
echo "   tmux attach-session -t fastapi"
echo ""
