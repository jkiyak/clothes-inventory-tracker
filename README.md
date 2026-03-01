# Clothes Inventory Tracker

A full-stack web application for managing clothing inventory, tracking wear patterns, and organizing laundry by care instructions. Built with vanilla JavaScript and deployed on AWS infrastructure.

![Project Status](https://img.shields.io/badge/status-active-success.svg)
![AWS](https://img.shields.io/badge/AWS-EC2%20%7C%20S3%20%7C%20IAM-orange)

## 🎯 Features

- **Daily Wear Logging**: Quick checkbox interface to track what you wore each day
- **Smart Inventory Management**: View all items with wear counts, wash status, and days since last wash
- **Intelligent Wash Grouping**: Automatically groups clothes by care instructions (temperature, dry method, special care)
- **Cloud Image Storage**: Upload photos of items stored in AWS S3
- **Edit Functionality**: Update item details, add/change photos after creation
- **Persistent Data**: LocalStorage for metadata, S3 for images

## 🏗️ Architecture

**Frontend:**
- HTML5, CSS3, JavaScript (ES6+)
- AWS SDK for JavaScript (S3 integration)
- Responsive design with mobile support

**Backend/Infrastructure:**
- **AWS EC2**: Amazon Linux 2023, t2.micro instance
- **Nginx**: Web server for static content delivery
- **AWS S3**: Cloud object storage for images
- **AWS IAM**: Secure credential management with least-privilege access

**Security:**
- Security Groups for network access control
- IAM user with S3-only permissions
- S3 bucket policies for public read access
- CORS configuration for cross-origin requests

## 📋 Prerequisites

- AWS Account (free tier eligible)
- SSH client (included in Windows 10+/macOS/Linux)
- Basic understanding of AWS console
- Text editor

## 🚀 Deployment Guide

### 1. EC2 Instance Setup

**Launch Instance:**
```bash
# Instance type: t2.micro (free tier)
# AMI: Amazon Linux 2023
# Key pair: Create and download .pem file
```

**Configure Security Group:**
- Inbound Rules:
  - SSH (port 22): Your IP or 0.0.0.0/0
  - HTTP (port 80): 0.0.0.0/0

**Connect via SSH:**
```bash
# Fix .pem permissions (Windows PowerShell)
icacls your-key.pem /inheritance:r
icacls your-key.pem /grant:r "%username%:(R)"

# Connect to instance
ssh -i your-key.pem ec2-user@YOUR-EC2-PUBLIC-IP
```

### 2. Install Nginx

```bash
# Install nginx
sudo dnf install nginx -y

# Start and enable nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 3. S3 Bucket Setup

**Create Bucket:**
1. Go to S3 Console → Create bucket
2. Bucket name: `your-unique-bucket-name`
3. Region: `us-east-1` (or your preferred region)
4. **Uncheck** "Block all public access"
5. Acknowledge the warning

**Configure Bucket Policy:**

Go to Permissions → Bucket policy → Edit:

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

**Configure CORS:**

Go to Permissions → CORS → Edit:

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

### 4. IAM User Setup

**Create IAM User:**
1. IAM Console → Users → Create user
2. User name: `s3-upload-user`
3. Attach policy: `AmazonS3FullAccess` (or create custom policy for your bucket only)

**Generate Access Keys:**
1. Security credentials → Create access key
2. Use case: "Application running outside AWS"
3. **Save both Access Key ID and Secret Access Key**

### 5. Deploy Application

**Prepare the application file:**

1. Open `app/index.html` in a text editor
2. Find the S3_CONFIG section (around line 240)
3. Update with your values:

```javascript
const S3_CONFIG = {
    bucketName: 'YOUR-BUCKET-NAME',
    region: 'us-east-1',
    accessKeyId: 'YOUR-ACCESS-KEY-ID',
    secretAccessKey: 'YOUR-SECRET-ACCESS-KEY'
};
```

**Upload to EC2:**

```bash
# From your local machine
scp -i your-key.pem app/index.html ec2-user@YOUR-EC2-IP:/tmp/

# SSH into EC2
ssh -i your-key.pem ec2-user@YOUR-EC2-IP

# Copy to nginx directory
sudo cp /tmp/index.html /usr/share/nginx/html/index.html
```

**Access your application:**
```
http://YOUR-EC2-PUBLIC-IP
```

## 💡 Usage

### Adding Items
1. Navigate to "Add New Item" tab
2. Fill in item details:
   - Name, Brand, Category, Color
   - Photo (optional)
   - Wash temperature and dry method
   - Special care instructions
   - Wears before wash threshold
3. Click "Add Item"

### Daily Logging
1. Go to "Daily Log" tab
2. Check boxes for items you wore today
3. Click "Log Today's Wear"

### Managing Laundry
1. Visit "Ready to Wash" tab
2. Items are automatically grouped by care instructions
3. Mark individual items or entire groups as washed

### Editing Items
1. Go to "Inventory" tab
2. Click "Edit" on any item
3. Update details and save

## 🔧 Troubleshooting

### Images not uploading
- Check S3 bucket policy is set correctly
- Verify CORS configuration includes your EC2 IP or uses wildcard `*`
- Check browser console for specific errors
- Confirm IAM credentials are correct in code

### Can't SSH into instance
- Verify security group allows SSH from your IP
- Check .pem file permissions (should be read-only for you)
- Confirm instance is in "running" state
- Use correct username: `ec2-user` for Amazon Linux

### Data lost after restart
- LocalStorage is tied to IP address
- If EC2 IP changes on restart, data appears lost
- Solution: Use Elastic IP or migrate to DynamoDB

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for more details.

## 📊 Technical Decisions

### Why S3 instead of localStorage?
- LocalStorage has 5-10MB limit (base64 images consume this quickly)
- S3 provides unlimited scalable storage
- Images persist even if browser data is cleared
- Enables future multi-device access

### Why IAM user instead of root credentials?
- Security best practice: least-privilege access
- Limits damage if credentials are compromised
- Can be easily rotated or revoked
- Demonstrates professional AWS security knowledge

### Why Nginx?
- Lightweight and efficient for static content
- Industry-standard web server
- Simple configuration
- Excellent performance for this use case

## 🔐 Security Considerations

**⚠️ IMPORTANT:** This is a learning project. For production use:

1. **Don't hardcode credentials in frontend code**
   - Use backend API with proper authentication
   - Implement AWS Cognito for user management
   - Use temporary credentials via STS

2. **Restrict S3 bucket access**
   - Use signed URLs for uploads
   - Implement proper access controls
   - Enable versioning and logging

3. **Use HTTPS**
   - Get SSL certificate (Let's Encrypt)
   - Configure nginx for HTTPS
   - Redirect HTTP to HTTPS

4. **Implement rate limiting**
   - Prevent abuse of upload functionality
   - Use AWS WAF for protection

## 🚧 Future Enhancements

- [ ] Migrate data storage to DynamoDB for multi-device sync
- [ ] Add user authentication with AWS Cognito
- [ ] Implement backend API with Lambda + API Gateway
- [ ] Add image compression before upload
- [ ] Create mobile app version
- [ ] Add analytics dashboard for wear patterns
- [ ] Implement outfit suggestions based on weather
- [ ] Add barcode scanning for quick item entry

## 📝 Lessons Learned

### Technical Challenges
- **CORS Configuration**: Required understanding of cross-origin policies
- **ACL Deprecation**: Adapted from ACL-based permissions to bucket policies
- **Windows Permissions**: Handled .pem file permission issues on Windows
- **LocalStorage Limitations**: Discovered and migrated from base64 to cloud storage

### Cloud Engineering Insights
- Importance of reading error messages carefully
- Value of testing in isolation (browser console testing)
- Security group configuration is critical for connectivity
- Always use least-privilege IAM permissions

## 🤝 Contributing

This is a learning project, but suggestions are welcome! Feel free to:
- Open issues for bugs or questions
- Submit pull requests with improvements
- Share your own implementations

## 📄 License

MIT License - feel free to use this code for learning purposes

## 👤 Author

Built as a hands-on AWS learning project to understand:
- EC2 instance management
- S3 object storage
- IAM security implementation
- Web server configuration
- Cloud application deployment

---

**Note:** Remember to stop your EC2 instance when not in use to avoid unnecessary charges. Images in S3 will persist and cost ~$0.023 per GB per month.
