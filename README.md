This repo contains my configuration files (dotfiles) for the command line and
editors. My hope is to use Homely (https://github.com/phodge/homely/) to manage
installation and create scripts for easily installing these.

Iterm:
In order to use the Iterm profile stored in this directory, you will need to
follow a few simple instructions.
- Go to preferences -> general
- Click 'Load preferences from a custom folder or URL'
- Load the settings from the dotfiles/iterm directory
- Make sure to click 'Save settings to Folder' so that future changes are made there

Zsh theme:
Mostly, all credits for the configuration go to: https://github.com/tonylambiris/dotfiles

# Remote Development Setup

## Overview
- **M3 MacBook Air (8GB)**: Thin client for coding
- **2014 MacBook Pro (16GB)**: Development server accessed via SSH
- **Tailscale**: VPN for remote access from anywhere
- **tmux + vim**: Remote development environment

## Quick Start
```bash
# At home:
ssh mac-home-local

# Away from home:
ssh mac-home

# Start tmux session:
tmux new -s dev

# Run Claude Code instances
```

## Setup Details
See [DEV_SERVER.md](./DEV_SERVER.md) for full setup instructions.
