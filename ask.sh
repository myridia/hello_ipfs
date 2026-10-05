#!/bin/bash
# hello_ipfs — Task Runner

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$DIR/.server.pid"
LOG_FILE="$DIR/.server.log"
CID_FILE="$DIR/.cid"
PORT=8092

have_ipfs() { command -v ipfs >/dev/null 2>&1; }
have_python() { command -v python3 >/dev/null 2>&1; }

server_pid() { [ -f "$PID_FILE" ] || return 1; cat "$PID_FILE"; }

printf "\n  hello_ipfs — Task Runner\n\n"
printf "  Site files live in public/. Served on port %s.\n\n" "$PORT"

while :; do
  printf "  ┌─────┬──────────────────────────────────────────────────┐\n"
  printf "  │  ID │ Description                                      │\n"
  printf "  ├─────┼──────────────────────────────────────────────────┤\n"
  printf "  │  %-3s │ %-50s│\n" "1" "Serve - http.server on port $PORT (public/)"
  printf "  │  %-3s │ %-50s│\n" "2" "Stop - stop the server started by task 1"
  printf "  │  %-3s │ %-50s│\n" "3" "Status - is the server running?"
  printf "  │  %-3s │ %-50s│\n" "4" "Add - ipfs add public/ -> root CID (.cid)"
  printf "  │  %-3s │ %-50s│\n" "5" "Publish - ipfs name publish that CID"
  printf "  │  %-3s │ %-50s│\n" "6" "Peer ID - this node's address"
  printf "  │  %-3s │ %-50s│\n" "7" "Clean - remove .cid, .server.pid, .server.log"
  printf "  │  %-3s │ %-50s│\n" "0" "Exit"
  printf "  └─────┴──────────────────────────────────────────────────┘\n\n"

  printf "  Enter Task ID: "
  read -r task || exit 0

  case "$task" in
    1)
      if ! have_python; then
        printf "  FAIL  python3 not in PATH\n\n"
      else
        pid=$(server_pid)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
          printf "  warn  already running (pid %s) on port %s\n\n" "$pid" "$PORT"
        else
          cd "$DIR/public" || exit 1
          nohup python3 -m http.server "$PORT" --bind 0.0.0.0 >"$LOG_FILE" 2>&1 &
          echo $! >"$PID_FILE"
          cd "$DIR" || exit 1
          printf "  ok    started (pid %s)\n" "$(cat "$PID_FILE")"
          printf "    http://localhost:%s/\n" "$PORT"
          printf "    http://192.168.43.2:%s/\n\n" "$PORT"
        fi
      fi
      ;;
    2)
      pid=$(server_pid)
      if [ -z "$pid" ]; then
        printf "  warn  no %s — nothing started by task 1\n\n" "$(basename "$PID_FILE")"
      elif kill -0 "$pid" 2>/dev/null; then
        kill "$pid" && printf "  ok    stopped (pid %s)\n\n" "$pid"
      else
        printf "  warn  pid %s not running\n\n" "$pid"
        rm -f "$PID_FILE"
      fi
      ;;
    3)
      pid=$(server_pid)
      if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        printf "  ok    running (pid %s) http://192.168.43.2:%s/\n\n" "$pid" "$PORT"
      else
        printf "  warn  not running\n\n"
      fi
      ;;
    4)
      if ! have_ipfs; then
        printf "  FAIL  ipfs not in PATH\n\n"
      elif [ ! -d "$DIR/public" ]; then
        printf "  FAIL  no public/ directory\n\n"
      else
        cd "$DIR" || exit 1
        cid=$(ipfs add -r --only-hash --quiet public | tail -n 1)
        printf "  ok    /ipfs/%s\n" "$cid"
        printf "%s\n" "$cid" >"$CID_FILE"
        printf "  saved %s\n\n" "$(basename "$CID_FILE")"
      fi
      ;;
    5)
      if ! have_ipfs; then
        printf "  FAIL  ipfs not in PATH\n\n"
      elif [ ! -f "$CID_FILE" ]; then
        printf "  warn  no %s — run task 4 first\n\n" "$(basename "$CID_FILE")"
      else
        cd "$DIR" || exit 1
        ipfs name publish "/ipfs/$(cat "$CID_FILE")"
        printf "\n"
      fi
      ;;
    6)
      if ! have_ipfs; then
        printf "  FAIL  ipfs not in PATH\n\n"
      else
        ipfs id -p || printf "  warn  ipfs daemon not reachable\n\n"
      fi
      ;;
    7)
      printf "...removing .cid .server.pid .server.log\n\n"
      rm -f "$CID_FILE" "$PID_FILE" "$LOG_FILE"
      printf "  ok    cleaned\n\n"
      ;;
    0)
      printf "  Bye.\n\n"
      exit 0
      ;;
    *)
      printf "  Unknown task: %s\n\n" "$task"
      ;;
  esac

  printf "  Press Enter to return to the menu..."
  read -r _ || exit 0
  printf "\n"
done