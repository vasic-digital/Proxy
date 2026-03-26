# AGENTS.md

Guidelines for AI coding agents working in this repository.

## Project Overview

This is a Bash/Docker/Podman-based project. Scripts manage containerized workloads and infrastructure automation.

## Build/Run/Test Commands

### Shell Scripts

```bash
# Lint all shell scripts
shellcheck scripts/*.sh

# Lint a single file
shellcheck scripts/proxy.sh

# Format shell scripts (requires shfmt)
shfmt -w scripts/*.sh

# Run a script
./scripts/proxy.sh [args]

# Test with bats (if tests exist)
bats test/*.bats

# Run a single test file
bats test/proxy.bats

# Run specific test by name
bats -f "test name pattern" test/proxy.bats
```

### Docker

```bash
# Build image
docker build -t proxy:latest .

# Build with no cache
docker build --no-cache -t proxy:latest .

# Run container
docker run -d --name proxy proxy:latest

# View logs
docker logs -f proxy

# Stop and remove
docker stop proxy && docker rm proxy

# Compose up
docker compose up -d

# Compose down
docker compose down

# Execute in container
docker exec -it proxy /bin/sh
```

### Podman

```bash
# Build image
podman build -t proxy:latest .

# Run container
podman run -d --name proxy proxy:latest

# Podman compose (if available)
podman-compose up -d

# Pod operations
podman pod create --name proxy-pod
podman pod start proxy-pod
podman pod stop proxy-pod
```

## Code Style Guidelines

### Shell Scripts (Bash)

```bash
#!/usr/bin/env bash
# Always use bash with env for portability

set -euo pipefail
# -e: Exit on error
# -u: Error on undefined variables
# -o pipefail: Pipeline fails on first error

# Script metadata as comments at top
# Description: What this script does
# Usage: ./script.sh [args]

#######################################
# Function description
# Globals:
#   VAR_NAME - description
# Arguments:
#   $1 - first arg description
# Outputs:
#   Writes to stdout
# Returns:
#   0 on success, non-zero on failure
#######################################
function_name() {
    local var="$1"
    
    # Prefer [[ ]] over [ ]
    if [[ -n "$var" ]]; then
        echo "$var"
    fi
}

# Main entry point
main() {
    function_name "$@"
}

main "$@"
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Variables | snake_case | `container_name` |
| Constants | UPPER_SNAKE | `MAX_RETRIES` |
| Functions | snake_case | `build_image()` |
| Scripts | kebab-case | `start-proxy.sh` |
| Directories | lowercase | `scripts/`, `config/` |

### Variable Declarations

```bash
# Always quote variables
local name="$1"
local path="${HOME}/config"

# Readonly for constants
readonly DEFAULT_PORT=8080
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Arrays
local containers=("web" "api" "db")
local -A config=(["host"]="localhost" ["port"]="8080")
```

### Error Handling

```bash
# Exit with meaningful codes
exit 1   # General error
exit 2   # Misuse of command
exit 126 # Command not executable
exit 127 # Command not found

# Error function
error() {
    echo "[ERROR] $1" >&2
    exit "${2:-1}"
}

# Trap for cleanup
cleanup() {
    docker stop "$container" 2>/dev/null || true
}
trap cleanup EXIT
```

### Dockerfile Style

```dockerfile
# syntax=docker/dockerfile:1

# Use specific versions, not :latest
FROM alpine:3.19

# Labels for metadata
LABEL maintainer="team@example.com"
LABEL version="1.0"
LABEL description="Proxy service"

# Combine RUN commands to reduce layers
RUN apk add --no-cache \
    curl \
    bash \
    && rm -rf /var/cache/apk/*

# Use COPY over ADD
COPY scripts/ /app/scripts/

# Non-root user when possible
RUN adduser -D appuser
USER appuser

# Explicit entrypoint and cmd
ENTRYPOINT ["/app/scripts/entrypoint.sh"]
CMD ["--help"]
```

### Docker Compose Style

```yaml
version: "3.8"

services:
  proxy:
    build:
      context: .
      dockerfile: Dockerfile
    image: proxy:latest
    container_name: proxy
    restart: unless-stopped
    environment:
      - LOG_LEVEL=info
    volumes:
      - ./config:/config:ro
    ports:
      - "8080:8080"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - proxy-net

networks:
  proxy-net:
    driver: bridge
```

## Project Structure

```
.
├── scripts/           # Shell scripts
│   ├── build.sh       # Build script
│   ├── deploy.sh      # Deploy script
│   └── utils.sh       # Shared functions
├── config/            # Configuration files
├── docker/            # Docker-related files
│   ├── Dockerfile
│   └── docker-compose.yml
├── test/              # Test files (*.bats)
├── .env.example       # Environment template
└── Makefile           # Common commands
```

## Best Practices

1. **Scripts**: Always include `set -euo pipefail` and a usage function
2. **Docker**: Use multi-stage builds for smaller images
3. **Security**: Never hardcode secrets; use environment variables
4. **Logging**: Use structured logging with timestamps
5. **Idempotency**: Scripts should be safe to run multiple times
6. **Documentation**: Comment complex logic; document exit codes

## Common Patterns

```bash
# Check dependencies
command -v docker >/dev/null 2>&1 || error "docker is required"
command -v podman >/dev/null 2>&1 || error "podman is required"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        -v|--verbose) VERBOSE=1; shift ;;
        *) error "Unknown option: $1" ;;
    esac
done

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    error "Do not run as root"
fi

# Retry logic
retry() {
    local max="$1"
    local cmd="${@:2}"
    local n=0
    until "$cmd"; do
        ((n++))
        [[ $n -ge $max ]] && error "Failed after $max attempts"
        sleep 2
    done
}
```
