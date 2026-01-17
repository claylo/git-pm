# git-pm justfile
# https://github.com/casey/just

set shell := ["bash", "-euo", "pipefail", "-c"]

# Default recipe: show available tasks
default:
    @just --list

# Validate script with shellcheck
check:
    shellcheck git-pm

# "Build" the script (inject version, validate, make executable)
build: check
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -f VERSION ]]; then
        version=$(cat VERSION)
        sed "s/(development)/$version/" git-pm > git-pm.tmp
        mv git-pm.tmp git-pm
        echo "Injected version: $version"
    fi
    chmod +x git-pm
    echo "Build complete: git-pm validated and executable"

# Show current version
version:
    @./git-pm --version

# Run the script (for testing)
run *ARGS:
    ./git-pm {{ARGS}}
