# Simple Swap Setup Script for Linux

## Overview
Swap is an area on a hard drive that has been designated as a place where the operating system can temporarily store data that it can no longer hold in RAM.

**Disclaimer:** This script may not work on every GNU/Linux distro.

---

## 🚀 Usage

### Step 1: Download the Script
First, download the main script using `wget` or `curl`:

**Using wget:**
```bash
wget https://raw.githubusercontent.com/waytohost/Swap/master/swap.sh -O swap
```

**Using curl:**
```bash
curl https://raw.githubusercontent.com/waytohost/Swap/master/swap.sh -o swap
```

### Step 2: Run the Script
Run the script with the following format:

```bash
sh swap <size>
```

**Example (create 4GB swap):**
```bash
sh swap 4G
```

### Step 3: Custom Location (Optional)
The default path for the swap file is `/swapfile`. To change the location, add the file path to the command:

```bash
sh swap 4G /swap
```

**Note:** The specified file must not already exist.

---

## 📋 Examples

### Create 2GB swap file:
```bash
sh swap 2G
```

### Create 1GB swap file at custom location:
```bash
sh swap 1G /mnt/swapfile
```

### Create 8GB swap file:
```bash
sh swap 8G
```

---

## 🔧 Manual Swap Setup (Alternative Method)

If the script doesn't work, you can manually set up swap:

### Step 1: Create Swap File
```bash
# Create 1GB swap file (adjust count for different sizes)
sudo dd if=/dev/zero of=/swapfile bs=1024 count=1048576
```

### Step 2: Set Permissions
```bash
sudo chmod 600 /swapfile
```

### Step 3: Set Up Swap Space
```bash
sudo mkswap /swapfile
```

### Step 4: Enable Swap
```bash
sudo swapon /swapfile
```

### Step 5: Make Permanent
```bash
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

---

## 📊 Verify Swap Setup

### Check Current Swap Usage:
```bash
free -h
```

### Check Swap File Details:
```bash
swapon --show
```

### Check Disk Space:
```bash
df -h
```

---

## 🗑️ Remove Swap File

### Disable Swap:
```bash
sudo swapoff /swapfile
```

### Remove Swap File:
```bash
sudo rm /swapfile
```

### Remove from fstab:
```bash
sudo nano /etc/fstab
```
Remove the line: `/swapfile none swap sw 0 0`

---

## 💡 Recommended Swap Sizes

| RAM Size | Recommended Swap |
|----------|------------------|
| ≤ 2GB | 2x RAM |
| 2GB - 8GB | Equal to RAM |
| 8GB - 64GB | 0.5x RAM |
| ≥ 64GB | 4GB |

**Example:**
- 2GB RAM → 4GB swap
- 4GB RAM → 4GB swap  
- 16GB RAM → 8GB swap
- 64GB RAM → 4GB swap

---

## ⚠️ Important Notes

### Before Creating Swap:
- Ensure you have sufficient disk space
- SSD vs HDD: Swap on SSD is faster but may reduce SSD lifespan
- Consider system requirements and usage patterns

### After Creating Swap:
- Monitor swap usage: `free -h` or `htop`
- High swap usage may indicate insufficient RAM
- Adjust swappiness if needed (default is usually 60)

### Check Swappiness:
```bash
cat /proc/sys/vm/swappiness
```

### Adjust Swappiness (temporary):
```bash
sudo sysctl vm.swappiness=10
```

---

## 🔄 Script Features

The automated script typically handles:
- ✅ Size validation and conversion
- ✅ File creation with proper permissions
- ✅ Swap space initialization
- ✅ Automatic fstab configuration
- ✅ Immediate activation of swap space

---

## 🎯 Summary

### Quick Setup:
```bash
wget https://raw.githubusercontent.com/waytohost/Swap/master/swap.sh -O swap
sh swap 2G
```

### Verification:
```bash
free -h
swapon --show
```

This simple swap setup ensures your Linux system has adequate virtual memory for optimal performance! 🚀
