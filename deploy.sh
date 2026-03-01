#!/bin/bash

# Clothes Inventory App - Quick Deploy Script
# This script uploads the application to your EC2 instance

# Configuration - UPDATE THESE VALUES
EC2_IP="YOUR-EC2-PUBLIC-IP"
KEY_FILE="path/to/your-key.pem"
APP_FILE="app/index.html"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Clothes Inventory Deployment Script${NC}"
echo "======================================"

# Check if key file exists
if [ ! -f "$KEY_FILE" ]; then
    echo -e "${RED}Error: Key file not found at $KEY_FILE${NC}"
    echo "Please update KEY_FILE in this script"
    exit 1
fi

# Check if app file exists
if [ ! -f "$APP_FILE" ]; then
    echo -e "${RED}Error: Application file not found at $APP_FILE${NC}"
    exit 1
fi

# Check if credentials are configured
if grep -q "YOUR_ACCESS_KEY_ID_HERE" "$APP_FILE"; then
    echo -e "${RED}Error: AWS credentials not configured in $APP_FILE${NC}"
    echo "Please update the S3_CONFIG section with your actual credentials"
    exit 1
fi

echo -e "${YELLOW}Uploading application to EC2...${NC}"

# Upload to /tmp on EC2
scp -i "$KEY_FILE" "$APP_FILE" ec2-user@$EC2_IP:/tmp/index.html

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to upload file${NC}"
    exit 1
fi

echo -e "${GREEN}Upload successful!${NC}"
echo -e "${YELLOW}Moving file to nginx directory...${NC}"

# SSH in and move file to nginx directory
ssh -i "$KEY_FILE" ec2-user@$EC2_IP << 'EOF'
    sudo cp /tmp/index.html /usr/share/nginx/html/index.html
    echo "File deployed successfully!"
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Deployment complete!${NC}"
    echo -e "Visit: ${GREEN}http://$EC2_IP${NC}"
else
    echo -e "${RED}Error: Failed to move file on server${NC}"
    exit 1
fi
