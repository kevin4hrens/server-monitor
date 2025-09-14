
# Server Monitor

Lightweight server monitoring script with Zapier integration.
Monitors network, server reboots, disk usage, memory, load average, and sends alerts via a Zapier webhook.
Includes a health check if no alerts occur for 30 days.

## Features

- Network outage detection
- Server reboot detection
- Disk usage warning
- Memory usage warning
- Load average warning
- Health check (alerts every 30 days if no issues)
- Zapier webhook integration (email, Discord, Slack, etc.)
- Lightweight and memory-efficient
- Configurable via `.env`

## Directory Structure

/opt/server-monitor/
├── monitor.sh        # Main script
├── .env.dist         # Template config file
└── .env              # Your personal config (not committed)

## Setup

1. Clone the repository:

```
git clone https://github.com/yourusername/server-monitor.git
cd server-monitor
```

2. Copy `.env.dist` to `.env`:

```
cp .env.dist .env
```

3. Edit `.env` and fill in your Zapier webhook and thresholds:

```
nano .env
```

4. Make script executable:

```
chmod +x monitor.sh
```

## Run

- Manual run:

```
./monitor.sh
```

- Recommended: run automatically using systemd timer.

### Systemd Service

`/etc/systemd/system/monitor.service`:

```
[Unit]
Description=Server Monitor Script
After=network.target

[Service]
Type=simple
ExecStart=/opt/server-monitor/monitor.sh
WorkingDirectory=/opt/server-monitor
Restart=on-failure
```

### Systemd Timer

`/etc/systemd/system/monitor.timer`:

```
[Unit]
Description=Run Server Monitor every 5 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
```

Enable and start:

```
sudo systemctl daemon-reload
sudo systemctl enable --now monitor.timer
sudo systemctl status monitor.timer
```

- Logs available via:

```
journalctl -u monitor.service
```

## Configuration (`.env`)

| Variable          | Description |
|------------------|-------------|
| CHECK_HOST        | IP or hostname to ping for network check |
| ZAPIER_WEBHOOK    | Your Zapier Catch Hook URL |
| DISK_WARN         | Disk usage percent threshold |
| MEM_WARN          | Minimum free memory percent |
| LOAD_WARN         | Load average threshold |

## Zapier Integration

- Script sends JSON payload to Zapier webhook:

```
{
  "date": "2025-09-14",
  "time": "12:00:00",
  "subject": "Network Down",
  "message": "⚠️ myserver: Cannot reach 8.8.8.8",
  "server": "myserver"
}
```

- Zapier can then forward alerts to Email, Discord, Slack, Telegram, SMS, etc.

## Security

- `.env` contains sensitive data (Zapier webhook) → do not commit to Git.
- `.env.dist` is safe to commit.
- Add `.env` to `.gitignore`.

## License

MIT License — free to use and modify.
