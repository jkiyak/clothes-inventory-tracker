# Detailed Setup Guide

This guide walks through every step of deploying the Clothes Inventory Tracker to AWS.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [EC2 Setup](#ec2-setup)
3. [S3 Configuration](#s3-configuration)
4. [IAM User Creation](#iam-user-creation)
5. [Application Deployment](#application-deployment)
6. [Verification](#verification)

---

## Prerequisites

### What You Need
- AWS Account (free tier eligible)
- Credit/debit card (required for AWS signup, but won't be charged if staying in free tier)
- SSH client:
  - **Windows 10+**: Built-in SSH in PowerShell/CMD
  - **macOS/Linux**: Built-in SSH in Terminal
- Text editor (Notepad, VS Code, Sublime, etc.)

### Estimated Costs
- **EC2 t2.micro**: Free (750 hours/month for 12 months)
- **S3 Storage**: ~$0.023 per GB/month (~$0.001 for 100 photos)
- **S3 Requests**: ~$0.005 per 1,000 PUT requests
- **Data Transfer**: First 100GB/month free

**Expected monthly cost for this project: < $0.05**

---

## EC2 Setup

### Step 1: Launch EC2 Instance

1. **Log into AWS Console** as your IAM admin user (not root!)

2. **Navigate to EC2**:
   - Search for "EC2" in the top search bar
   - Click "EC2" under Services

3. **Launch Instance**:
   - Click orange "Launch instance" button
   - **Name**: `clothes-inventory-app`
   
4. **Choose AMI** (Amazon Machine Image):
   - Select: **Amazon Linux 2023 AMI**
   - Architecture: **64-bit (x86)**

5. **Choose Instance Type**:
   - Select: **t2.micro** (Free tier eligible)
   - Should show "Free tier eligible" label

6. **Key Pair (Login)**:
   - Click "Create new key pair"
   - Name: `clothes-app-key`
   - Key pair type: **RSA**
   - Private key format: **.pem**
   - Click "Create key pair"
   - **SAVE THIS FILE!** You can't download it again

7. **Network Settings**:
   - Click "Edit"
   - **Auto-assign public IP**: Enable
   - **Firewall (security groups)**: Create security group
   - Security group name: `clothes-app-sg`
   - Description: `Security group for clothes inventory app`

8. **Configure Security Group Rules**:
   
   **Rule 1 - SSH:**
   - Type: SSH
   - Protocol: TCP
   - Port: 22
   - Source: 0.0.0.0/0 (or "My IP" for better security)
   - Description: SSH access
   
   **Rule 2 - HTTP:**
   - Click "Add security group rule"
   - Type: HTTP
   - Protocol: TCP
   - Port: 80
   - Source: 0.0.0.0/0
   - Description: Web traffic

9. **Storage**:
   - Keep default: **8 GiB gp3** (Free tier eligible)

10. **Advanced Details** (Optional):
    - Leave everything as default

11. **Review and Launch**:
    - Click "Launch instance"
    - Wait for "Success" message
    - Click "View all instances"

### Step 2: Fix .pem File Permissions (Windows Only)

**If you're on macOS/Linux, skip to Step 3**

Open PowerShell and navigate to where you saved the .pem file:

```powershell
cd C:\path\to\your\key\

# Remove inherited permissions
icacls clothes-app-key.pem /inheritance:r

# Grant read permission only to yourself
icacls clothes-app-key.pem /grant:r "%username%:(R)"
```

### Step 3: Connect to Your Instance

1. **Get your instance's Public IP**:
   - In EC2 Console, select your instance
   - Copy the "Public IPv4 address" (e.g., 3.145.67.89)

2. **SSH into the instance**:

**Windows (PowerShell/CMD):**
```bash
ssh -i C:\path\to\clothes-app-key.pem ec2-user@YOUR-PUBLIC-IP
```

**macOS/Linux (Terminal):**
```bash
chmod 400 ~/path/to/clothes-app-key.pem
ssh -i ~/path/to/clothes-app-key.pem ec2-user@YOUR-PUBLIC-IP
```

3. **Accept fingerprint**:
   - Type `yes` when asked "Are you sure you want to continue connecting?"

4. **You're in!** You should see:
```
   ,     #_
   ~\_  ####_        Amazon Linux 2023
  ~~  \_#####\
  ~~     \###|
  ~~       \#/ ___
   ~~       V~' '->
    ~~~         /
      ~~._.   _/
         _/ _/
       _/m/'

[ec2-user@ip-172-31-x-x ~]$
```

### Step 4: Install Nginx

```bash
# Update package manager
sudo dnf update -y

# Install nginx
sudo dnf install nginx -y

# Start nginx
sudo systemctl start nginx

# Enable nginx to start on boot
sudo systemctl enable nginx

# Verify nginx is running
sudo systemctl status nginx
```

You should see "active (running)" in green.

### Step 5: Test Nginx

Open your browser and go to:
```
http://YOUR-PUBLIC-IP
```

You should see the default Nginx welcome page!

---

## S3 Configuration

### Step 1: Create S3 Bucket

1. **Navigate to S3**:
   - AWS Console → Search "S3" → Click S3

2. **Create Bucket**:
   - Click "Create bucket"
   - **Bucket name**: Must be globally unique
     - Try: `clothes-inventory-[yourname]-[year]`
     - Example: `clothes-inventory-john-2026`
   - **Region**: `us-east-1` (or your preferred region)
   - **Object Ownership**: ACLs disabled (recommended)

3. **Block Public Access Settings**:
   - **UNCHECK** "Block all public access"
   - Check the acknowledgment box
   - (We need this for images to be publicly viewable)

4. **Bucket Versioning**: Disabled

5. **Encryption**: Server-side encryption with Amazon S3 managed keys (SSE-S3)

6. **Click "Create bucket"**

### Step 2: Configure Bucket Policy

1. **Click on your new bucket**

2. **Go to "Permissions" tab**

3. **Scroll to "Bucket policy"**

4. **Click "Edit"**

5. **Paste this policy** (replace YOUR-BUCKET-NAME):

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::YOUR-BUCKET-NAME/*"
        }
    ]
}
```

6. **Click "Save changes"**

### Step 3: Configure CORS

1. **Still in "Permissions" tab**

2. **Scroll to "Cross-origin resource sharing (CORS)"**

3. **Click "Edit"**

4. **Paste this CORS configuration**:

```json
[
    {
        "AllowedHeaders": ["*"],
        "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
        "AllowedOrigins": ["*"],
        "ExposeHeaders": ["ETag"]
    }
]
```

**Note:** Using `"*"` for AllowedOrigins is fine for development/learning. For production, replace with your specific domain.

5. **Click "Save changes"**

---

## IAM User Creation

### Step 1: Create IAM User

1. **Navigate to IAM**:
   - AWS Console → Search "IAM" → Click IAM

2. **Create User**:
   - Click "Users" in left sidebar
   - Click "Create user"
   - **User name**: `clothes-app-s3-user`
   - Click "Next"

3. **Set Permissions**:
   - Select "Attach policies directly"
   - Search for: `AmazonS3FullAccess`
   - Check the box
   - Click "Next"

**Note:** For better security in production, create a custom policy that only allows access to your specific bucket.

4. **Review and Create**:
   - Click "Create user"

### Step 2: Create Access Keys

1. **Click on the user** you just created

2. **Go to "Security credentials" tab**

3. **Scroll to "Access keys"**

4. **Click "Create access key"**

5. **Use case**: Select "Application running outside AWS"

6. **Click "Next"**

7. **Description** (optional): `Clothes inventory app`

8. **Click "Create access key"**

9. **CRITICAL - Save These Credentials**:
   - **Access key ID**: Starts with AKIA...
   - **Secret access key**: Long random string
   - Click "Download .csv file" OR copy both values
   - **Store in password manager immediately**
   - You cannot retrieve the secret key again!

10. **Click "Done"**

---

## Application Deployment

### Step 1: Prepare the Application File

1. **Download** `app/index.html` from this repository

2. **Open in text editor** (Notepad, VS Code, etc.)

3. **Find the S3_CONFIG section** (around line 440):

```javascript
const S3_CONFIG = {
    bucketName: 'YOUR-BUCKET-NAME-HERE',
    region: 'us-east-1',
    accessKeyId: 'YOUR_ACCESS_KEY_ID_HERE',
    secretAccessKey: 'YOUR_SECRET_ACCESS_KEY_HERE'
};
```

4. **Replace placeholders**:
   - `YOUR-BUCKET-NAME-HERE` → Your actual bucket name
   - `us-east-1` → Your bucket's region (if different)
   - `YOUR_ACCESS_KEY_ID_HERE` → Your IAM access key ID
   - `YOUR_SECRET_ACCESS_KEY_HERE` → Your IAM secret access key

5. **Save the file**

### Step 2: Upload to EC2

**Method A: Using SCP (Recommended)**

From your local machine (PowerShell/Terminal):

```bash
# Upload file to EC2 /tmp directory
scp -i /path/to/clothes-app-key.pem /path/to/index.html ec2-user@YOUR-PUBLIC-IP:/tmp/
```

Then SSH in and move it:

```bash
# SSH into EC2
ssh -i /path/to/clothes-app-key.pem ec2-user@YOUR-PUBLIC-IP

# Copy to nginx directory
sudo cp /tmp/index.html /usr/share/nginx/html/index.html

# Exit SSH
exit
```

**Method B: Using Nano (Alternative)**

1. SSH into your EC2 instance

2. Open nano:
```bash
sudo nano /usr/share/nginx/html/index.html
```

3. Delete all content (Ctrl+K repeatedly)

4. Paste your entire HTML file (right-click or Shift+Insert)

5. Save: Ctrl+O, Enter, Ctrl+X

---

## Verification

### Test 1: Access the Application

1. **Open browser**

2. **Go to**: `http://YOUR-EC2-PUBLIC-IP`

3. **You should see**: Purple gradient page with "Clothes Inventory Tracker"

### Test 2: Add an Item

1. **Click "Add New Item" tab**

2. **Fill out form**:
   - Name: Test Hoodie
   - Brand: Nike
   - Category: Tops
   - Color: Blue
   - Upload a photo
   - Wash: Cold
   - Dry: No Heat
   - Wears before wash: 3

3. **Click "Add Item"**

4. **Should see**: "Uploading image..." then "Item added successfully!"

### Test 3: Verify S3 Upload

1. **Go to S3 Console**

2. **Click your bucket**

3. **You should see**: An image file with timestamp in name

4. **Click the image** → Check that it's viewable

### Test 4: Check Inventory

1. **Click "Inventory" tab**

2. **Should see**: Your test item with photo displayed

3. **Try**: Edit, Mark Washed, Daily Log features

---

## Common Issues

### "Permission denied" when SSH-ing
- Check .pem file permissions (Windows: use icacls commands above)
- Verify security group allows SSH from your IP
- Confirm instance is "running" state

### Can't access website
- Verify security group has HTTP rule (port 80, 0.0.0.0/0)
- Check nginx is running: `sudo systemctl status nginx`
- Confirm you're using http:// not https://

### Images not uploading
- Check S3 bucket policy is correct
- Verify CORS configuration saved
- Open browser console (F12) to see exact error
- Confirm AWS credentials in code are correct

### "Quota exceeded" error
- This means localStorage is full (shouldn't happen with S3)
- Clear localStorage: Browser console → `localStorage.clear()`

---

## Next Steps

✅ Application deployed successfully!

**Consider:**
- Set up Elastic IP (keeps same IP when instance restarts)
- Migrate to DynamoDB (data persists across IP changes)
- Add domain name (more professional than IP address)
- Implement HTTPS with Let's Encrypt
- Create backup/restore functionality

---

**Questions?** Check the [TROUBLESHOOTING.md](TROUBLESHOOTING.md) guide or open an issue!
