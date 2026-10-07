# AGENTS.md — hello_ipfs

## Overview
Minimal IPFS test page. One static HTML file in `public/`, served locally with
Python's `http.server` or added to IPFS with the `ipfs` CLI. No build step, no
dependencies, no Docker.

## Stack
- Static HTML in `public/` (`index.html`)
- `python3 -m http.server` for local serving (stdlib, nothing to install)
- `ipfs` CLI for `add` / `name publish` (must be installed + running locally)

## Structure
```
hello_ipfs/
├── ask.sh          — task runner (serve / add / publish / cleanup)
├── hello_ipfs.svg  — logo
├── public/
│   └── index.html  — the page itself
├── LICENSE         — MIT
└── README.md
```

## Tasks (`ask.sh`)
| ID | Task |
|----|------|
| 1 | Serve — `python3 -m http.server` on port `8092` from `public/`, writes `.server.pid` |
| 2 | Stop — kills the pid from task 1 |
| 3 | Status — `ok` / `warn` whether the server is up |
| 4 | Add — `ipfs add -r --only-hash --quiet public`, prints the root CID, saves it to `.cid` |
| 5 | Publish — `ipfs name publish /ipfs/<cid from .cid>` |
| 6 | Peer ID — `ipfs id -p` |
| 7 | Clean — removes `.cid`, `.server.pid`, `.server.log` |
| 0 | Exit |

The user starts the tasks — do not run `ask.sh` from the agent. Verify with
`bash -n ask.sh` only.

## URLs
- Local: `http://192.168.43.2:8092/` (from the agent container; never
  `127.0.0.1`, which is the agent's own namespace)
- IPFS: `/ipfs/<cid>` — the path form, gateway-independent

## Runtime files (gitignored)
`.cid`, `.server.pid`, `.server.log`. They live in the project root, are
written by `ask.sh`, and are shared with the host via the bind mount.

## Conventions
- **The page stays self-contained.** Inline `<style>`, inline `<svg>`, inline
  `<script>`, favicon as a `data:` URI. Nothing may be loaded from outside the
  file — the `external requests` row the page prints is the check
  (`performance.getEntriesByType("resource")` filtered to other origins must be 0).
- The CID is the identity of the content. Editing `public/index.html` changes
  the CID — re-run task 4, then task 5 to move the published name.
- `--only-hash` on task 4 keeps the repo clean: no CID-named files are written
  into the working tree. Use a real `ipfs add -r public` only when you
  deliberately want those blocks on disk.
- No comments in code unless asked.
- Veto commits; the agent prepares and verifies only.