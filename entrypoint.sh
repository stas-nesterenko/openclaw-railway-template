#!/bin/bash
set -e

# Ensure /data and OpenClaw state paths are writable by openclaw
mkdir -p /data/.openclaw/identity /data/workspace
chown -R openclaw:openclaw /data 2>/dev/null || true
chmod 700 /data 2>/dev/null || true
chmod 700 /data/.openclaw 2>/dev/null || true
chmod 700 /data/.openclaw/identity 2>/dev/null || true

# Persist Homebrew to Railway volume so it survives container rebuilds
BREW_VOLUME="/data/.linuxbrew"
BREW_SYSTEM="/home/openclaw/.linuxbrew"

if [ -d "$BREW_VOLUME" ]; then
  # Volume already has Homebrew — symlink back to expected location
  if [ ! -L "$BREW_SYSTEM" ]; then
    rm -rf "$BREW_SYSTEM"
    ln -sf "$BREW_VOLUME" "$BREW_SYSTEM"
    echo "[entrypoint] Restored Homebrew from volume symlink"
  fi
else
  # First boot — move Homebrew install to volume for persistence
  if [ -d "$BREW_SYSTEM" ] && [ ! -L "$BREW_SYSTEM" ]; then
    mv "$BREW_SYSTEM" "$BREW_VOLUME"
    ln -sf "$BREW_VOLUME" "$BREW_SYSTEM"
    echo "[entrypoint] Persisted Homebrew to volume on first boot"
  fi
fi

# Persist Claude Code auth/config under /data/secrets so login survives redeploys
mkdir -p /data/secrets/claude
chown -R openclaw:openclaw /data/secrets 2>/dev/null || true
chmod 700 /data/secrets 2>/dev/null || true
chmod 700 /data/secrets/claude 2>/dev/null || true

CLAUDE_HOME_TARGET="/home/openclaw/.claude"
CLAUDE_VOLUME_TARGET="/data/secrets/claude/.claude"

if [ -e "$CLAUDE_HOME_TARGET" ] && [ ! -L "$CLAUDE_HOME_TARGET" ]; then
  mkdir -p /data/secrets/claude
  rm -rf "$CLAUDE_VOLUME_TARGET"
  mv "$CLAUDE_HOME_TARGET" "$CLAUDE_VOLUME_TARGET"
fi

if [ ! -e "$CLAUDE_VOLUME_TARGET" ]; then
  mkdir -p "$CLAUDE_VOLUME_TARGET"
  chown -R openclaw:openclaw /data/secrets/claude 2>/dev/null || true
fi

if [ ! -L "$CLAUDE_HOME_TARGET" ]; then
  rm -rf "$CLAUDE_HOME_TARGET"
  ln -sf "$CLAUDE_VOLUME_TARGET" "$CLAUDE_HOME_TARGET"
  echo "[entrypoint] Persisted Claude Code state to /data/secrets/claude"
fi

exec gosu openclaw node src/server.js
