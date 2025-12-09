#!/bin/bash

# find-free-port.shを実行してからdocker-compose upを実行
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/find-free-port.sh" up -d

