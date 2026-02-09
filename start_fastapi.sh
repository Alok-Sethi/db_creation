#!/bin/bash
# Start FastAPI server in tmux background session

cd /home/ubuntu/db_creation
source venv/bin/activate

echo "Starting FastAPI server..."

# Kill any existing tmux session
tmux kill-session -t fastapi 2>/dev/null || true

# Create new session and run server
tmux new-session -d -s fastapi
tmux send-keys -t fastapi "cd /home/ubuntu/db_creation && source venv/bin/activate && python3 -m uvicorn Database.db_using_sqlalchemy_fastapi:app --host 0.0.0.0 --port 8000" Enter

sleep 2

# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

echo ""
echo "✅ FastAPI server started in tmux session 'fastapi'"
echo ""
echo "🔗 Access your app:"
echo "   http://$PUBLIC_IP:8000"
echo ""
echo "📚 Swagger UI (interactive docs):"
echo "   http://$PUBLIC_IP:8000/docs"
echo ""
echo "📊 ReDoc (alternative docs):"
echo "   http://$PUBLIC_IP:8000/redoc"
echo ""
echo "To view logs:"
echo "   tmux attach-session -t fastapi"
echo ""
echo "To stop server:"
echo "   tmux kill-session -t fastapi"
echo ""
