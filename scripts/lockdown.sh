#!/usr/bin/env bash
# Takes away background execution and background data from the packages Amazon
# refuses to disable. Usage: ./scripts/lockdown.sh [--dry-run] [-y]
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
parse_flags "$@"
need_device
load_conf

step "network policy"
note "data saver on, then a blacklist entry per protected package"
acmd cmd netpolicy set restrict-background true >/dev/null

for p in $(list_of "$(fos protected.txt)"); do
  if keep_pkg "$p"; then
    printf '  %-46s SKIP (keep list)\n' "$p"; continue
  fi
  if ! present "$p"; then
    printf '  %-46s absent\n' "$p"; continue
  fi
  uid=$(uid_of "$p")
  if [[ -z $uid || $uid -lt 10000 ]]; then
    printf '  %-46s SKIP (shared system uid %s)\n' "$p" "${uid:-?}"
    continue
  fi
  bg_off "$p"
  acmd am force-stop "$p" >/dev/null 2>&1
  acmd cmd netpolicy add restrict-background-blacklist "$uid" >/dev/null
  printf '  %-46s ops off, data blocked (uid %s)\n' "$p" "$uid"
done

step "verify"
if [[ $DRY_RUN == 1 ]]; then
  note "skipped in dry-run"
else
  note "data saver: $(dev 'cmd netpolicy get restrict-background' | tr -d '\r')"
  note "blacklist:  $(dev 'cmd netpolicy list restrict-background-blacklist' | tr -d '\r')"
  op=RUN_ANY_IN_BACKGROUND; [[ $SDK -lt 28 ]] && op=RUN_IN_BACKGROUND
  for p in $(list_of "$(fos protected.txt)"); do
    present "$p" && note "$(printf '%-44s' "$p") $(dev "appops get $p $op" | tr -d '\r')"
  done
fi
