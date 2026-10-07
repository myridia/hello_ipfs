<img src="hello_ipfs.svg" alt="hello_ipfs" width="120">

# hello_ipfs

Static page in `public/`, served locally or added to IPFS.


https://letsdecentralize.org/tutorials/ipfs.html


#!/bin/bash
set -e

GOVERSION=$(wget -qO- https://go.dev/VERSION)
if [ -z "$GOVERSION" ]; then
  echo "FAIL: could not fetch latest Go version from https://go.dev/VERSION"
  exit 1
fi
echo "latest: $GOVERSION"

case "$(uname -m)" in
  x86_64) GOARCH=amd64 ;;
  aarch64|arm64) GOARCH=arm64 ;;
  *) echo "FAIL: unsupported arch $(uname -m)"; exit 1 ;;
esac

URL="https://go.dev/dl/${GOVERSION}.linux-${GOARCH}.tar.gz"
echo "downloading $URL"
wget -O /tmp/go.tar.gz "$URL"

rm -rf /usr/local/go
tar -C /usr/local -xzf /tmp/go.tar.gz
rm -f /tmp/go.tar.gz

if [ -d /etc/profile.d ]; then
  printf 'export PATH=$PATH:/usr/local/go/bin\n' > /etc/profile.d/go.sh
else
  echo "export PATH=\$PATH:/usr/local/go/bin" >> /etc/bash.bashrc
fi

echo "ok: installed /usr/local/go"
