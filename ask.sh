#!/bin/bash
# hello_ipfs — Task Runner

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CID_FILE="$DIR/.cid"
SERVER_PID="$DIR/.server.pid"
SERVER_LOG="$DIR/.server.log"
DAEMON_PID="$DIR/.daemon.pid"
DAEMON_LOG="$DIR/.daemon.log"
GATEWAY_PID="$DIR/.gateway.pid"
GATEWAY_LOG="$DIR/.gateway.log"
PORT=8092
GATEWAY_PORT=8093

have_ipfs() { command -v ipfs >/dev/null 2>&1; }
have_python() { command -v python3 >/dev/null 2>&1; }
alive() { [ -n "$1" ] && kill -0 "$1" 2>/dev/null; }
pid_of() { [ -f "$1" ] || return 1; cat "$1"; }
daemon_up() { have_ipfs && ipfs swarm peers >/dev/null 2>&1; }

stop_bg() {
  file=$1
  label=$2
  pid=$(pid_of "$file")
  if [ -z "$pid" ]; then
    printf "  warn  no %s - nothing started\n\n" "$(basename "$file")"
  elif alive "$pid"; then
    kill "$pid" && printf "  ok    %s stopped (pid %s)\n\n" "$label" "$pid"
  else
    printf "  warn  %s pid %s not running\n\n" "$label" "$pid"
    rm -f "$file"
  fi
}

add_site() {
  extra=$1
  label=$2
  cd "$DIR" || exit 1
  printf "  $ ipfs add -r%s public\n\n" "$extra"
  out=$(ipfs add -r $extra public 2>&1)
  rc=$?
  printf "%s\n\n" "$out"
  if [ $rc -ne 0 ]; then
    printf "  FAIL  exit %s - see the message above\n" "$rc"
    daemon_up || printf "  warn  ipfs daemon not reachable - task 1\n"
    printf "\n"
    return
  fi
  cid=$(printf "%s\n" "$out" | awk '$3 == "public" {print $2}' | tail -n 1)
  if [ -z "$cid" ]; then
    printf "  FAIL  no line 'added <cid> public' in the output - not saving\n\n"
    return
  fi
  printf "%s\n" "$cid" >"$CID_FILE"
  printf "  ok    %s\n" "$label"
  printf "        /ipfs/%s\n" "$cid"
  printf "        saved in %s\n\n" "$(basename "$CID_FILE")"
}

printf "\n  hello_ipfs - Task Runner\n\n"
printf "  Publishing public/ to IPFS, in order:\n"
printf "    1-3  node       4-5  add       6  name       7-8  read back\n"
printf "    9-10 plain http, no ipfs node involved\n\n"

while :; do
  printf "  ┌─────┬──────────────────────────────────────────────────┐\n"
  printf "  │  ID │ Description                                      │\n"
  printf "  ├─────┼──────────────────────────────────────────────────┤\n"
  printf "  │  %-3s │ %-50s│\n" "1" "Daemon start - ipfs daemon (.daemon.pid)"
  printf "  │  %-3s │ %-50s│\n" "2" "Daemon stop - stop the node"
  printf "  │  %-3s │ %-50s│\n" "3" "Daemon status - ok/warn + peer id"
  printf "  │  %-3s │ %-50s│\n" "4" "Add site - ipfs add -r public"
  printf "  │  %-3s │ %-50s│\n" "5" "Add site, CID only - --only-hash"
  printf "  │  %-3s │ %-50s│\n" "6" "Publish - ipfs name publish /ipfs/<cid>"
  printf "  │  %-3s │ %-50s│\n" "7" "Gateway start - ipfs gateway, port $GATEWAY_PORT"
  printf "  │  %-3s │ %-50s│\n" "8" "Gateway stop"
  printf "  │  %-3s │ %-50s│\n" "9" "Serve - http.server on port $PORT (public/)"
  printf "  │  %-3s │ %-50s│\n" "10" "Stop server"
  printf "  │  %-3s │ %-50s│\n" "11" "Clean - .cid, logs, files written by add"
  printf "  │  %-3s │ %-50s│\n" "0" "Exit"
  printf "  └─────┴──────────────────────────────────────────────────┘\n\n"

  printf "  Enter Task ID: "
  read -r task || exit 0

  case "$task" in
    1)
      if ! have_ipfs; then
        printf "  FAIL  ipfs not in PATH\n\n"
      else
        pid=$(pid_of "$DAEMON_PID")
        if daemon_up; then
          printf "  warn  daemon already running"
          [ -n "$pid" ] && printf " (pid %s)" "$pid"
          printf "\n\n"
        elif alive "$pid"; then
          printf "  warn  pid %s alive but not answering yet - %s\n\n" "$pid" "$(basename "$DAEMON_LOG")"
        else
          rm -f "$DAEMON_PID"
          printf "  $ ipfs daemon\n\n"
          nohup ipfs daemon >"$DAEMON_LOG" 2>&1 &
          echo $! >"$DAEMON_PID"
          i=0
          while [ $i -lt 30 ] && ! daemon_up; do
            sleep 1
            i=$((i + 1))
          done
          if daemon_up; then
            printf "  ok    daemon ready (pid %s), log %s\n" "$(cat "$DAEMON_PID")" "$(basename "$DAEMON_LOG")"
            printf "  $ ipfs id -p\n"
            ipfs id -p || printf "  warn  ipfs id failed\n"
          else
            printf "  warn  not ready after %ss - %s\n\n" "$i" "$(basename "$DAEMON_LOG")"
          fi
        fi
      fi
      ;;
    2)
      stop_bg "$DAEMON_PID" "daemon"
      ;;
    3)
      if ! have_ipfs; then
        printf "  FAIL  ipfs not in PATH\n\n"
      else
        pid=$(pid_of "$DAEMON_PID")
        if daemon_up; then
          printf "  ok    daemon running"
          [ -n "$pid" ] && printf " (pid %s)" "$pid"
          printf "\n"
        else
          printf "  warn  daemon not running\n"
        fi
        printf "  $ ipfs id -p\n"
        ipfs id -p || printf "  warn  ipfs id failed\n"
        printf "\n"
      fi
      ;;
    4)
      if ! have_ipfs; then
        printf "  FAIL  ipfs not in PATH\n\n"
      else
        add_site "" "added and pinned"
      fi
      ;;
    5)
      if ! have_ipfs; then
        printf "  FAIL  ipfs not in PATH\n\n"
      else
        add_site "--only-hash --quiet" "hash only, nothing written"
      fi
      ;;
    6)
      if ! have_ipfs; then
        printf "  FAIL  ipfs not in PATH\n\n"
      elif [ ! -f "$CID_FILE" ]; then
        printf "  warn  no %s - run task 4 or 5 first\n\n" "$(basename "$CID_FILE")"
      else
        cid=$(cat "$CID_FILE")
        cd "$DIR" || exit 1
        printf "  $ ipfs name publish /ipfs/%s\n\n" "$cid"
        ipfs name publish "/ipfs/$cid" || {
          printf "  FAIL  name publish failed\n\n"
          daemon_up || printf "  warn  ipfs daemon not reachable - task 1\n\n"
        }
      fi
      ;;
    7)
      if ! have_ipfs; then
        printf "  FAIL  ipfs not in PATH\n\n"
      else
        pid=$(pid_of "$GATEWAY_PID")
        if alive "$pid"; then
          printf "  warn  gateway already running (pid %s) on port %s\n\n" "$pid" "$GATEWAY_PORT"
        else
          rm -f "$GATEWAY_PID"
          printf "  $ ipfs gateway --port %s\n\n" "$GATEWAY_PORT"
          nohup ipfs gateway --port "$GATEWAY_PORT" >"$GATEWAY_LOG" 2>&1 &
          echo $! >"$GATEWAY_PID"
          sleep 2
          if alive "$(cat "$GATEWAY_PID")"; then
            printf "  ok    gateway started (pid %s), log %s\n" "$(cat "$GATEWAY_PID")" "$(basename "$GATEWAY_LOG")"
            if [ -f "$CID_FILE" ]; then
              printf "        http://192.168.43.2:%s/ipfs/%s\n" "$GATEWAY_PORT" "$(cat "$CID_FILE")"
              printf "        http://localhost:%s/ipfs/%s\n" "$GATEWAY_PORT" "$(cat "$CID_FILE")"
            else
              printf "        http://192.168.43.2:%s/ipfs/<cid> - no %s yet\n" "$GATEWAY_PORT" "$(basename "$CID_FILE")"
            fi
            printf "\n"
          else
            printf "  FAIL  gateway exited - %s\n\n" "$(basename "$GATEWAY_LOG")"
          fi
        fi
      fi
      ;;
    8)
      stop_bg "$GATEWAY_PID" "gateway"
      ;;
    9)
      if ! have_python; then
        printf "  FAIL  python3 not in PATH\n\n"
      else
        pid=$(pid_of "$SERVER_PID")
        if alive "$pid"; then
          printf "  warn  already running (pid %s) on port %s\n\n" "$pid" "$PORT"
        else
          rm -f "$SERVER_PID"
          cd "$DIR/public" || exit 1
          printf "  $ python3 -m http.server %s\n\n" "$PORT"
          nohup python3 -m http.server "$PORT" --bind 0.0.0.0 >"$SERVER_LOG" 2>&1 &
          echo $! >"$SERVER_PID"
          cd "$DIR" || exit 1
          printf "  ok    started (pid %s)\n" "$(cat "$SERVER_PID")"
          printf "    http://localhost:%s/\n" "$PORT"
          printf "    http://192.168.43.2:%s/\n\n" "$PORT"
        fi
      fi
      ;;
    10)
      stop_bg "$SERVER_PID" "server"
      ;;
    11)
      rm -f "$CID_FILE" "$SERVER_LOG" "$DAEMON_LOG" "$GATEWAY_LOG"
      printf "  ok    removed %s and the logs\n" "$(basename "$CID_FILE")"
      pid=$(pid_of "$DAEMON_PID")
      if alive "$pid"; then
        printf "  warn  daemon still running (pid %s) - stop it with task 2\n" "$pid"
      else
        rm -f "$DAEMON_PID"
      fi
      pid=$(pid_of "$GATEWAY_PID")
      if alive "$pid"; then
        printf "  warn  gateway still running (pid %s) - stop it with task 8\n" "$pid"
      else
        rm -f "$GATEWAY_PID"
      fi
      pid=$(pid_of "$SERVER_PID")
      if alive "$pid"; then
        printf "  warn  server still running (pid %s) - stop it with task 10\n" "$pid"
      else
        rm -f "$SERVER_PID"
      fi
      added=$(ls -1 "$DIR"/Qm* "$DIR"/bafy* "$DIR"/bafk* 2>/dev/null)
      if [ -n "$added" ]; then
        printf "%s\n" "$added" | while read -r f; do
          printf "  removing %s\n" "$(basename "$f")"
          rm -f "$f"
        done
      fi
      printf "\n"
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