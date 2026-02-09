# EC2 Setup - Quick Start Guide

## Prerequisites
- AWS Account (free tier eligible)
- AWS CLI installed on your local machine
- PuTTY or Terminal for SSH

---

## Step 1: Launch EC2 Instance (AWS Console)

1. Go to **EC2 Dashboard**: https://console.aws.amazon.com/ec2/
2. Click **Launch Instances**
3. **AMI Selection**: Choose **Ubuntu Server 22.04 LTS** (Free Tier eligible)
4. **Instance Type**: Select **t2.micro** (1 GB RAM, free tier)
5. **Key Pair**: 
   - Click "Create new key pair" 
   - Name: `db-creation-key`
   - Format: `.pem` (for Mac/Linux) or `.ppk` (for PuTTY on Windows)
   - Download and save securely (e.g., `C:\AWS\db-creation-key.pem`)
6. **Network Settings**:
   - Create security group: `db-creation-sg`
   - Allow SSH (Port 22) from your IP
   - Allow HTTP (Port 80) from anywhere (0.0.0.0/0)
   - Allow Custom TCP (Port 8000) from anywhere (for FastAPI)
7. **Storage**: 20 GB (default free tier)
8. Click **Launch Instance**

### Security Group Configuration
| Protocol | Port | Source |
|----------|------|--------|
| SSH | 22 | Your IP (or 0.0.0.0/0 for testing) |
| HTTP | 80 | 0.0.0.0/0 |
| TCP | 8000 | 0.0.0.0/0 |

---

## Step 2: Connect to Your Instance

### Option A: SSH from Terminal (Windows 10+, Mac, Linux)

```powershell
# Replace with your EC2 public IP (find in EC2 console)
$PublicIP = "your-ec2-public-ip"

# Connect via SSH
ssh -i "C:\path\to\db-creation-key.pem" ubuntu@$PublicIP

# On first connection, type 'yes' to add to known hosts
```

### Option B: Using PuTTY (Windows)

1. Download PuTTYgen, convert `.pem` to `.ppk`
2. Open PuTTY
3. Host: `ubuntu@your-ec2-public-ip`
4. Connection → SSH → Auth → Private key file: select `.ppk`
5. Open

### Option C: AWS Systems Manager (No key needed)

1. EC2 Dashboard → Select instance
2. Click **Connect** → **Session Manager**
3. Click **Connect** (browser-based terminal)

---

## Step 3: Run Automated Setup Script

Once connected to EC2, copy and run this setup script:

```bash
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
echo "1. Run FastAPI server manually (test):"
echo "   cd /home/ubuntu/db_creation"
echo "   source venv/bin/activate"
echo "   python3 -m uvicorn Database.db_using_sqlalchemy_fastapi:app --host 0.0.0.0 --port 8000"
echo ""
echo "2. Run FastAPI in background (persistent):"
echo "   bash /home/ubuntu/db_creation/start_fastapi.sh"
echo ""
echo "3. Access from your local machine:"
echo "   curl http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8000/docs"
echo ""
```

### Run the Script

```bash
# Option 1: Paste the script directly in terminal
# (Copy from above and paste into SSH session)

# Option 2: Download and run
wget https://raw.githubusercontent.com/Alok-Sethi/db_creation/master/setup-ec2.sh
chmod +x setup-ec2.sh
./setup-ec2.sh
```

---

## Step 4: Start FastAPI Server

After setup script completes, you have two options:

### Option A: Run in Foreground (for testing)

```bash
cd /home/ubuntu/db_creation
source venv/bin/activate
python3 -m uvicorn Database.db_using_sqlalchemy_fastapi:app --host 0.0.0.0 --port 8000
```

Your app will be live at: `http://your-ec2-public-ip:8000`

### Option B: Run in Background (using tmux - persistent)

Create `start_fastapi.sh`:

```bash
#!/bin/bash
cd /home/ubuntu/db_creation
source venv/bin/activate

# Kill any existing tmux session
tmux kill-session -t fastapi 2>/dev/null || true

# Create new session and run server
tmux new-session -d -s fastapi
tmux send-keys -t fastapi "cd /home/ubuntu/db_creation && source venv/bin/activate && python3 -m uvicorn Database.db_using_sqlalchemy_fastapi:app --host 0.0.0.0 --port 8000" Enter

echo "FastAPI server started in tmux session 'fastapi'"
echo "Access at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8000"
```

```bash
chmod +x /home/ubuntu/db_creation/start_fastapi.sh
bash /home/ubuntu/db_creation/start_fastapi.sh
```

---

## Step 5: Test from Your Local Machine

Get your EC2 public IP:

```bash
# In EC2 session
curl http://169.254.169.254/latest/meta-data/public-ipv4
```

Then from your **local** machine:

```powershell
$IP = "your-ec2-public-ip"

# Test API docs
curl "http://$IP:8000/docs"

# Get all users
curl "http://$IP:8000/users"

# Create a user
curl -X POST "http://$IP:8000/users" `
  -H "Content-Type: application/json" `
  -d "{`"name`":`"John Doe`",`"email`":`"john@example.com`",`"password`":`"secret123`"}"

# Get single user
curl "http://$IP:8000/users/1"
```

Open in browser: `http://your-ec2-public-ip:8000/docs` for interactive Swagger UI.

---

## Step 6: Monitor & Manage

### Check if server is running

```bash
# SSH into instance
ssh -i "your-key.pem" ubuntu@your-ec2-public-ip

# Check tmux sessions
tmux list-sessions

# View logs
tmux capture-pane -t fastapi -p

# Stop server
tmux kill-session -t fastapi

# View running processes
ps aux | grep uvicorn
```

### Check database

```bash
cd /home/ubuntu/db_creation

# View all users in SQLite
sqlite3 employee.db "SELECT * FROM users;"

# Check table schema
sqlite3 employee.db ".schema users"
```

---

## Troubleshooting

### Can't connect via SSH
```powershell
# Check key permissions (Windows)
icacls "C:\path\to\db-creation-key.pem" /inheritance:r /grant:r "%USERNAME%:F"

# Or use Session Manager instead (browser-based, no key needed)
```

### Port 8000 not accessible
```bash
# Check security group allows port 8000
# AWS Console → EC2 → Security Groups → db-creation-sg

# Check if app is running
ps aux | grep uvicorn

# Check if port is listening
sudo netstat -tulpn | grep 8000
```

### Out of memory
```bash
# Check memory usage
free -h

# If needed, upgrade instance to t2.small (costs ~$10/month)
# AWS Console → EC2 → Stop instance → Instance Settings → Change Instance Type
```

### Permission denied on .pem file
```powershell
# Fix permissions on Windows
icacls "path\to\key.pem" /inheritance:r /grant:r "%USERNAME%:R"
```

---

## Cost Estimate

**Monthly Cost (Free Tier):**
- EC2 t2.micro: **FREE** (750 hrs/month included, covers 24/7)
- Data transfer: **FREE** (up to 100 GB/month)
- Storage: **FREE** (20 GB EBS)
- **Total: $0** (first 12 months)

After free tier: ~$10-15/month for one t2.micro instance.

---

## Next: Make It Persistent

If you want the server to restart automatically on reboot:

Create `/etc/systemd/system/fastapi.service`:

```bash
sudo tee /etc/systemd/system/fastapi.service > /dev/null << 'EOF'
[Unit]
Description=FastAPI App
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/db_creation
ExecStart=/home/ubuntu/db_creation/venv/bin/uvicorn Database.db_using_sqlalchemy_fastapi:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable service
sudo systemctl enable fastapi
sudo systemctl start fastapi

# Check status
sudo systemctl status fastapi
```

---

## Quick Reference

| Task | Command |
|------|---------|
| SSH into instance | `ssh -i key.pem ubuntu@ec2-ip` |
| Start FastAPI | `tmux new-session -d -s fastapi -c /home/ubuntu/db_creation "source venv/bin/activate && python3 -m uvicorn Database.db_using_sqlalchemy_fastapi:app --host 0.0.0.0 --port 8000"` |
| View logs | `tmux capture-pane -t fastapi -p` |
| Stop server | `tmux kill-session -t fastapi` |
| Check database | `sqlite3 employee.db "SELECT * FROM users;"` |
| View EC2 public IP | `curl http://169.254.169.254/latest/meta-data/public-ipv4` |
| Restart instance | EC2 Console → Right-click → Instance State → Reboot |

---

**Ready to deploy? Follow the steps above and you'll have your app running in AWS in ~10 minutes!**

Need help? Let me know!
