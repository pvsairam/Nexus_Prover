# Nexus_Prover (Nexus Prover Management Tool)

A convenient management tool for Nexus Prover nodes, offering simple installation, operation, and management features. Self-compiled using the latest 0.4.1 source code.

## Features

- Automatically detects and installs dependencies
- Supports AMD64 Linux and ARM64 macOS
- One-click installation and launch of Nexus Prover
- Prover ID management
- Runtime status monitoring
- tmux session management

## Quick Start

```bash
curl -O https://raw.githubusercontent.com/pvsairam/nexus_prover/refs/heads/main/nexus-manager.sh && chmod +x nexus-manager.sh && ./nexus-manager.sh
```

## System Requirements

- Linux (AMD64) or macOS (ARM64)
- APT or YUM package manager (Linux)
- Homebrew (macOS)

## Functional Options

- Install and start Nexus
- Check current runtime status
- View Prover ID
- Set Prover ID
- Stop Nexus
- Exit

## Notes

- On the first run, you will be prompted to enter a Prover ID. If you don’t have one, press Enter to generate one automatically (it's recommended to use the ID from the web interface).
- When checking runtime status, exit using either terminal closure or by pressing Ctrl+B followed by B. Do not use Ctrl+C.
- The program will run in the background automatically, so there’s no need to keep the terminal open.

### About the Author

Twitter: @zerah_eth

### English Translation

Twitter: @og_airdrop

### Related Links

- (Nexus Network)[https://nexus.xyz/]
- (Nexus Beta)[https://beta.nexus.xyz/]
