# =============================================================================
# Gruvbox Dark System Telemetry HUD (Termux / WSL / Linux) — Full-Width Edition
# =============================================================================
_render_motd() {
  local C_RESET=$'\e[0m'
  local C_BOLD=$'\e[1m'
  local C_BG_GRAY=$'\e[38;2;102;92;84m'    # #665c54 (borders)
  local C_GRAY=$'\e[38;2;146;131;116m'     # #928374 (muted text)
  local C_FG=$'\e[38;2;235;219;178m'       # #ebdbb2 (gruvbox fg)
  local C_ORANGE=$'\e[38;2;254;128;25m'    # #fe8019 (accents)
  local C_YELLOW=$'\e[38;2;250;189;47m'    # #fabd2f (warnings/badges)
  local C_GREEN=$'\e[38;2;184;187;38m'     # #b8bb26 (healthy bars)
  local C_AQUA=$'\e[38;2;142;192;124m'     # #8ec07c (labels)
  local C_BLUE=$'\e[38;2;131;165;152m'     # #83a598 (info)
  local C_RED=$'\e[38;2;251;73;52m'        # #fb4934 (high usage)

  # 1. Identity & Platform Detection
  local user="${USER:-$(id -un 2>/dev/null || echo user)}"
  local host="${HOST:-$(hostname 2>/dev/null || echo localhost)}"
  host="${host%%.*}"
  local arch="$(uname -m 2>/dev/null || echo unknown)"
  local kernel="$(uname -r 2>/dev/null || echo unknown)"
  kernel="${kernel%%-microsoft*}"

  local platform="LINUX"
  local os_name="Linux"
  if [[ -d "/data/data/com.termux" ]]; then
    platform="TERMUX"
    local android_ver="$(getprop ro.build.version.release 2>/dev/null)"
    local device_model="$(getprop ro.product.model 2>/dev/null)"
    os_name="Android ${android_ver:-?} ${device_model:+($device_model)}"
  elif [[ -f /proc/version ]] && grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
    platform="WSL2"
    if [[ -f /etc/os-release ]]; then
      os_name="$(awk -F= '/^PRETTY_NAME=/{gsub(/"/,"",$2); print $2}' /etc/os-release)"
    fi
  elif [[ -f /etc/os-release ]]; then
    os_name="$(awk -F= '/^PRETTY_NAME=/{gsub(/"/,"",$2); print $2}' /etc/os-release)"
  fi

  # 2. Uptime & Load Average
  local up_str="N/A"
  if [[ -r /proc/uptime ]]; then
    local up_sec="${$(</proc/uptime)%%.*}"
    local d=$((up_sec / 86400))
    local h=$(((up_sec % 86400) / 3600))
    local m=$(((up_sec % 3600) / 60))
    if (( d > 0 )); then
      up_str="${d}d ${h}h ${m}m"
    elif (( h > 0 )); then
      up_str="${h}h ${m}m"
    else
      up_str="${m}m"
    fi
  fi

  local load_str=""
  if [[ -r /proc/loadavg ]]; then
    read -r l1 l5 l15 _ < /proc/loadavg
    load_str="${l1} ${l5} ${l15}"
  fi

  # 3. Network (LAN + Tailscale)
  local lan_ip=""
  local ts_ip=""
  if command -v ip >/dev/null 2>&1; then
    lan_ip="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1); exit}')"
    ts_ip="$(ip -4 addr show tailscale0 2>/dev/null | awk '/inet /{sub(/\/.*/,"",$2); print $2; exit}')"
    [[ -z "$ts_ip" ]] && ts_ip="$(ip -4 addr show tun0 2>/dev/null | awk '/inet 100\./{sub(/\/.*/,"",$2); print $2; exit}')"
  fi
  [[ -z "$lan_ip" ]] && lan_ip="offline"

  # 4. Memory Telemetry (/proc/meminfo)
  local mem_pct=0 mem_used_g="0.0" mem_tot_g="0.0"
  if [[ -r /proc/meminfo ]]; then
    local mem_tot_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
    local mem_avail_kb=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
    if (( mem_tot_kb > 0 )); then
      local mem_used_kb=$((mem_tot_kb - mem_avail_kb))
      mem_pct=$((mem_used_kb * 100 / mem_tot_kb))
      mem_used_g="$(awk "BEGIN {printf \"%.1f\", $mem_used_kb/1048576}")"
      mem_tot_g="$(awk "BEGIN {printf \"%.1f\", $mem_tot_kb/1048576}")"
    fi
  fi

  # 5. Disk Telemetry
  local disk_pct=0 disk_used="0G" disk_tot="0G"
  if command -v df >/dev/null 2>&1; then
    read -r disk_tot disk_used disk_pct < <(df -Ph "$HOME" 2>/dev/null | awk 'NR==2 {gsub(/%/,"",$5); print $2, $3, $5}')
  fi

  # 6. Dev Environment Summary
  local nvim_v=""
  if command -v nvim >/dev/null 2>&1; then
    nvim_v="$(nvim --version 2>/dev/null | awk 'NR==1 {print $2}')"
  fi
  local tmux_info="off"
  if command -v tmux >/dev/null 2>&1; then
    local sess_cnt="$(tmux list-sessions 2>/dev/null | wc -l | tr -d ' ')"
    (( sess_cnt > 0 )) && tmux_info="${sess_cnt} active"
  fi

  # Helper: 10-segment Gruvbox progress bar
  _make_bar() {
    local pct="${1:-0}"
    local filled=$((pct / 10))
    (( filled > 10 )) && filled=10
    (( filled < 0 )) && filled=0
    local empty=$((10 - filled))
    local bar_color="$C_GREEN"
    (( pct >= 65 )) && bar_color="$C_YELLOW"
    (( pct >= 85 )) && bar_color="$C_RED"

    local b_fill="" b_empty="" i
    for ((i = 0; i < filled; i++)); do b_fill+="▰"; done
    for ((i = 0; i < empty; i++)); do b_empty+="▱"; done
    printf "%s%s%s%s%s" "$bar_color" "$b_fill" "$C_BG_GRAY" "$b_empty" "$C_RESET"
  }

  local mem_bar="$(_make_bar "$mem_pct")"
  local disk_bar="$(_make_bar "${disk_pct:-0}")"
  local now_str="$(date +'%H:%M // %a' | tr '[:lower:]' '[:upper:]')"

  # 7. Dynamic Full-Width Border Calculation
  local cols="${COLUMNS:-0}"
  if (( cols <= 0 )); then
    cols="$(tput cols 2>/dev/null || stty size 2>/dev/null | awk '{print $2}' || echo 80)"
  fi
  (( cols <= 0 )) && cols=80

  local top_badge="[${platform} // ${arch}]"
  local bot_badge="[${now_str}]"

  # Visible character count:
  # Top: "╭─ ⚡ " (6 columns, ⚡ is 2 cells wide) + "user@host" + " " (1) + dashes + " " (1) + top_badge
  local user_host="${user}@${host}"
  local top_fill_len=$(( cols - 8 - ${#user_host} - ${#top_badge} ))
  (( top_fill_len < 2 )) && top_fill_len=2

  # Bottom: "╰" (1) + dashes + " " (1) + bot_badge
  local bot_fill_len=$(( cols - 2 - ${#bot_badge} ))
  (( bot_fill_len < 2 )) && bot_fill_len=2

  local top_dashes="" bot_dashes="" i
  for ((i = 0; i < top_fill_len; i++)); do top_dashes+="─"; done
  for ((i = 0; i < bot_fill_len; i++)); do bot_dashes+="─"; done

  # Render HUD
  print ""
  print "${C_BG_GRAY}╭─${C_RESET} ${C_ORANGE}${C_BOLD}⚡ ${user}${C_GRAY}@${C_FG}${host}${C_RESET} ${C_BG_GRAY}${top_dashes}${C_RESET} ${C_YELLOW}${top_badge}${C_RESET}"
  print "${C_BG_GRAY}│${C_RESET}"
  print "${C_BG_GRAY}│${C_RESET}  ${C_AQUA}${C_BOLD}OS     ${C_RESET} ${C_FG}${os_name}${C_RESET} ${C_GRAY}(${kernel})${C_RESET}"
  print "${C_BG_GRAY}│${C_RESET}  ${C_AQUA}${C_BOLD}UP     ${C_RESET} ${C_FG}${up_str}${C_RESET}${load_str:+  ${C_GRAY}•  LOAD${C_RESET} ${C_FG}${load_str}${C_RESET}}"
  print "${C_BG_GRAY}│${C_RESET}  ${C_AQUA}${C_BOLD}NET    ${C_RESET} ${C_FG}${lan_ip}${C_RESET}${ts_ip:+  ${C_GRAY}•  ${C_BLUE}TS ${ts_ip}${C_RESET}}"
  print "${C_BG_GRAY}│${C_RESET}  ${C_AQUA}${C_BOLD}ENV    ${C_RESET} ${C_FG}zsh ${ZSH_VERSION}${C_RESET}${nvim_v:+  ${C_GRAY}•${C_RESET}  ${C_FG}nvim ${nvim_v}${C_RESET}}  ${C_GRAY}•${C_RESET}  ${C_FG}tmux: ${tmux_info}${C_RESET}"
  print "${C_BG_GRAY}│${C_RESET}"
  printf "%s│%s  %s%sMEM    %s %s  %s%3d%%%s  %s(%sG / %sG)%s\n" \
    "$C_BG_GRAY" "$C_RESET" "$C_AQUA" "$C_BOLD" "$C_RESET" "$mem_bar" "$C_FG" "$mem_pct" "$C_RESET" "$C_GRAY" "$mem_used_g" "$mem_tot_g" "$C_RESET"
  printf "%s│%s  %s%sDISK   %s %s  %s%3d%%%s  %s(%s / %s)%s\n" \
    "$C_BG_GRAY" "$C_RESET" "$C_AQUA" "$C_BOLD" "$C_RESET" "$disk_bar" "$C_FG" "${disk_pct:-0}" "$C_RESET" "$C_GRAY" "$disk_used" "$disk_tot" "$C_RESET"
  print "${C_BG_GRAY}│${C_RESET}"
  print "${C_BG_GRAY}╰${bot_dashes}${C_RESET} ${C_GRAY}${bot_badge}${C_RESET}"
  print ""
}

# Auto-run rules:
# 1. Outside Tmux -> Always show
# 2. Inside Tmux  -> Show ONLY in the first window when unsplit (1 pane)
_should_show_motd() {
  [[ -z "${TMUX:-}" ]] && return 0

  local tmux_state
  tmux_state="$(tmux display-message -p -t "${TMUX_PANE:-}" '#{window_index}:#{window_panes}:#{session_windows}' 2>/dev/null)" || return 0

  local win_idx="${tmux_state%%:*}"
  local rest="${tmux_state#*:}"
  local win_panes="${rest%%:*}"
  local sess_wins="${rest##*:}"

  if [[ "$win_panes" == "1" ]] && [[ "$win_idx" == "0" || "$sess_wins" == "1" ]]; then
    return 0
  fi
  return 1
}

if _should_show_motd; then
  _render_motd
fi

alias sys='_render_motd'
