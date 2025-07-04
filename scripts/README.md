# Scripts Directory

This directory contains modular installation scripts created by the v5.0 deployment system.

## Scripts Created by `./deploy.sh setup`:

- **common.sh** - Shared functions and utilities
- **install-collections.sh** - Install enhanced newsletter collections
- **install-frontend.sh** - Install frontend integration
- **install-flow.sh** - Install Directus automation flow
- **debug-installation.sh** - Comprehensive debugging tools

## Usage:

The scripts are automatically created when you run:

```bash
./deploy.sh setup
```

After setup, you can use individual scripts:

```bash
# Install collections only
./scripts/install-collections.sh https://directus.com admin@example.com password

# Install frontend integration
./scripts/install-frontend.sh /path/to/nuxt/project

# Debug complete installation
./scripts/debug-installation.sh https://directus.com admin@example.com password
```

## Modular Architecture Benefits:

- **Individual testing** of each component
- **Easy debugging** with isolated scripts
- **Selective installation** based on needs
- **Better error isolation** and recovery

For complete documentation, see the main [README.md](../README.md) and [docs/INSTALLATION.md](../docs/INSTALLATION.md).