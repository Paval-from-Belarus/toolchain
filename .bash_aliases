alias vi=nvim
alias sl=ls
alias ns=nautilus

alias sl="ls"
alias ns="nautilus ."
alias cb="cargo build"
alias cbr="cargo build --release"
alias ct="cargo test"
alias cr="cargo run"
alias crr="cargo run --release"
alias cm="cargo make"
alias dc-up="docker-compose -d up &"
alias dc-down="docker-compose -d down &"
alias j="just"

alias vi="nvim"
alias vim="nvim"
alias cls=clear
alias clk="xdg-open"
alias python="python3" # for debian only
alias firewall-off="systemctl stop firewalld.service"
alias firewall-on="systemctl start firewalld.service"
alias vpn-status="systemctl status wg-quick@wg0.service"
alias check-battery="upower -i /org/freedesktop/UPower/devices/battery_BAT0"
alias check-nvme="sudo nvme smart-log /dev/nvme0n1"
alias check-sda="sudo smartctl /dev/sda -a"
alias hex-editor="flatpak run org.wxhexeditor.wxHexEditor"
alias power-save="sudo powertop --auto-tune; sudo cpupower frequency-set -g powersave"
alias jn="jupyter notebook"
alias ды=ls
alias ыд=ls
alias св=cd
alias tmux-clean="tmux list-sessions -F '#{session_attached} #{session_id}' | \
  awk '/^0/{print $2}' | \
  xargs -n 1 tmux kill-session -t"
alias rnm="sudo systemctl restart NetworkManager"
alias console="tokio-console"
#alias cat="bat"
alias py="python"
alias gr="go run ."
alias jl="just -f justfile.local"
alias gch="git checkout"
# alias kubectl="microk8s kubectl"

export EDITOR="nvim"
function parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

export PS1="\u@\h \[\e[32m\]\w \[\e[91m\]\$(parse_git_branch)\[\e[00m\]$ "
export SYSTEMD_PAGER=
export PROMPT_DIRTRIM=2
