# Server Stats

## Overview
**Server Stats** is a Bash script that provides a snapshot of key system information, such as uptime, installed software versions, resource usage, logged-in users, and running services.

## Features
- Displays system time and uptime.
- Show installed OS and kernel.
- Shows installed software versions (Nginx, Apache, PHP, MariaDB, MySQL, Node.js, Redis, MongoDB, and more).
- Notifies about system updates and security patches.
- Shows logged-in users and their active sessions.
- Displays open public network ports.
- Displays network traffic.
- Reports CPU and memory usage, including per-core utilization.
- Reports disk space usage.
- Lists top 10 memory and CPU-consuming processes.
- Ability to turn features on/off.

## Requirements
The script requires mpstat from sysstat to be installed to fetch CPU info.
```bash
sudo apt install sysstat  # For Debian/Ubuntu
sudo dnf install sysstat  # For Fedora
sudo yum install sysstat  # For CentOS/RHEL
```

## Usage
1. **Set up configuration file**:
   - Copy the example config file:
   ```bash
   cp server-stats.conf.example server-stats.conf
   ```  
2. **Make the script executable**:
   ```bash
   chmod +x server-stats.sh
   ```
3. **Run the script**:
   ```bash
   ./server-stats.sh
   ```

## Configuration
Edit server-stats.conf and set variables to 'on' to enable features, or leave them empty to disable. Example:

```bash
   TIME=on   #Feature is turned on.
   TIME=     #Feature is turned off.
```

## Automatically Execute on SSH Login
If you want the script to run automatically every time you log in via SSH, follow these steps:

1. Open your shell profile file in a text editor:
   ```bash
   nano ~/.bashrc
   ```
   Or if you use `zsh`:
   ```bash
   nano ~/.zshrc
   ```
2. Add the following line at the end of the file (replace the path with your actual path):
   ```bash
   ~/scripts/server-stats/server-stats.sh
   ```
3. Save and exit (in nano: press `CTRL + X`, then `Y`, then `Enter`).

4. Apply the changes:
   ```bash
   source ~/.bashrc
   ```

Now, the script will execute automatically each time you log in via SSH.

## Important Notes
- All data reported is a snapshot in time and not updated in real-time.

## Enjoying This Script?
**If you found this script useful, a small tip is appreciated ❤️**  
[https://buymeacoffee.com/paulsorensen](https://buymeacoffee.com/paulsorensen)

## License
This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3 of the License.

**Legal Notice:** If you edit and redistribute this code, you must mention the original author, **Paul Sørensen** ([paulsorensen.io](https://paulsorensen.io)), in the redistributed code or documentation.

**Copyright (C) 2025 Paul Sørensen ([paulsorensen.io](https://paulsorensen.io))**

See the LICENSE file in this repository for the full text of the GNU General Public License v3.0, or visit [https://www.gnu.org/licenses/gpl-3.0.txt](https://www.gnu.org/licenses/gpl-3.0.txt).