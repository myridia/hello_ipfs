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
  printf "  │  1  │ Show CLI - how to install/run ipfs on host       │\n"
  printf "  │  2  │ Show CLI - start daemon                         │\n"
  printf "  │  3  │ Show CLI - check daemon (ipfs id -p)            │\n"
  printf "  │  4  │ Show CLI - add site -> get CID (prints commands)│\n"
  printf "  │  5  │ Show CLI - name publish /ipfs/<cid>             │\n"
  printf "  │  6  │ Show CLI - local gateway on port %s             │\n" "$GATEWAY_PORT"
  printf "  │  7  │ Serve - python http.server on port %s            │\n" "$PORT"
  printf "  │  8  │ Stop server (task 7)                            │\n"
  printf "  │  0  │ Exit                                             │\n"
  printf "  └─────┴──────────────────────────────────────────────────┘\n\n"
  printf "  Enter Task ID: "
  read -r task || exit 0

  case "$task" in
    1)
      printf "  \033[1mKubo (ipfs) - install on the HOST\033[0m\n\n"
      printf "  Option A (official script):\n"
      printf "    curl -fsSL https://dist.ipfs.tech/kubo/install.sh | sh\n"
      printf "    export PATH=\"$HOME/.ipfs/kubo:$PATH\"\n\n"
      printf "  Option B (Debian/apt):\n"
      printf "    sudo apt install kubo  (check version)\n\n"
      printf "  Option C (binary): https://dist.ipfs.tech/kubo/\n\n"
      printf "  After install, check: ipfs --version\n\n"
      ;;
    2)
      printf "  \033[1mStart ipfs daemon (on HOST)\033[0m\n\n"
      printf "  mkdir -p %s\n" "$DIR"
      printf "  cd %s\n" "$DIR"
      printf "  nohup ipfs daemon > .daemon.log 2>&1 &\n"
      printf "  echo $! > .daemon.pid\n"
      printf "  # wait ~5s or tail .daemon.log\n"
      printf "  tail -f .daemon.log | head -20\n\n"
      ;;
    3)
      printf "  \033[1mCheck daemon (on HOST)\033[0m\n\n"
      printf "  cd %s\n" "$DIR"
      printf "  ipfs id -p\n"
      printf "  ipfs swarm peers 2>&1 | head -5\n\n"
      ;;
    4)
      printf "  \033[1mAdd site and get CID (on HOST)\033[0m\n\n"
      printf "  cd %s\n" "$DIR"
      printf "  # write nothing but hash\n"
      printf "  ipfs add -r --only-hash --quiet public | tail -n1 > .cid\n"
      printf "  cat .cid\n"
      printf "  # or pin it properly:\n"
      printf "  ipfs add -r public\n"
      printf "  # last line gives root CID (dir)\n\n"
      ;;
    5)
      printf "  \033[1mPublish CID (on HOST)\033[0m\n\n"
      printf "  cd %s\n" "$DIR"
      printf "  CID=$(cat .cid 2>/dev/null)\n"
      printf "  [ -n \"$CID\" ] || { echo 'no .cid - run task 4'; exit 1; }\n"
      printf "  ipfs name publish /ipfs/$CID\n\n"
      printf "  View: https://ipfs.io/ipfs/$CID  or  /ipfs/$CID via your gateway\n\n"
      ;;
    6)
      printf "  \033[1mLocal IPFS gateway (on HOST)\033[0m\n\n"
      printf "  cd %s\n" "$DIR"
      printf "  CID=$(cat .cid 2>/dev/null || echo '<cid>')\n"
      printf "  nohup ipfs gateway --port %s > .gateway.log 2>&1 &\n" "$GATEWAY_PORT"
      printf "  echo $! > .gateway.pid\n"
      printf "  echo http://192.168.43.2:%s/ipfs/$CID\n" "$GATEWAY_PORT"
      printf "  echo http://localhost:%s/ipfs/$CID\n\n" "$GATEWAY_PORT"
      ;;
    7)
      printf "  \033[1mServe with Python (on HOST or here)\033[0m\n\n"
      pid=$(pid_of "$SERVER_PID")
      if alive "$pid"; then
        printf "  already running (pid %s) http://192.168.43.2:%s/\n\n" "$pid" "$PORT"
      elif have_python; then
        cd "$DIR/public" || exit 1
        nohup python3 -m http.server "$PORT" --bind 0.0.0.0 >"$SERVER_LOG" 2>&1 &
        echo $! >"$SERVER_PID"
        cd "$DIR" || exit 1
        printf "  started (pid %s)\n" "$(cat "$SERVER_PID")"
        printf "  http://192.168.43.2:%s/\n" "$PORT"
        printf "  http://localhost:%s/\n\n" "$PORT"
      else
        printf "  python3 not in PATH here\n\n"
      fi
      ;;
    8)
      pid=$(pid_of "$SERVER_PID")
      if [ -z "$pid" ]; then
        printf "  no server running\n\n"
      elif alive "$pid"; then
        kill "$pid" && printf "  stopped (pid %s)\n\n" "$pid"
      else
        printf "  pid %s not running\n\n" "$pid"
        rm -f "$SERVER_PID"
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
