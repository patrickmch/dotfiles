---
name: browser-isolation
description: Set up or use isolated browser automation profiles so agents do not share cookies, tabs, ports, or authenticated sessions. Use when a project needs browser automation, persistent login state, or concurrent agents that must not hijack each other's browser sessions.
---

# Browser Isolation

Use isolated browser profiles for project automation. The neutral concept is: one project gets one browser state directory, one gateway/profile name, one port if needed, and explicit instructions in the project docs.

## Principles

- Never let unrelated agents share an authenticated browser session when they may navigate, click, or log in.
- Keep project cookies and browser data scoped to the project profile.
- Document the profile name, state path, gateway port, and command prefix in the project instructions.
- Prefer runtime-native browser tooling when available; use the local OpenClaw implementation only on machines where it is installed.

## Generic Setup Checklist

1. Inventory existing profiles and ports.
2. Pick a short lowercase profile name tied to the project.
3. Allocate an unused browser state directory and, if applicable, an unused loopback port.
4. Start or configure the browser automation gateway for that profile.
5. Verify navigation, snapshot/screenshot, and login persistence.
6. Add project instructions that require this profile for browser work.

## Local OpenClaw Implementation

Current local convention starts ports at 18790 and keeps the shared/default gateway separate.

```bash
# Existing profile/port inventory
ls -d ~/.openclaw-*/ 2>/dev/null
grep -r '"port"' ~/.openclaw*/openclaw.json ~/.openclaw/openclaw.json 2>/dev/null
```

Suggested config shape for `~/.openclaw-<profile>/openclaw.json`:

```json
{
  "browser": {
    "headless": false,
    "defaultProfile": "openclaw"
  },
  "gateway": {
    "port": 18790,
    "mode": "local",
    "bind": "loopback",
    "auth": {
      "mode": "token",
      "token": "<profile>-agent-token"
    }
  }
}
```

Use headed mode when the human may need to complete CAPTCHAs or logins over Screen Sharing. Use loopback binding unless there is a reviewed reason to expose the gateway.

## Project Instruction Snippet

```markdown
- Browser automation: use the isolated browser profile `<profile>`. All browser commands must use the project-specific profile/port/state. Do not use the shared default browser gateway for this project.
```

## Verification

- Navigate to a harmless page.
- Capture a snapshot or screenshot.
- Restart the gateway and confirm cookies/session state persist when persistence is required.
- Confirm another project profile is unaffected.
