# Automated Apache Druid Single-Node Deployment

[![Infrastructure](https://img.shields.io/badge/Infrastructure-AWS-orange)]()
[![Terraform](https://img.shields.io/badge/Terraform-1.0%2B-blue)]()
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)]()

A production-grade infrastructure automation tool for deploying Apache Druid in a single-node configuration on AWS. This project simplifies the process of setting up a Druid environment for testing, development, and proof-of-concept purposes.

## 🚀 Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd druid-single-node-deployment

# Make the deployment script executable
chmod +x deploy.sh

# Run the deployment
./deploy.sh
```

## 🎯 Features

- **One-Command Deployment**: Fully automated setup of Druid and all dependencies
- **Infrastructure as Code**: AWS infrastructure managed through Terraform
- **Secure by Default**: Proper security group configurations and key pair management
- **Cost-Efficient**: Single node setup perfect for testing and development
- **PoC-Ready**: Includes all necessary components:
  - Apache ZooKeeper
  - MySQL for metadata storage
  - Imply Manager for cluster management
  - Proper security configurations
  - Automated dependency installation

## 🏗️ Prerequisites

- AWS CLI installed and configured
- Terraform v1.0 or later
- curl
- jq
- AWS account with appropriate permissions
- SSH key pair in your target AWS region

## 📁 Project Structure

```
druid-single-node-deployment/
├── LICENSE.txt
├── README.md
├── keys
│   └── your_aws_keys.pem
└── terraform
    ├── deploy.sh
    ├── destroy.sh
    ├── install_dependencies.sh
    ├── main.tf
```

## 🔧 Configuration Options

During deployment, you'll be prompted for:

- AWS Region
- Instance Type (default: t2.xlarge)
- VPC and Security Group selection
- Storage size (default: 50GB)
- SSH key pair selection
- Instance naming and tagging

## 🚀 Deployment Process

1. **Infrastructure Setup**:
   ```bash
   ./deploy.sh
   ```
   Follow the interactive prompts to configure your deployment.

2. **Accessing Your Cluster**:
   - Imply Manager UI: `http://<public-ip>:9097`
   - Druid Console: `http://<public-ip>:8888`
   - SSH Access: `ssh -i keys/<your-key>.pem ubuntu@<public-ip>`

3. **Cleanup**:
   ```bash
   ./destroy.sh
   ```

## 💡 Component Details

### Installed Software
- Java OpenJDK 17
- Python 3
- MySQL Server
- ZooKeeper 3.8.4
- Imply Manager 2024.09
- Imply Agent v7

### Default Ports
- Druid Console: 8888
- Imply Manager: 9097
- ZooKeeper: 2181
- MySQL: 3306

## 🔐 Security

- Instance launched with security group allowing only necessary ports
- SSH access limited to deployment host IP
- All sensitive data (passwords, keys) properly managed
- Root volume encryption enabled
- MySQL secured with custom credentials

## 🔍 Monitoring and Management

Access the Imply Manager UI for:
- Cluster health monitoring
- Performance metrics
- Configuration management
- Node status
- Query management

## 📝 Common Operations

### Starting Services
Services are automatically started during deployment. If needed manually:
```bash
sudo systemctl start mysql
sudo systemctl start imply-manager
sudo systemctl start imply-agent
```

### Checking Service Status
```bash
sudo systemctl status mysql
sudo systemctl status imply-manager
sudo systemctl status imply-agent
```

### Accessing Logs
```bash
# Imply Manager logs
sudo journalctl -u imply-manager

# Imply Agent logs
sudo journalctl -u imply-agent
```

## 🚨 Troubleshooting

Common issues and solutions:

1. **Connection Timeout**
   - Check security group rules
   - Verify instance is running
   - Confirm VPC settings

2. **Service Start Failure**
   - Check system logs: `journalctl -xe`
   - Verify all dependencies are installed
   - Check disk space: `df -h`

3. **Permission Issues**
   - Verify key pair permissions: `chmod 400 keys/<your-key>.pem`
   - Check service user permissions
   - Review AWS IAM roles

## ⚠️ Limitations

- Single-node deployment (not for production use)
- Limited to AWS platform
- Fixed software versions
- Basic security configurations

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.

## 📫 Support

For support:
1. Open an issue in the repository
2. Check existing documentation
3. Review common issues in troubleshooting section

## 🙏 Acknowledgments

- Apache Druid Community
- Imply.io Documentation
- AWS Documentation
- Terraform Community

---
*Note: This deployment is intended for testing and development purposes. For production deployments, please refer to the official Apache Druid documentation for multi-node cluster setup.*