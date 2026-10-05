#!/bin/bash
# hello_ipfs — Task Runner (manual, step by step)
# ipfs/kubo not installed in this container; run these on the host

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CID_FILE="$DIR/.cid"
PORT=8092
GATEWAY_PORT=8093
SERVER_PID="$DIR/.server.pid"
SERVER_LOG="$DIR/.server.log"

have_ipfs() { command -v ipfs >/dev/null 2>&1; }
have_python() { command -v python3 >/dev/null 2>&1; }
alive() { [ -n "$1" ] && kill -0 "$1" 2>/dev/null; }
pid_of() { [ -f "$1" ] || return 1; cat "$1"; }

while :; do
  printf "\n  hello_ipfs - Task Runner (manual steps)\n\n"
  printf "  ┌─────┬──────────────────────────────────────────────────┐\n"
  printf "  │  ID │ Description                                      │\n"
  printf "  ├─────┼──────────────────────────────────────────────────┤\n"
  printf "  │  1  │ Install + enable ipfs in this container (A)      │\n"
  printf "  │  0  │ Exit                                             │\n"
  printf "  └─────┴──────────────────────────────────────────────────┘\n\n"
  printf "  Enter Task ID: "
  read -r task || exit 0

  case "$task" in
    1)
      export PATH="$HOME/.ipfs/kubo:$HOME/.ipfs/kubo/bin:$HOME/go/bin:$PATH"
      if have_ipfs; then
        printf "  ok    ipfs already installed\n"
        printf "        %s  (%s)\n\n" "$(command -v ipfs)" "$(ipfs --version 2>&1 | head -1)"
      else
        printf "  installing kubo in this container...\n\n"
        curl -fsSL https://dist.ipfs.tech/kubo/install.sh | bash
        export PATH="$HOME/.ipfs/kubo:$HOME/.ipfs/kubo/bin:$HOME/go/bin:$PATH"
        if have_ipfs; then
          printf "  ok    ipfs installed\n"
          printf "        %s  (%s)\n\n" "$(command -v ipfs)" "$(ipfs --version 2>&1 | head -1)"
        else
          printf "  FAIL  ipfs not found after install. Look in ~/.ipfs/kubo/\n\n"
        fi
      fi
      ;;
    0)
      printf "  Bye.\n\n"
      exit 0
      ;;
    *)
      printf "  unknown task: %s\n\n" "$task"
      ;;
  esac
  printf "  Press Enter..."
  read -r _ || exit 0
  printf "\n"
done
