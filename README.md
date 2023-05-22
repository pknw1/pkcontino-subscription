# pkcontino-subscription

| Deployments | Automation |
| ----------- | ---------- |
| ✅ Single Click Environment Deployment         | ⌛️ automated, timed un-deployment|
| ✅ Ubuntu 22.04, Windows 11 Bare OS Selections | ⌛️ resource groups tagged with over-ridable expiry|
| ✅ Python 3.10 on Ubuntu                       | ⌛️ hourly scans for expired rg|


## [Deploy | Destroy] Azure Environment

- manual workflow action to select an OS choice
- user selected expiry in days (default 1 day)
- terraform apply to deploy the selected OS
  - resource group is tagged with tag `expires` and set to `X days` in the future 
- scheduled recurring workflow runs and checks for expires tag
  - if expires tag value is today, undeploy the OS
