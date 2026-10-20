# Which TVs this works on

One idea covers every TV here: **the TV should do what you paid for, not what the
vendor wants to sell you.** Whether that is possible is decided by one thing —
does the TV let a normal owner (no root, no soldering) run commands on it.

| Platform | Disable vendor apps | Replace the home screen | On-device DNS filter | Status |
|---|---|---|---|---|
| **Fire OS 6** (2017–2018 devices) | yes, some are protected | yes, `Keeper` + usage stats | yes | tested on a Stick 4K (AFTMM); own lists in `data/fireos6/` |
| **Fire OS 7** (Android 9) | yes, some are protected | yes, accessibility `Guard` | yes | **tested end to end, what this repo was built on** |
| **Fire OS 8** (Android 11) | yes, protected list differs | not yet — Android 11 blocks the launch (`docs/GOTCHAS.md`) | yes, with one step in the app | partly works on a Stick 4K Max (AFTKM), community report |
| **Android TV / Google TV** (Sony, TCL, Philips, Hisense, Xiaomi, Shield…) | yes, `pm disable-user` | yes, by disabling the stock launcher | yes, Private DNS or a local-VPN app | method documented, no verified package list yet |
| **Samsung Tizen** | store apps only | no | no | a wall without root |
| **LG webOS** | no | no | no | dev mode installs apps, nothing else |
| **Roku TV** (TCL/Hisense/Sharp) | no | no | no | control API only |
| **Hisense VIDAA** | no | no | no | control API only |
| **Vizio SmartCast** | no | no | no | control API only |
| **Panasonic My Home Screen** | no | no | no | closed, no dev path |
| **Philips Saphi** (cheap sets) | no | no | no | control API only |

"Network-level blocking" works on every one of them, including the closed ones:
point the TV's DNS at NextDNS, AdGuard Home or Pi-hole and it stops reaching the
vendors' ad and telemetry hosts. That is not this repository, but it is the honest
answer for a TV that refuses to be opened.

## Fire OS

This is the platform the scripts in `scripts/` are written for.

Run `scripts/preflight.sh`, then `scripts/debloat.sh --dry-run`, then for real.
`PROTECTED` lines tell you what to add to `data/fireos/protected.txt` (Fire OS 8)
or `data/fireos6/protected.txt` (Fire OS 6). Anything
`absent` simply is not on that device. Do not copy lists from the internet —
package names and protections moved between releases, and TV-specific packages
(panel, tuner, backlight) exist only on televisions.

**Fire TV Edition televisions** (Onida, Toshiba, JVC, Insignia, Croma — an
integrated panel, not a Stick) expose the same ADB shell and behave the same way.
Two differences: they carry extra panel, tuner and live-TV packages that belong on
the never-disable list, and on some of them Developer Options is hidden in a
submenu your model may not have — `adb_enabled` is already set, so ADB keeps
working either way.

## Android TV and Google TV

Same shell, same `pm disable-user`, different targets.

- **Telemetry is Google's.** Swap the Amazon lists for a Google tracker list, or
  keep the Amazon one only if Amazon apps are installed.
- **`cmd package set-home-activity` is not enough.** It prints `Success` and is
  then ignored, because HOME is resolved by intent-filter priority and the stock
  launcher ships `android:priority=2` against a sideloaded launcher's `0`. The
  working sequence is: install the new launcher first, then
  `pm disable-user` the stock one (`com.google.android.tvlauncher` on older
  builds, `com.google.android.apps.tv.launcherx` on newer ones).
- **Google TV trap:** `com.google.android.tungsten.setupwraith` also answers HOME
  (`.MainActivity` priority 4, `.RecoveryActivity` priority 1) and can crash-loop
  `system_server` if you disable `launcherx` alone. Disable the whole
  `setupwraith` package too. On some builds (a TCL G05 is reported) neither
  disable survives a reboot.
- **Private DNS is usually enough**: `settings put global private_dns_mode hostname`
  plus a filtering DoT resolver, with no app to keep alive. Use personalDNSfilter
  only if you need a custom host list.
- Fire OS settings keys (`amz_limit_ad_tracking` and friends) do nothing here.
- A few China-market TCL sets refuse to install any third-party launcher at all.

The generic Android TV bloat list is deliberately not included here. A bad list
can remove the input switcher or the settings app. Build it per device from
`pm list packages` on that device, with `./scripts/discover.sh`.

Reference lists from people who did this on real hardware:
[Gathin23/cleanyourtv](https://github.com/Gathin23/cleanyourtv) (30+ models) and
[seun-novodev/android-tv-debloat-toolkit](https://github.com/seun-novodev/android-tv-debloat-toolkit).

## Samsung Tizen

Different tool (`sdb` on port 26101, not ADB on 5555) and the walls are real:

- Developer Mode (Smart Hub → Apps → **12345** → Host PC IP → reboot) gives
  **no shell and no root**: `sdb capability` reports `intershell_support: disabled`
  and `sdbd_rootperm: disabled`. The usable verbs are app list, app uninstall and
  push — there is no way to change a setting, repoint HOME, or disable a service.
- `sdb uninstall` does remove store and carrier apps. It cannot touch the
  `org.tizen.*` / `com.samsung.*` packages, which is where the ads, ACR and
  telemetry live — and removing the wrong one takes the home screen with it.
- So: **no launcher replacement, no ad removal, no on-device DNS.**
- What does work, from the remote: `Settings → General → Smart Features → Autorun
  Smart Hub OFF` and `Autorun Last App OFF`, so the TV boots to the last input
  instead of the ad-laden hub.
- The real "dumb panel" answer is **hospitality mode**: with the TV on, press
  **Mute → 1 → 1 → 9 → Enter**, then set the power-on source and lock the inputs.
  A Samsung that boots straight into HDMI with no network attached is a
  completely private TV.

Details and the sdb capability dump:
[ardazeytin/samsung-tizen-tv-debloat](https://github.com/ardazeytin/samsung-tizen-tv-debloat).

## LG webOS

- Dev Mode (from the Content Store) + `ares` CLI over SSH on 9922 installs and
  runs IPK apps. That is all it does: no shell, no disabling preinstalled apps,
  no home-screen change, no DNS.
- Everything else — screensaver control, telemetry off, a custom home — is in the
  root-only column of [webosbrew.org/rooting](https://www.webosbrew.org/rooting/),
  and the home screen is a signed read-only Flutter app.
- Root existed for years (`faultmanager`, `dejavuln`, `mvpd`) but as of
  2025-08 the current firmware for webOS 5/6/7/9 is patched
  ([patch status](https://github.com/throwaway96/faultmanager-autoroot#patch-status)).
  On an up-to-date set, assume no root.
- The practical answer is **hotel mode**: hold the Settings button ~5 s, enter
  **1105**, then set `Power On Status` to a fixed input or `Last Input`.

## Roku TV

Developer mode exists (Home ×3, Up ×2, Right-Left-Right-Left-Right) and the ECP
REST API is on port 8060, but both are for **your own app**: ECP is query and
control (`query/device-info`, `keypress`, `launch`, `input`, `exit-app`) with no
command to disable, uninstall or repoint anything. Roku OS 14.1+ also gates ECP
behind "Control by mobile apps".
[ECP reference](https://developer.roku.com/docs/developer-program/debugging/external-control-api.md).

What is worth doing: `Settings → System → Power → Power on` = last input, and DNS
blocking at the router.

## Hisense VIDAA

No ADB. Older firmware exposes Chrome DevTools on port 9223; newer sets expose an
MQTT broker on 36669 for remote control. Both are control surfaces. Web apps can
be installed by DNS-spoofing `vidaahub.com` ([trialuser/vidaa-appstore](https://github.com/trialuser/vidaa-appstore)),
which is a neat trick and not a debloat.

Hidden menus: service menu via Settings → Sound → Advanced Audio Settings →
highlight Balance → **1969** (works on some models only), and a separate hotel
mode menu on many sets. A ready-made DNS list exists:
[ipanalytics/Hisense-VIDAA-DNS-Clean-TV-Blocklist](https://github.com/ipanalytics/Hisense-VIDAA-DNS-Clean-TV-Blocklist).

## Vizio SmartCast

Local HTTPS API on port 7345, PIN-paired, discovered over SSDP. Power, volume,
keypress, input switching, app launch and settings read/write — nothing that
disables an app or replaces a launcher
([exiva/Vizio_SmartCast_API](https://github.com/exiva/Vizio_SmartCast_API)).

## Panasonic and Philips Saphi

Panasonic's My Home Screen is a closed continuation of Firefox OS with no ADB, no
developer mode and no LAN control API. Panasonic moved its 2024+ TVs to Fire OS,
so those get the Fire OS answer instead.

Philips' cheap sets run Saphi, reachable only through the JointSpace API on port
1925 (power, Ambilight, remote keys, input, app launch). Philips sets running
Google TV are standard Android TV and are fully covered above.

## The option that always works

Feed the TV over HDMI from something you control — a Raspberry Pi with
LibreELEC/Kodi, a cheap Amlogic box with CoreELEC, or any Android TV box — and
never connect the TV to a network. The TV becomes a monitor: no firmware
fighting, no OTA risk, nothing to re-apply after an update.

## What we are working on

Honest list, no dates:

1. **A verified Android TV package list.** `data/androidtv/` has the safety list
   and nothing else. One careful run of `discover.sh` on one real Sony/TCL/Philips
   set, checked by hand, is worth more than any amount of code here.
2. **Launcher takeover without the accessibility service on Android TV**, using
   the stock-launcher disable instead, so `dumbtv home` works there the way it
   does on Fire OS.
3. **A `dumb-panel.sh` script** that sets the vendor's own boot-to-HDMI option
   where it exists (Samsung hospitality, LG installer menu, VIDAA hotel mode) and
   tells you the remote sequence on models where it does not.
4. **Samsung `sdb` uninstall lists** that are safe — store and carrier apps only,
   with the never-remove list enforced — if contributors with Tizen sets want it.
5. **Root paths** are out of scope on purpose. Where they exist they are
   per-build, temporary, and patched within weeks; a repo that depends on them
   stops working silently.

## Claims this repository will not make

- "ADB works on Samsung." It does not — Tizen uses `sdb`, and retail firmware
  gives no shell.
- "`set-home-activity` replaces the launcher." It is ignored on Fire OS (the
  launcher is protected, HOME priority 950) and on Android TV (stock launcher
  priority 2). The launcher has to be disabled.
- "Dev mode on webOS/Roku lets you disable things." It installs your own app.
- "On-device DNS filtering works everywhere." It needs an Android-style local VPN
  or Private DNS, so: Fire OS and Android TV only. Everywhere else the filter
  lives on your router.
- "You can remove the operating system." See `WHY-NOT-REPLACE-OS.md`.
