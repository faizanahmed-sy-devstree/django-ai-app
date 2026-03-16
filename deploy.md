This is your **AI Engineering Deployment Manual**. Keep this file (e.g., `DEPLOYMENT.md`) in your project root. It covers the entire lifecycle from a blank AWS server to pushing daily updates.

---

# 🚀 Django AI Deployment Guide: AWS EC2 + Docker + uv

This guide documents the professional workflow for deploying and maintaining your Django AI application on an AWS EC2 instance.

---

## 🏗️ 1. Initial AWS Server Setup (One-Time)

### A. Launch EC2
1. **AMI:** Ubuntu 24.04 LTS.
2. **Instance Type:** `t3.micro` (Free Tier) or `t3.medium` (Recommended for AI).
3. **Security Group Inbound Rules:**
   - SSH (Port 22): My IP
   - HTTP (Port 80): Anywhere
   - Custom TCP (Port 8000): Anywhere

### B. Prepare Local Key
```bash
chmod 400 ~/Documents/KEYS/my-ai-key.pem
```

### C. Install Docker on EC2
SSH into the server:
```bash
ssh -i "~/Documents/KEYS/my-ai-key.pem" ubuntu@43.205.196.41
```
Run this setup script:
```bash
sudo apt update && sudo apt install -y docker.io docker-compose-v2
sudo usermod -aG docker ubuntu
exit  # Log out to apply permissions
```

---

## 🚚 2. Initial Deployment (First Time)

### A. Create `.dockerignore` (Local Laptop)
Create this file in your project root to prevent uploading 100MB+ of useless files.
```text
.venv
__pycache__
.git
db.sqlite3
staticfiles
.env
```

### B. Upload Code to EC2
Run this from your **local** project folder:
```bash
rsync -avz -e "ssh -i ~/Documents/KEYS/my-ai-key.pem" \
--exclude='.venv' --exclude='__pycache__' --exclude='.git' \
. ubuntu@43.205.196.41:~/django-ai-app
```

### C. Launch Containers (On EC2)
SSH back into EC2 and run:
```bash
cd ~/django-ai-app
docker compose up -d --build
docker compose exec web python manage.py migrate
docker compose exec web python manage.py createsuperuser
```

---

## 🔄 3. Pushing Changes (Daily Workflow)

Whenever you change your code or add a library, follow this **"3-Step Push"**:

### Step 1: Upload the changes (Local Laptop)
```bash
rsync -avz -e "ssh -i ~/Documents/KEYS/my-ai-key.pem" \
--exclude='.venv' --exclude='__pycache__' --exclude='.git' \
. ubuntu@43.205.196.41:~/django-ai-app
```

### Step 2: Rebuild/Restart (On EC2)
```bash
# If you added a new library (e.g., uv add openai)
docker compose up -d --build

# OR: If you only changed code logic (views, urls)
docker compose restart web
```

### Step 3: Database Updates (If you changed `models.py`)
```bash
docker compose exec web python manage.py makemigrations
docker compose exec web python manage.py migrate
```

---

## 🛠️ 4. Maintenance & Debugging

| Goal | Command |
| :--- | :--- |
| **Check if app is running** | `docker ps` |
| **View live error logs** | `docker compose logs -f web` |
| **Fix "Disk Full" errors** | `docker system prune -a` |
| **Restart the Database** | `docker compose restart db` |
| **Open Python Shell** | `docker compose exec web python manage.py shell` |

---

## 🔐 5. Security (Critical)

### Environment Variables
**Never** put API Keys (OpenAI, Anthropic) directly in your code.
1. On EC2, create a `.env` file: `nano ~/django-ai-app/.env`
2. Add your keys:
   ```text
   OPENAI_API_KEY=sk-xxxx
   DEBUG=0
   ```
3. Update `docker-compose.yml` to include:
   ```yaml
   web:
     env_file:
       - .env
   ```

### Collectstatic (CSS Fix)
If the Admin UI looks broken on AWS, run:
```bash
docker compose exec web python manage.py collectstatic --noinput
docker compose restart web
```

---

## 🛑 6. Shutdown
If you want to stop the server to save costs/CPU:
```bash
docker compose down
```