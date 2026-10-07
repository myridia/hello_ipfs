<img src="hello_ipfs.svg" alt="hello_ipfs" width="120">

# hello_ipfs

Static page in `public/`, served locally or added to IPFS.

https://letsdecentralize.org/tutorials/ipfs.html

## Install Go
```
sudo ./install.sh
```
Downloads the latest Go, extracts it to `/usr/local/go`, and adds `/usr/local/go/bin` to `PATH`.

## Install Kubo
```
git clone https://github.com/ipfs/kubo; cd kubo
make build
sudo mv ./cmd/ipfs/ipfs /usr/local/bin
ipfs init
```

## Create Service
```
emacs /usr/lib/systemd/system/ipfs.service
```

## Copy Service
```
cat /usr/lib/systemd/system/ipfs.service
[Unit]
Description=IPFS
After=network.target
StartLimitIntervalSec=0


[Service]
User=root
ExecStart=/usr/local/bin/ipfs daemon
ExecReload=/usr/local/bin/ipfs daemon
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full


[Install]
WantedBy=multi-user.target

```

## Register and start
```
sudo systemctl daemon-reload

sudo systemctl enable ipfs

sudo systemctl start ipfs
```

### Publish a website index.html
```
cd /var/customers/webs/ipfs/test
ipfs add -r --cid-version=1 .
```

## return
```
added bafkreiaz2uuo52cwwqi3z36ul4dhfefnumwhinvijaj65z5iezayy24b3y test/index.html
added bafybeicor3q2zndxy5vehl3467bhf2irghtayo42xw5gfpergic4olp4a4 test
```

## Your site root CID is:
```
bafybeicor3q2zndxy5vehl3467bhf2irghtayo42xw5gfpergic4olp4a4
```

## Open it:
- Local: http://127.0.0.1:8080/ipfs/bafybeicor3q2zndxy5vehl3467bhf2irghtayo42xw5gfpergic4olp4a4/
- Public: https://bafybeicor3q2zndxy5vehl3467bhf2irghtayo42xw5gfpergic4olp4a4.ipfs.dweb.link/

Verify contents:
```
ipfs ls bafybeicor3q2zndxy5vehl3467bhf2irghtayo42xw5gfpergic4olp4a4
```
