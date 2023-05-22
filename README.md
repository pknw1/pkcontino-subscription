# pkcontino-subscription

| Deployments | Automation |
| ----------- | ---------- |
| ✅ Single Click Environment Deployment         | ⌛️ automated, timed un-deployment|
| ✅ Ubuntu 22.04, Windows 11 Bare OS Selections | ⌛️ resource groups tagged with over-ridable expiry|
| ✅ Python 3.10 on Ubuntu                       | ⌛️ hourly scans for expired rg|

## Environment Deployment & Control

- Choose Actions
- Choose Environment Actions
- Click "Run WorkFlow" button
  - Branch              : Main
  - Choose Action       : [plan|apply|destroy]
  - Choose Environment  : [ubuntu2204|ubuntu2204python|win11]
  - Auto-Expire (Days)  : [1|2|3|4|5]

  
## Automated Expired Un-Deployment