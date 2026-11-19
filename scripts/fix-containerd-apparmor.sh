#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Profile derived from containerd v2.3.7 contrib/apparmor/template.go.
# Copyright The docker Authors, The Moby Authors, The containerd Authors.
# Source matches k3s-io/containerd v2.3.7-k3s1 byte-for-byte.
# Correction: https://github.com/containerd/containerd/pull/14487
# Run on the affected rootful Ubuntu K3s server, not the workstation.
set -euo pipefail

render_profile() {
  local daemon_profile="${1:-unconfined}"
  echo '# Managed by homelab containerd AppArmor workaround (#14487).'
  echo '# SPDX-License-Identifier: Apache-2.0'
  echo '# Derived from containerd v2.3.7; copyright Docker, Moby, containerd Authors.'
  echo '# https://www.apache.org/licenses/LICENSE-2.0'
  if [[ -f /etc/apparmor.d/abi/3.0 ]]; then echo 'abi <abi/3.0>,'; fi
  if [[ -f /etc/apparmor.d/tunables/global ]]; then
    echo '#include <tunables/global>'
  else
    echo '@{PROC}=/proc/'
  fi
  echo 'profile cri-containerd.apparmor.d flags=(attach_disconnected,mediate_deleted) {'
  if [[ -f /etc/apparmor.d/abstractions/base ]]; then
    echo '  #include <abstractions/base>'
  fi
  cat <<PROFILE
  network,
  capability,
  file,
  umount,
  # Host (privileged) processes may send signals to container processes.
  signal (receive) peer=unconfined,
  # runc may send signals to container processes.
  signal (receive) peer=runc,
  # crun may send signals to container processes.
  signal (receive) peer=crun,
  # Manager may send signals to container processes.
  signal (receive) peer=${daemon_profile},
  # Container processes may send signals amongst themselves.
  signal (send,receive) peer=cri-containerd.apparmor.d,
  # Upstream fix: containerd/containerd#14487 (exact stacked peer).
  signal (send,receive) peer=cri-containerd.apparmor.d//&unconfined,


  deny @{PROC}/* w,   # deny write for all files directly in /proc (not in a subdir)
  # deny write to files not in /proc/<number>/** or /proc/sys/**
  deny @{PROC}/{[^1-9/],[^1-9/][^0-9/],[^1-9s/][^0-9y/][^0-9s/],[^1-9/][^0-9/][^0-9/][^0-9/]*}/** w,
  deny @{PROC}/sys/[^k]** w,  # deny /proc/sys except /proc/sys/k* (effectively /proc/sys/kernel)
  deny @{PROC}/sys/kernel/{?,??,[^s][^h][^m]**} w,  # deny everything except shm* in /proc/sys/kernel/
  deny @{PROC}/sysrq-trigger rwklx,
  deny @{PROC}/kcore rwklx,

  deny mount,

  deny /sys/[^f]*/** wklx,
  deny /sys/f[^s]*/** wklx,
  deny /sys/fs/[^c]*/** wklx,
  deny /sys/fs/c[^g]*/** wklx,
  deny /sys/fs/cg[^r]*/** wklx,
  deny /sys/firmware/** rwklx,
  deny /sys/devices/virtual/powercap/** rwklx,
  deny /sys/kernel/security/** rwklx,

  # allow processes within the container to trace each other,
  # provided all other LSM and yama setting allow it.
  ptrace (trace,tracedby,read,readby) peer=cri-containerd.apparmor.d,
  ptrace (trace,tracedby,read,readby) peer=cri-containerd.apparmor.d//&unconfined,
}
PROFILE
}

case "${1:-}" in
  --print-profile) render_profile; exit 0 ;;
  --install) ;;
  *) echo "Usage: bash $0 --print-profile | sudo bash $0 --install" >&2; exit 2 ;;
esac

[[ $EUID -eq 0 ]] || { echo 'Run --install with sudo.' >&2; exit 1; }
for tool in apparmor_parser systemctl pgrep awk install cmp; do
  command -v "$tool" >/dev/null || { echo "Missing prerequisite: $tool" >&2; exit 1; }
done
# shellcheck disable=SC1091
source /etc/os-release
[[ "$ID" == ubuntu ]] || { echo 'This workaround targets Ubuntu hosts.' >&2; exit 1; }
systemctl is-active --quiet k3s || { echo 'Expected an active k3s server service.' >&2; exit 1; }
mapfile -t runtime_pids < <(pgrep -x containerd)
[[ ${#runtime_pids[@]} -eq 1 ]] || { echo 'Expected exactly one rootful containerd process; inspect manually.' >&2; exit 1; }
runtime_pid="${runtime_pids[0]}"
[[ $(awk '/^Uid:/ {print $2}' "/proc/$runtime_pid/status") == 0 ]] || { echo 'Rootless containerd is unsupported.' >&2; exit 1; }
daemon_profile=$(cat "/proc/$runtime_pid/attr/current")
daemon_profile="${daemon_profile%% *}"
[[ "$daemon_profile" =~ ^[a-zA-Z0-9_./\&:-]+$ ]] || { echo 'Unexpected daemon AppArmor label; inspect manually.' >&2; exit 1; }
profile=/etc/apparmor.d/cri-containerd.apparmor.d
dropin_dir=/etc/systemd/system/k3s.service.d
dropin="$dropin_dir/20-apparmor-stacked-peer.conf"
if [[ -e "$profile" ]] && ! head -n 1 "$profile" | grep -q '^# Managed by homelab containerd AppArmor workaround'; then
  echo "Existing unmanaged profile at $profile; refusing to overwrite it." >&2; exit 1
fi
if [[ -e "$dropin" ]] && ! head -n 1 "$dropin" | grep -q '^# Managed by homelab'; then
  echo "Existing unmanaged systemd override at $dropin; refusing to overwrite it." >&2; exit 1
fi
umask 077
workdir=$(mktemp -d)
trap 'rm -rf -- "$workdir"' EXIT
render_profile "$daemon_profile" > "$workdir/profile"
# Parse without loading into the kernel or using a stale parser cache.
apparmor_parser -Q -K "$workdir/profile"
cat > "$workdir/dropin" <<'UNIT'
# Managed by homelab containerd AppArmor workaround (#14487).
[Unit]
Requires=apparmor.service
After=apparmor.service
[Service]
ExecStartPre=/usr/sbin/apparmor_parser -r -K /etc/apparmor.d/cri-containerd.apparmor.d
UNIT
if [[ -e "$profile" ]] && ! cmp -s "$profile" "$workdir/profile"; then
  install -m 600 "$profile" "/var/backups/cri-containerd.apparmor.d.$(date +%Y%m%d%H%M%S).bak"
fi
install -m 644 "$workdir/profile" "$profile"
install -d -m 755 "$dropin_dir"
install -m 644 "$workdir/dropin" "$dropin"
apparmor_parser -r -K "$profile"
systemctl daemon-reload
echo 'Corrected AppArmor profile loaded; confinement remains enabled.'
echo 'The profile is persisted and loaded before future k3s starts.'
echo 'K3s was not restarted. Verify PostgreSQL recovery from the workstation.'
echo 'Remove this override during a planned upgrade once K3s includes the upstream fix.'
