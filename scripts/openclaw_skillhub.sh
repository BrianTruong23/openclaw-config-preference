#!/usr/bin/env bash
set -euo pipefail

exec clawhub --workdir /root/.openclaw --dir skills "$@"
