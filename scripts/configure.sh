#!/usr/bin/env bash
# Interview: what does this person actually want to keep?
# Writes dumbtv.conf (git-ignored), which debloat.sh, dnsfilter.sh and
# launcher.sh read. Agents must run this before the destructive steps instead of
# guessing. Usage: ./scripts/configure.sh [--keep "pkg pkg"] [--remove "pkg"] [--system-dns 0|1] [-y] [--dry-run]
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

KEEP_ARG=""; REMOVE_ARG=""; SYSTEM_DNS_ARG=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --keep)   KEEP_ARG=$2; shift 2 ;;
    --remove) REMOVE_ARG=$2; shift 2 ;;
    --system-dns) SYSTEM_DNS_ARG=$2; shift 2 ;;
    -y|--yes) ASSUME_YES=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    *) die "unknown flag: $1" ;;
  esac
done

KEEP=${KEEP_ARG:-}
EXTRA=${REMOVE_ARG:-}

# Prompt on stderr, answer on stdout: $() must capture only 0 or 1.
yn() {
  local prompt=$1 def=$2 a
  if [[ $ASSUME_YES == 1 ]]; then printf '%s' "$def"; return; fi
  if [[ $def == 1 ]]; then printf '%s [Y/n] ' "$prompt" >&2; else printf '%s [y/N] ' "$prompt" >&2; fi
  read -r a
  [[ -z $a ]] && { printf '%s' "$def"; return; }
  case $a in y|Y|yes|YES) printf 1 ;; *) printf 0 ;; esac
}

add_keep() { case " $KEEP " in *" $1 "*) ;; *) KEEP="$KEEP $1" ;; esac; }

step "what stays on the TV"
note "Everything that only does ads, tracking or experiments is removed either way."
note "This step is only about apps a person might actually watch."

# The list is read on fd 3 so the prompt inside the loop still owns stdin.
while IFS= read -r -u 3 p; do
  [[ -z $p || $p == \#* ]] && continue
  name=$(app_name "$p"); name=${name:-$p}
  if [[ $(yn "Remove $name?" 1) == 0 ]]; then
    add_keep "$p"
    note "keep   $name ($p)"
  else
    note "remove $name ($p)"
  fi
done 3< <(list_of "$(fos user-apps.txt)")

if [[ $(yn "Do you watch Prime Video? (keeps its CDN out of the filter)" 1) == 1 ]]; then
  PRIME=1; note "prime: kept"
else
  PRIME=0; note "prime: blocked (playback will not work)"
fi

LAUNCHER=$(yn "Replace Amazon's home screen with dumbtv home (open source, no ads, no internet access)?" 1)
DNSFILTER=$(yn "Run the on-TV DNS filter (blocks Amazon telemetry and updates)?" 1)
if [[ -n $SYSTEM_DNS_ARG ]]; then
  SYSTEM_DNS=$SYSTEM_DNS_ARG
else
  SYSTEM_DNS=$(yn "Fire OS 6 only: let system apps bypass the filter so the clock syncs? Amazon's system-user apps go unfiltered too" 0)
fi
# Default no: YouTube is the app people actually watch, and the stock app stays
# unless they say otherwise. scripts/youtube.sh is the only thing that touches it.
if [[ $(yn "Replace the YouTube app with SmartTube (no ads, no Shorts)? Your YouTube account and subscriptions are untouched" 0) == 1 ]]; then
  YOUTUBE=1; note "youtube: replaced with SmartTube"
else
  YOUTUBE=0; note "youtube: left alone"
fi

if [[ $ASSUME_YES == 0 && -z $KEEP_ARG ]]; then
  printf '\nOther apps to keep, space separated package names (Enter for none): ' >&2
  read -r more
  for p in $more; do add_keep "$p"; done
  printf 'Extra apps to remove, space separated package names (Enter for none): ' >&2
  read -r extras
  EXTRA="$EXTRA $extras"
fi

KEEP=$(printf '%s' "$KEEP" | sed 's/^ *//')
EXTRA=$(printf '%s' "$EXTRA" | sed 's/^ *//')

if [[ $DRY_RUN == 1 ]]; then
  step "would write $CONF"
  note "KEEP_APPS=\"$KEEP\""
  note "REMOVE_EXTRA=\"$EXTRA\""
  note "PRIME=$PRIME LAUNCHER=$LAUNCHER DNSFILTER=$DNSFILTER SYSTEM_DNS=$SYSTEM_DNS YOUTUBE=$YOUTUBE"
  exit 0
fi

mkdir -p "$REPORT"
cat > "$CONF" <<EOF_CONF
# Written by scripts/configure.sh. Git-ignored; it describes this household, not the repo.
KEEP_APPS="$KEEP"
REMOVE_EXTRA="$EXTRA"
PRIME=$PRIME
LAUNCHER=$LAUNCHER
DNSFILTER=$DNSFILTER
SYSTEM_DNS=$SYSTEM_DNS
YOUTUBE=$YOUTUBE
EOF_CONF

# Prove the file before anyone sources it.
# shellcheck disable=SC1090
source "$CONF"
case $LAUNCHER in 0|1) ;; *) die "internal error: LAUNCHER=$LAUNCHER";; esac
case $DNSFILTER in 0|1) ;; *) die "internal error: DNSFILTER=$DNSFILTER";; esac
case $SYSTEM_DNS in 0|1) ;; *) die "internal error: SYSTEM_DNS=$SYSTEM_DNS";; esac
case $PRIME in 0|1) ;; *) die "internal error: PRIME=$PRIME";; esac
case $YOUTUBE in 0|1) ;; *) die "internal error: YOUTUBE=$YOUTUBE";; esac

step "saved"
note "${CONF#$ROOT/}"
note "keep:     ${KEEP:-none}"
note "remove:   ${EXTRA:-nothing extra}"
note "prime=$PRIME launcher=$LAUNCHER dnsfilter=$DNSFILTER system_dns=$SYSTEM_DNS youtube=$YOUTUBE"
note "change any answer later by running this again"
