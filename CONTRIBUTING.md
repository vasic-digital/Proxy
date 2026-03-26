# Contributing to Proxy Service

Thank you for your interest in contributing to the Proxy Service project!

## How to Contribute

### Reporting Issues

1. Check existing issues to avoid duplicates
2. Use the issue template
3. Include:
   - Description of the issue
   - Steps to reproduce
   - Expected behavior
   - Actual behavior
   - Environment details (OS, container runtime)
   - Relevant logs

### Submitting Changes

1. Fork the repository
2. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. Make your changes
4. Test thoroughly:
   ```bash
   ./tests/run-tests.sh
   ```
5. Commit with clear message:
   ```bash
   git commit -m "Add: description of change"
   ```
6. Push to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```
7. Open a Pull Request

### Code Style

#### Shell Scripts

- Use `#!/usr/bin/env bash` shebang
- Include `set -euo pipefail`
- Use snake_case for variables and functions
- Use UPPER_SNAKE for constants
- Document functions with header comments
- Follow patterns in existing scripts

#### Docker Compose

- Use version 3.8
- Include health checks
- Use profiles for optional services
- Document all environment variables

### Testing

Before submitting:
1. Run all tests: `./tests/run-tests.sh`
2. Test with Docker and Podman
3. Test VPN and non-VPN modes
4. Verify documentation is updated

### Documentation

- Update README.md for user-facing changes
- Update docs/ for detailed changes
- Add inline comments for complex code
- Keep AGENTS.md updated for AI guidelines

## Development Setup

```bash
# Clone your fork
git clone git@github.com:YOUR_USERNAME/Proxy.git
cd Proxy

# Copy environment
cp .env.example .env

# Initialize
./init

# Run tests
./tests/run-tests.sh
```

## Project Structure

See README.md for directory structure explanation.

## Questions?

Open an issue for questions or discussions.
