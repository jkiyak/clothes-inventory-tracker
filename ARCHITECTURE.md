# System Architecture

## Overview

The Clothes Inventory Tracker is a serverless-frontend application deployed on AWS infrastructure. It uses a static web interface with cloud-based storage for scalability and reliability.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                          USER DEVICE                             │
│  ┌────────────────────────────────────────────────────────┐     │
│  │                 Web Browser                             │     │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │     │
│  │  │   HTML/CSS   │  │  JavaScript  │  │  AWS SDK JS  │ │     │
│  │  └──────────────┘  └──────────────┘  └──────────────┘ │     │
│  │         │                 │                  │          │     │
│  │         └─────────────────┴──────────────────┘          │     │
│  │                       │                                 │     │
│  │                localStorage (Metadata)                  │     │
│  └────────────────────────┬───────────────────────────────┘     │
└────────────────────────────┼───────────────────────────────────┘
                             │
                             │ HTTP (Port 80)
                             │
                ┌────────────▼─────────────┐
                │                          │
                │    AWS EC2 Instance      │
                │  (Amazon Linux 2023)     │
                │                          │
                │  ┌────────────────────┐  │
                │  │   Nginx Server     │  │
                │  │   (Port 80)        │  │
                │  │                    │  │
                │  │  Serves:           │  │
                │  │  - index.html      │  │
                │  │  - Static assets   │  │
                │  └────────────────────┘  │
                │                          │
                └──────────────────────────┘
                             │
                    ┌────────┴────────┐
                    │                 │
            ┌───────▼──────┐   ┌─────▼────────┐
            │              │   │              │
            │   AWS IAM    │   │   AWS S3     │
            │              │   │   Bucket     │
            │  IAM User:   │   │              │
            │  s3-upload   │   │  Storage:    │
            │              │   │  - Images    │
            │  Permissions:│   │  - Photos    │
            │  S3 Access   │   │              │
            │              │   │  Policy:     │
            │              │   │  Public Read │
            └──────────────┘   └──────────────┘
```

## Component Details

### Frontend Layer

**Web Browser**
- **Technology**: HTML5, CSS3, JavaScript (ES6+)
- **Responsibilities**:
  - User interface rendering
  - Form validation
  - Client-side data management
  - Image upload handling
  - AWS SDK integration

**LocalStorage**
- **Purpose**: Store clothing metadata
- **Data Stored**:
  - Item details (name, brand, category, color)
  - Wear counts and wash status
  - Care instructions
  - S3 image URLs (not the images themselves)
- **Limitations**: 
  - Tied to specific IP/domain
  - ~5-10MB capacity
  - Cleared if browser cache is cleared

**AWS SDK for JavaScript**
- **Version**: 2.1552.0
- **Purpose**: Client-side S3 integration
- **Methods Used**:
  - `s3.upload()` - Upload images to S3
  - Handles authentication via access keys
  - Manages CORS requests

### Infrastructure Layer

**AWS EC2 (Elastic Compute Cloud)**
- **Instance Type**: t2.micro (1 vCPU, 1GB RAM)
- **Operating System**: Amazon Linux 2023
- **Purpose**: Web server hosting
- **Configuration**:
  - Public IP address for internet access
  - Security group for network access control
  - 8GB gp3 EBS volume for storage

**Nginx Web Server**
- **Version**: Latest from Amazon Linux repos
- **Port**: 80 (HTTP)
- **Purpose**: Serve static HTML/CSS/JS files
- **Configuration**:
  - Default document root: `/usr/share/nginx/html/`
  - Single page application (index.html)
  - No backend processing required

### Storage Layer

**AWS S3 (Simple Storage Service)**
- **Bucket Purpose**: Store user-uploaded clothing images
- **Access Control**:
  - Bucket Policy: Public read access
  - ACLs: Disabled (recommended by AWS)
  - CORS: Configured for cross-origin uploads
- **File Naming**: Timestamp-based unique identifiers
- **Benefits**:
  - Unlimited scalability
  - 99.999999999% durability
  - Pay-per-use pricing (~$0.023/GB/month)

### Security Layer

**AWS IAM (Identity and Access Management)**
- **IAM User**: `clothes-app-s3-user`
- **Permissions**: S3 upload/read access
- **Access Keys**: 
  - Programmatic access for JavaScript SDK
  - Embedded in frontend (acceptable for learning project)
  - **Production Note**: Should use backend API with temporary credentials

**Security Groups**
- **Purpose**: Firewall rules for EC2 instance
- **Inbound Rules**:
  - SSH (22): Administrative access
  - HTTP (80): Web traffic
- **Outbound Rules**: All traffic allowed

**S3 Bucket Policy**
- **Effect**: Allow
- **Principal**: * (public)
- **Action**: s3:GetObject (read-only)
- **Resource**: All objects in bucket

## Data Flow

### 1. Adding a New Item with Image

```
User fills form → Clicks "Add Item"
    ↓
JavaScript validates input
    ↓
Image file selected?
    ↓ Yes
AWS SDK prepares upload to S3
    ↓
s3.upload() called with:
  - Bucket name
  - File content
  - IAM credentials
    ↓
S3 returns public URL
    ↓
Item object created:
  - Metadata: name, brand, etc.
  - image: S3 URL
    ↓
Saved to localStorage
    ↓
UI updates: Item appears in inventory
```

### 2. Daily Wear Logging

```
User checks items worn → Clicks "Log Today's Wear"
    ↓
JavaScript loops through checked items
    ↓
For each item:
  - Increment timesWorn
  - Increment wearsSinceWash
    ↓
Update localStorage
    ↓
Uncheck all boxes
```

### 3. Viewing Inventory

```
User clicks "Inventory" tab
    ↓
JavaScript reads from localStorage
    ↓
For each item:
  - Calculate days since wash
  - Check if needs washing
    ↓
Generate HTML for each item
    ↓
Load images from S3 URLs
    ↓
Display in grid layout
```

## Design Decisions

### Why Not a Traditional Backend?

**Pros of Serverless Frontend:**
- Simpler deployment (single EC2 instance)
- Lower cost (no backend servers)
- Easier to learn and understand
- Sufficient for single-user application

**Cons:**
- LocalStorage limited to one device/IP
- Credentials exposed in frontend
- No user authentication
- Limited scalability

**Production Improvement**: Add Lambda + API Gateway + DynamoDB for multi-user support.

### Why LocalStorage + S3 Hybrid?

**LocalStorage for Metadata:**
- Fast access (no network calls)
- Small data size (JSON)
- Suitable for item properties

**S3 for Images:**
- Avoids localStorage quota
- Scalable storage
- CDN-ready
- Professional cloud architecture

### Why Nginx?

**Alternatives Considered:**
- **Apache**: Heavier, more complex
- **Node.js/Express**: Overkill for static content
- **S3 Static Hosting**: Loses server management learning

**Nginx Chosen Because:**
- Lightweight and efficient
- Industry standard
- Simple configuration
- Good learning experience

## Security Considerations

### Current Implementation (Learning Project)

✅ **Good:**
- IAM user with limited permissions
- Security groups properly configured
- S3 bucket policy restricts to read-only
- HTTPS not required (no sensitive data)

⚠️ **Acceptable for Learning:**
- Credentials in frontend code
- No user authentication
- Public S3 bucket

### Production Recommendations

🔒 **Must Have:**
1. **Backend API**: Lambda + API Gateway
2. **Authentication**: AWS Cognito
3. **Temporary Credentials**: AWS STS
4. **HTTPS**: SSL certificate (Let's Encrypt)
5. **Private S3 Bucket**: Pre-signed URLs for access
6. **Database**: DynamoDB for user data
7. **WAF**: Rate limiting and DDoS protection

## Scalability Analysis

### Current Limits

**Single User:**
- ✅ Works perfectly
- ✅ Low cost
- ✅ Simple maintenance

**Multiple Users:**
- ❌ LocalStorage not shared
- ❌ No authentication
- ❌ No data isolation

### Scaling to Production

**10-100 Users:**
- Add DynamoDB for shared data
- Implement Cognito authentication
- Keep single EC2 instance

**100-1000 Users:**
- Add Application Load Balancer
- Auto Scaling Group (2-4 instances)
- CloudFront CDN for S3 images

**1000+ Users:**
- Migrate to serverless (Lambda)
- API Gateway for backend
- DynamoDB with auto-scaling
- CloudFront for entire application

## Cost Analysis

### Current Monthly Costs

| Service | Usage | Cost |
|---------|-------|------|
| EC2 t2.micro | 750 hrs (free tier) | $0.00 |
| S3 Storage | ~0.1 GB (100 photos) | $0.00 |
| S3 Requests | ~100 PUTs | $0.00 |
| Data Transfer | < 1 GB | $0.00 |
| **Total** | | **~$0.00** |

**After Free Tier (12 months):**
- EC2: ~$8.50/month
- S3: ~$0.02/month
- **Total: ~$8.52/month**

### Production Costs (1000 users)

| Service | Usage | Cost |
|---------|-------|------|
| Lambda | 1M requests | $0.20 |
| API Gateway | 1M requests | $3.50 |
| DynamoDB | 25GB + 1M writes | $6.88 |
| S3 | 25GB + 1M requests | $0.58 |
| CloudFront | 100GB transfer | $8.50 |
| **Total** | | **~$19.66** |

## Monitoring and Observability

### Current Capabilities

**Browser Console:**
- JavaScript errors
- Network requests
- S3 upload status

**EC2 Metrics** (CloudWatch):
- CPU utilization
- Network traffic
- Disk usage

**S3 Metrics**:
- Request count
- Error rate
- Storage size

### Production Recommendations

- **CloudWatch Logs**: Application logging
- **CloudWatch Alarms**: Automated alerts
- **X-Ray**: Distributed tracing
- **CloudTrail**: API call auditing

## Future Architecture Evolution

### Phase 1: Multi-Device Support
- Add DynamoDB table
- Implement sync mechanism
- Keep current frontend

### Phase 2: Multi-User Support
- Add Cognito authentication
- User-specific data isolation
- Sharing capabilities

### Phase 3: Full Serverless
- Migrate to Lambda functions
- API Gateway for routing
- Remove EC2 dependency

### Phase 4: Mobile Apps
- React Native mobile app
- Shared backend with web app
- Push notifications for laundry reminders

---

This architecture demonstrates foundational AWS concepts while remaining simple enough for learning and iteration.
