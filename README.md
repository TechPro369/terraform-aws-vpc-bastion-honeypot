# AWS VPC + Bastion + Honeypot Foundation (Terraform)

Production-style AWS network foundation deployed entirely as Infrastructure-as-Code — a reusable, auditable, least-privilege base for cybersecurity projects.

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5.0-7B42BC?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS Provider](https://img.shields.io/badge/AWS-Provider%205.x-FF9900?logo=amazon-aws&logoColor=white)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)

---

## Overview

This Terraform module provisions a secure, multi-AZ AWS network suitable for hosting honeypots, SIEM feeds, and serverless threat-detection workloads. It replaces click-through AWS console setup with a reproducible, auditable baseline that tears down cleanly with a single `terraform destroy`.

### What it provisions

- **VPC** across 2 Availability Zones with public and private subnets
- **Internet Gateway** for public subnet egress
- **NAT Gateway** for outbound-only traffic from private subnets
- **Bastion host** (EC2 t3.micro, Amazon Linux 2023) in public subnet — SSH + SSM Session Manager access
- **Private EC2** reachable only via the bastion's security group
- **Encrypted, versioned S3 bucket** for honeypot log ingestion (AES-256, Glacier lifecycle)
- **SNS topic** with email subscription for security alerts
- **IAM role scaffolded** for a future Lambda-based CloudTrail threat detector

### Why this exists

Every cybersecurity project in my portfolio (honeypot deployment, log forwarding, threat detection) needs the same network foundation. Rebuilding it by hand in the console each time was error-prone and non-reproducible. This module bakes it into code and becomes the shared starting point.

---

## Architecture

```
                              ┌── AWS ──┐
                              │         │
                              ▼         ▼
                         ┌───────────────────┐
                         │  Internet Gateway │
                         └─────────┬─────────┘
                                   │
      ┌────────────────── VPC (10.0.0.0/16) ──────────────────┐
      │                            │                          │
      │   ┌─── AZ-a ────────┐      │       ┌─── AZ-b ────┐   │
      │   │  Public subnet   │◀────┘       │  Public     │   │
      │   │  10.0.1.0/24     │             │  10.0.2.0/24│   │
      │   │  ┌────────────┐  │             │             │   │
      │   │  │  Bastion   │──┼──NAT GW────▶│             │   │
      │   │  │  (SSH+SSM) │  │  (EIP)      │             │   │
      │   │  └─────┬──────┘  │             │             │   │
      │   └────────┼─────────┘             └─────────────┘   │
      │            │                                          │
      │     SSH from bastion SG only                          │
      │            ▼                                          │
      │   ┌───────────────────┐          ┌────────────────┐  │
      │   │  Private subnet   │          │ Private subnet │  │
      │   │  10.0.11.0/24     │          │  10.0.12.0/24  │  │
      │   │  ┌─────────────┐  │          │                │  │
      │   │  │ Private EC2 │  │          │                │  │
      │   │  └─────────────┘  │          │                │  │
      │   └───────────────────┘          └────────────────┘  │
      │                                                       │
      └───────────────────────────────────────────────────────┘

       ┌──────────────────┐   ┌──────────────┐   ┌──────────────────┐
       │ S3 (honeypot     │   │ SNS topic    │   │ IAM role for     │
       │ logs, encrypted, │   │ → email      │   │ future CloudTrail│
       │ versioned)       │   │ subscription │   │ threat detector  │
       └──────────────────┘   └──────────────┘   └──────────────────┘
```

---

## Repository structure

```
terraform-aws-vpc-bastion-honeypot/
├── README.md                   # You are here
├── LICENSE                     # MIT
├── .gitignore                  # Keeps state & secrets out of Git
├── versions.tf                 # Terraform + provider version pins
├── providers.tf                # AWS provider with default tags
├── variables.tf                # Input variables
├── outputs.tf                  # Useful outputs for chaining
├── terraform.tfvars.example    # Copy → terraform.tfvars, fill in values
├── vpc.tf                      # VPC, subnets, IGW, NAT, routes, AMI lookup
├── bastion.tf                  # Bastion EC2, SG, SSM IAM role
├── private.tf                  # Private EC2 + SG
├── s3.tf                       # Honeypot log bucket (encrypted, versioned)
├── sns.tf                      # Security-alerts SNS topic + subscription
└── iam.tf                      # IAM role scaffolded for future detector
```

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) **>= 1.5.0**
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured with credentials that can create VPCs, EC2, S3, IAM, and SNS resources
- An **existing EC2 key pair** in your target region ([how to create one](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html))
- An email address where you can confirm an SNS subscription

---

## Deploy

### 1. Clone

```bash
git clone https://github.com/TechPro369/terraform-aws-vpc-bastion-honeypot.git
cd terraform-aws-vpc-bastion-honeypot
```

### 2. Configure your variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set at minimum:

| Variable | What to set it to |
|---|---|
| `allowed_ssh_cidr` | Your public IP in CIDR format, e.g. `203.0.113.5/32` |
| `key_pair_name` | Name of your existing EC2 key pair |
| `alert_email` | Where you want security alerts delivered |

> ⚠️ `terraform.tfvars` is gitignored. Never commit real values.

### 3. Initialize and deploy

```bash
terraform init
terraform plan
terraform apply
```

Review the plan output before typing `yes` at the apply prompt.

### 4. Confirm the SNS email subscription

Check the inbox for the address you set in `alert_email`. AWS sends a confirmation email — **click the "Confirm subscription" link** or no alerts will be delivered.

---

## Connect to the hosts

### SSH to the bastion

```bash
ssh -i ~/.ssh/your-key.pem ec2-user@$(terraform output -raw bastion_public_ip)
```

### Via SSM Session Manager (no SSH key or open port needed)

```bash
aws ssm start-session --target $(terraform output -raw bastion_instance_id)
```

### From bastion to private EC2

Once you're on the bastion:

```bash
# Copy your key to the bastion first (from your local machine):
scp -i ~/.ssh/your-key.pem ~/.ssh/your-key.pem ec2-user@<bastion-ip>:~/.ssh/

# Then from the bastion:
ssh -i ~/.ssh/your-key.pem ec2-user@<private-ec2-private-ip>
```

---

## Outputs

After a successful `terraform apply`, these outputs are available:

| Output | Description |
|---|---|
| `vpc_id` | ID of the created VPC |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `bastion_public_ip` | Public IP of the bastion (for SSH) |
| `bastion_instance_id` | Bastion instance ID (for SSM) |
| `private_instance_id` | Private EC2 instance ID |
| `private_instance_private_ip` | Private EC2 private IP |
| `honeypot_logs_bucket` | S3 bucket name for honeypot logs |
| `security_alerts_topic_arn` | SNS topic ARN for security alerts |
| `threat_detector_role_arn` | IAM role ARN scaffolded for future Lambda detector |

Retrieve an individual output with:

```bash
terraform output bastion_public_ip
```

---

## Teardown

```bash
terraform destroy
```

This tears down every resource created by the module, including the NAT Gateway.

---

## ⚠️ Cost warning

Leaving this stack running costs approximately:

| Resource | Approx. monthly cost |
|---|---|
| NAT Gateway | **~$32** (the big one — billed hourly) |
| Elastic IP (attached to NAT) | free while attached |
| 2× t3.micro EC2 | ~$15 (or free for 12 mo on free tier) |
| S3 storage | pennies |
| SNS | pennies |

**Always run `terraform destroy` when you're done experimenting.** Set a billing alarm in CloudWatch (`$5` or `$10` threshold) as a safety net.

---

## Security notes

- **All EBS volumes are encrypted** (AES-256, AWS-managed keys)
- **S3 bucket** has Block Public Access, versioning, and server-side encryption enabled
- **IMDSv2 is enforced** on all EC2 instances (mitigates SSRF → credential theft)
- **Bastion SG** restricts SSH ingress to a single CIDR (set via `allowed_ssh_cidr`)
- **Private EC2 SG** only allows ingress from the bastion SG — it is not reachable from the internet
- **IAM roles** follow least-privilege scoping; the future-detector role is limited to specific CloudTrail, SNS, and S3 actions
- **SSM Session Manager** is available on the bastion — you can avoid opening port 22 entirely by using `aws ssm start-session`

**Before you apply**, replace the default `allowed_ssh_cidr = "0.0.0.0/0"` with your actual IP in `/32` form.

---

## Roadmap

- [ ] Deploy the actual Lambda that consumes the scaffolded `threat_detector_role_arn` and monitors CloudTrail for suspicious API patterns
- [ ] Add VPC Flow Logs → CloudWatch for forensic analysis
- [ ] Integrate AWS GuardDuty and route findings into the `security_alerts` SNS topic
- [ ] Add a second EC2 as a public-subnet honeypot (Cowrie / T-Pot) writing logs to the honeypot S3 bucket
- [ ] Remote backend (S3 + DynamoDB) for state, instead of local state
- [ ] Ship as a proper Terraform module with a `modules/` directory and a `examples/` consumer

---

## License

MIT — see [LICENSE](./LICENSE).

---

## Author

**Biruk Aregu** — Technology Analyst @ Accenture Federal Services
Cybersecurity · Cloud · AI Tooling

🌐 [birukaregu.com](https://www.birukaregu.com) · 💻 [github.com/TechPro369](https://github.com/TechPro369)
