---
name: browser-profile
description: Create an isolated OpenClaw browser profile for a project so its agents get their own Chrome instance, cookies, and gateway — no conflicts with other agents. Use when setting up browser automation for a new project, or when an agent needs its own browser session.
---

# Isolated Browser Profile Setup

Create a dedicated OpenClaw browser profile so a project's agents get their own Chrome instance, cookies, tabs, and gateway port. Prevents agents from hijacking each other's browser sessions.

## When to Use

- Setting up browser automation for a new project
- An agent needs to stay logged into a service (Clay, LinkedIn, etc.) without other agents navigating away
- Multiple agents will use the browser concurrently
- Eventually: every project should get its own profile by default

## Port Allocation

Check existing profiles before picking a port. Ports are allocated sequentially starting at 18790.

```bash
# See what's already claimed
ls -d ~/.openclaw-*/ 2>/dev/null
# Check which ports are in configs
grep -r '"port"' ~/.openclaw*/openclaw.json ~/.openclaw/openclaw.json 2>/dev/null
```

| Port  | Profile | Project |
|-------|---------|---------|
| 18789 | (main)  | Shared gateway — avoid for project work |
| 18790 | isolated | Anagram |
| 18791+ | (next)  | Allocate sequentially |

**Update this table in the skill when you allocate a new port.**

## Steps

### 1. Create the profile directory and config

Replace `<profile-name>` with a short lowercase identifier (e.g., `mtro`, `crowdsolve`).
Replace `<port>` with the next available port from the table above.

```bash
PROFILE="<profile-name>"
PORT="<port>"

mkdir -p ~/.openclaw-${PROFILE}
cat > ~/.openclaw-${PROFILE}/openclaw.json << EOF
{
  "browser": {
    "headless": false,
    "defaultProfile": "openclaw"
  },
  "gateway": {
    "port": ${PORT},
    "mode": "local",
    "bind": "loopback",
    "auth": {
      "mode": "token",
      "token": "${PROFILE}-agent-token"
    }
  }
}
EOF
```

Key config choices:
- `headless: false` — headed mode so Patrick can Screen Share in for CAPTCHAs/logins
- `defaultProfile: "openclaw"` — persists cookies/sessions across gateway restarts
- `bind: loopback` — only reachable from gc itself

### 2. Start the gateway

```bash
# Start in background (for testing)
openclaw --profile ${PROFILE} gateway run --port ${PORT} &

# Verify it's up
sleep 2
openclaw --profile ${PROFILE} gateway status
```

For persistent operation, create a launchd plist:

```bash
cat > ~/Library/LaunchAgents/ai.openclaw.gateway.${PROFILE}.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>ai.openclaw.gateway.${PROFILE}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/mchey/.openclaw/bin/openclaw</string>
        <string>--profile</string>
        <string>${PROFILE}</string>
        <string>gateway</string>
        <string>run</string>
        <string>--port</string>
        <string>${PORT}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/openclaw-${PROFILE}.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/openclaw-${PROFILE}.err</string>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/ai.openclaw.gateway.${PROFILE}.plist
```

### 3. Verify the browser works

```bash
openclaw --profile ${PROFILE} browser navigate 'https://example.com'
openclaw --profile ${PROFILE} browser screenshot
```

If this is the first launch, a Chrome window will open. For services requiring login (Clay, LinkedIn, etc.), Patrick should Screen Share into gc (`open vnc://100.118.247.22`) to complete the login. Cookies persist in `~/.openclaw-${PROFILE}/browser-data/`.

### 4. Document in the project's CLAUDE.md

Add to the project's `## Workflow Rules` section:

```markdown
- **Browser automation**: Use the **isolated OCP profile** on gc: `openclaw --profile <profile-name> browser ...`. This project has its own Chrome instance, cookies, and gateway (port <port>) — completely separate from the main gateway on 18789. Never use bare `ocp` or `~/bin/ocp` — those hit the shared gateway and other agents can hijack the session.
```

### 5. Update this skill's port table

Edit the Port Allocation table above to register the new profile and port.

## Agent Prompt Instructions

Paste this into agent prompts or project CLAUDE.md so agents know how to use the profile:

```
BROWSER ISOLATION: This project has its own OpenClaw browser profile.
For ALL browser commands, use: openclaw --profile <profile-name> browser ...

Examples:
  openclaw --profile <profile-name> browser navigate 'https://example.com'
  openclaw --profile <profile-name> browser snapshot
  openclaw --profile <profile-name> browser click e13
  openclaw --profile <profile-name> browser type e11 'hello@example.com'
  openclaw --profile <profile-name> browser screenshot

NEVER use bare `ocp` or `~/bin/ocp` — those hit the shared gateway
and other agents can hijack the session.

Your gateway runs on port <port> with its own Chrome instance, cookies,
and tabs — completely separate from other agents.
```

## Troubleshooting

- **Gateway won't start**: Check if the port is already in use: `lsof -ti :<port>`
- **Config invalid**: OpenClaw validates config strictly. Only use documented keys. `userDataDir` is NOT a valid key — `defaultProfile` handles persistence.
- **Browser not launching**: Chrome launches on first browser action, not on gateway start. Run a `navigate` command to trigger it.
- **Lost login session**: If `defaultProfile` was not set when you logged in, the cookies were in a temp dir. Set `defaultProfile: "openclaw"`, restart gateway, and log in again.
- **Gateway restart needed after config change**: `kill $(lsof -ti :<port>) && openclaw --profile <profile-name> gateway run --port <port> &`
