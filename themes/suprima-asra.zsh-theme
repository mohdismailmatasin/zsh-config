# Ultima Zsh Theme p2.c7 - https://github.com/egorlem/ultima.zsh-theme
#
# Minimalistic .zshrc config contains all of the settings required for 
# comfortable terminal use.
#
# This code doesn't provide much value, but it will make using zsh a little more
# enjoyable.
#
# ------------------------------------------------------------------------------
# Authors
# -------
#
#  * Egor Lem <guezwhoz@gmail.com> / egorlem.com
#
# ------------------------------------------------------------------------------

autoload -Uz compinit; compinit

# LOCAL/VARIABLES/ANSI ---------------------------------------------------------

ANSI_reset="\x1b[0m"
ANSI_dim_black="\x1b[0;30m"
ANSI_grey="\x1b[0;37m"
ANSI_dim_grey="\x1b[2;37m"
ANSI_very_dim_grey="\x1b[2;30m"

# LOCAL/VARIABLES/GRAPHIC ------------------------------------------------------

char_arrow="›"                                                  #Unicode: \u203a
char_up_and_right_divider="└"                                   #Unicode: \u2514
char_down_and_right_divider="┌"                                 #Unicode: \u250c
char_vertical_divider="─"                                       #Unicode: \u2500

# SEGMENT/VCS_STATUS_LINE ------------------------------------------------------

export VCS="git"

current_vcs="\":vcs_info:*\" enable $VCS"
char_badge="%F{black} on %f%F{black}${char_arrow}%f"
vc_branch_name="%F{green}%b%f"

vc_action="%F{black}%a %f%F{black}${char_arrow}%f"
vc_unstaged_status="%F{cyan} M ${char_arrow}%f"

vc_git_staged_status="%F{green} A ${char_arrow}%f"
vc_git_hash="%F{green}%6.6i%f %F{black}${char_arrow}%f"
vc_git_untracked_status="%F{blue} U ${char_arrow}%f"

if [[ $VCS != "" ]]; then
  autoload -Uz vcs_info
  eval zstyle $current_vcs
  zstyle ':vcs_info:*' get-revision true
  zstyle ':vcs_info:*' check-for-changes true
fi

case "$VCS" in 
   "git")
    # git sepecific 
    zstyle ':vcs_info:git*+set-message:*' hooks use_git_untracked
    zstyle ':vcs_info:git:*' stagedstr $vc_git_staged_status
    zstyle ':vcs_info:git:*' unstagedstr $vc_unstaged_status
    zstyle ':vcs_info:git:*' actionformats "  ${vc_action} ${vc_git_hash}%m%u%c${char_badge} ${vc_branch_name}"
    zstyle ':vcs_info:git:*' formats " %c%u%m${char_badge} ${vc_branch_name}"
  ;;

  # svn sepecific 
  "svn")
    zstyle ':vcs_info:svn:*' branchformat "%b"
    zstyle ':vcs_info:svn:*' formats " ${char_badge} ${vc_branch_name}"
  ;;

  # hg sepecific 
  "hg")
    zstyle ':vcs_info:hg:*' branchformat "%b"
    zstyle ':vcs_info:hg:*' formats " ${char_badge} ${vc_branch_name}"
  ;;
esac

# Show untracked file status char on git status line
+vi-use_git_untracked() {
  if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == "true" ]] &&
    git status --porcelain | grep -m 1 "^??" &>/dev/null; then
    hook_com[misc]=$vc_git_untracked_status
  else
    hook_com[misc]=""
  fi
}

# SEGMENT/SSH_STATUS -----------------------------------------------------------

ssh_marker=""

if [[ -n "$SSH_CLIENT" || -n "$SSH2_CLIENT" ]]; then
 ssh_marker="%F{green}SSH%f%F{black}:%f"
fi

# UTILS ------------------------------------------------------------------------

setopt PROMPT_SUBST

# Command execution time tracking
cmd_exec_time() {
  local stop=$(date +%s)
  local start=${cmd_timestamp:-$stop}
  local elapsed=$((stop - start))
  
  if (( elapsed > 5 )); then
    echo "%F{yellow}⏱ ${elapsed}s%f | "
  fi
}

preexec() {
  cmd_timestamp=$(date +%s)
}

# Battery status function for Linux (using /sys/class/power_supply)
battery_status() {
  local percent bat_status icon color
  if [[ -d /sys/class/power_supply/BAT0 ]]; then
    percent=$(< /sys/class/power_supply/BAT0/capacity)
    bat_status=$(< /sys/class/power_supply/BAT0/status)
    if (( percent > 80 )); then
      icon="🔋"
      color="%F{green}"
    elif (( percent > 30 )); then
      icon="🔋"
      color="%F{yellow}"
    else
      icon="🔋"
      color="%F{red}"
    fi
    if [[ $bat_status == "Charging" ]]; then
      icon="⚡"
    fi
    echo "$color$icon $percent%%%f"
  fi
}

# Function to get public IP address (if online) - DISABLED
get_public_ip() {
  # IP address display removed for privacy
  echo ""
}

# Prepare git status line
prepareGitStatusLine() {
  echo '${vcs_info_msg_0_}'
} 

# Prepare prompt line limiter
printPsOneLimiter() {
  local termwidth
  local spacing=""
  
  ((termwidth = ${COLUMNS} - 1))
  
  for i in {1..$termwidth}; do
    spacing="${spacing}${char_vertical_divider}"
  done
  
  echo $ANSI_very_dim_grey$char_down_and_right_divider$spacing$ANSI_reset
}

# SEGMENT/PYTHON_ENV -----------------------------------------------------------

python_env_status() {
  if [[ -n "$VIRTUAL_ENV" ]]; then
    local env_name=$(basename "$VIRTUAL_ENV")
    echo "%F{white} $env_name%f | "
  fi
}

# SEGMENT/NODE_ENV -------------------------------------------------------------

node_env_status() {
  if [[ -f "package.json" || -f ".nvmrc" || -f "node_modules" ]]; then
    local node_version=$(node --version 2>/dev/null)
    if [[ -n "$node_version" ]]; then
      echo "%F{green}⬢ ${node_version#v}%f | "
    fi
  fi
}

# SEGMENT/DIRECTORY_INFO -------------------------------------------------------

dir_info() {
  local username=$(whoami)
  echo "%F{242}($username)%f "
}

# SEGMENT/DOCKER_STATUS --------------------------------------------------------

docker_status() {
  if [[ -f "Dockerfile" || -f "docker-compose.yml" || -f "docker-compose.yaml" ]]; then
    echo "%F{blue}🐳%f | "
  fi
}

# ENV/VARIABLES/PROMPT_LINES ---------------------------------------------------

# PS1 arrow - green # PS2 arrow - cyan # PS3 arrow - white

PROMPT="%F{235}${char_up_and_right_divider} ${ssh_marker} %f%F{cyan}%~%f$(dir_info)$(prepareGitStatusLine)
%F{green} ${char_arrow}%f "

# Show exit status, time, battery, python env, node env, docker status, and command execution time in RPROMPT
RPROMPT='$(cmd_exec_time)$(docker_status)$(node_env_status)$(python_env_status)$(if [[ $LAST_EXIT_STATUS -ne 0 ]]; then echo "%F{red}✗ $LAST_EXIT_STATUS%f | "; fi)%F{yellow}%*%f | $(battery_status)'

# PS2 Example 
# wc << EOF 
# wc << HEAR 
PS2="%F{black} %_ %f%F{cyan}${char_arrow} "

# PS3 The value of this parameter is used as the prompt for the select
# command (see SHELL GRAMMAR above).
# PS3 Example 
# select x in foo bar baz; do echo $x; done
PS3=" ${char_arrow} "

# ENV/HOOKS --------------------------------------------------------------------

# Show exit status of last command in prompt
precmd() {
  if [[ $VCS != "" ]]; then
    vcs_info
  fi
  printPsOneLimiter
  export LAST_EXIT_STATUS=$?
}

# ENV/VARIABLES/LS_COLORS ------------------------------------------------------

LSCOLORS=gxafexdxfxagadabagacad
export LSCOLORS                                                             #BSD

LS_COLORS="di=36:ln=30;45:so=34:pi=33:ex=35:bd=30;46:cd=30;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"
export LS_COLORS                                                            #GNU

# ENV/VARIABLES/LESS AND MAN ---------------------------------------------------

export LESS='--quit-if-one-screen --ignore-case --status-column --LONG-PROMPT --RAW-CONTROL-CHARS --HILITE-UNREAD --tabs=4 --no-init --window=-4'
export LESS_TERMCAP_mb=$'\x1b[0;36m'                                # begin bold
export LESS_TERMCAP_md=$'\x1b[0;34m'                               # begin blink
export LESS_TERMCAP_me=$'\x1b[0m'                             # reset bold/blink
export LESS_TERMCAP_so=$' \x1b[0;42;30m '                  # begin reverse video
export LESS_TERMCAP_se=$' \x1b[0m'
export LESS_TERMCAP_us=$'\x1b[0m\x1b[0;32m'                    # begin underline
export LESS_TERMCAP_ue=$'\x1b[0m'                              # reset underline
export GROFF_NO_SGR=1     

# SEGMENT/COMPLETION -----------------------------------------------------------

setopt MENU_COMPLETE

completion_descriptions="%F{blue} ${char_arrow} %f%%F{green}%d%f"
completion_warnings="%F{yellow} ${char_arrow} %fno matches for %F{green}%d%f"
completion_error="%B%F{red} ${char_arrow} %f%e %d error"

zstyle ':completion:*' completer _expand _complete _ignored _approximate
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/.zcompcache"
zstyle ':completion:*' verbose yes
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list "m:{a-z}={A-Z}"
zstyle ':completion:*' group-name ''

zstyle ':completion:*:*:*:*:descriptions' format $completion_descriptions
zstyle ':completion:*:*:*:*:corrections' format $completion_error
zstyle ':completion:*:*:*:*:default' list-colors ${(s.:.)LS_COLORS} "ma=0;42;30"
zstyle ':completion:*:*:*:*:warnings' format $completion_warnings
zstyle ':completion:*:*:*:*:messages' format "%d"

zstyle ':completion:*:expand:*' tag-order all-expansions
zstyle ':completion:*:approximate:*' max-errors "reply=( $(( ($#PREFIX+$#SUFFIX)/3 )) numeric )"
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters
zstyle ':completion:*:*:(^rm):*:*files' ignored-patterns "*?.o" "*?.c~" "*?.old" "*?.pro"
zstyle ':completion:*:functions' ignored-patterns "_*"

zstyle -e ':completion:*:(ssh|scp|sftp|rsh|rsync):hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'

zstyle ':completion:*:parameters' list-colors '=*=34'
zstyle ':completion:*:options' list-colors '=^(-- *)=34'
zstyle ':completion:*:commands' list-colors '=*=1;34'

# ------------------------------------------------------------------------------
