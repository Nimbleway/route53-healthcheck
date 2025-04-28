# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands
- No specific build or test commands visible in the codebase
- This is a GitHub Action that runs in a workflow environment

## Code Style
- JavaScript: Standard Node.js style with CommonJS require syntax
- Bash: Use double quotes for variables, add proper error handling
- Add comments for complex logic sections
- Maintain consistent indentation (2 spaces)
- Variable naming: UPPERCASE for environment variables, camelCase for JavaScript variables
- Always check environment variables before use with fallbacks using ${VAR:-default}
- Use proper error handling with set -e in bash scripts
- Add proper quoting around variables in bash to prevent word splitting

## Testing
- No formal testing framework present
- Manual verification through GitHub Action runs

## Notes
- This action creates/updates AWS Route53 health checks for Kubernetes services
- Uses environment variables heavily for configuration
- Works with Kubernetes Ingress and Service resources