#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
serverDir="$root/../server"
jar="$serverDir/paper-1.12.2.jar"

if [[ ! -f "$jar" ]]; then
  echo "Missing $jar. Run scripts/setup.ps1 first." >&2
  exit 1
fi

cd "$serverDir"
java -Xms1G -Xmx2G -jar "$jar" nogui
