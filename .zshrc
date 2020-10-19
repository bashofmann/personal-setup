HISTFILE=~/.zsh_history
HISTSIZE=10000000                   # big history
SAVEHIST=10000000                   # big history
setopt append_history           # append
setopt hist_ignore_all_dups     # no duplicate
unsetopt hist_ignore_space      # ignore space prefixed commands
setopt hist_reduce_blanks       # trim blanks
setopt hist_verify              # show before executing history commands
setopt inc_append_history       # add commands as they are typed, don't wait until shell exit
setopt share_history            # share hist between sessions
setopt bang_hist                # !keyword
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY

bindkey "\e[3~" delete-char

export GOPATH="$HOME/dev"
export PATH=${HOME}/bin:/usr/local/sbin:/usr/local/bin:$PATH:${HOME}/bin
export PATH=/usr/local/opt/ruby/bin:$PATH
export PATH=${PATH}:${HOME}/.composer/vendor/bin
export PATH="$GOPATH/bin:$PATH"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export PATH=$PATH:${HOME}/bin
export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/make/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
export NODE_PATH=/usr/local/lib/node_modules
export C_INCLUDE_PATH=/user/local/include
export LIBRARY_PATH=/usr/local/lib
export LANG="en_US.UTF-8"
alias ll="exa -l -a --git"
alias ping='prettyping --nolegend'
alias k=kubectl
export ZPLUG_HOME=/usr/local/opt/zplug
source $ZPLUG_HOME/init.zsh

zplug "mafredri/zsh-async", from:github, use:async.zsh
zplug "zsh-users/zsh-autosuggestions", from:github
zplug "bashofmann/pure", use:pure.zsh, from:github, as:theme
zplug "plugins/docker", from:oh-my-zsh

if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

zplug load

source "/usr/local/opt/kube-ps1/share/kube-ps1.sh"
source <(helm completion zsh)
source <(kubectl completion zsh)
source <(k3d completion zsh)

export XDG_DATA_HOME=~/.data

explain () {
  if [ "$#" -eq 0 ]; then
    while read  -p "Command: " cmd; do
      curl -Gs "https://www.mankier.com/api/explain/?cols="$(tput cols) --data-urlencode "q=$cmd"
    done
    echo "Bye!"
  elif [ "$#" -eq 1 ]; then
    curl -Gs "https://www.mankier.com/api/explain/?cols="$(tput cols) --data-urlencode "q=$1"
  else
    echo "Usage"
    echo "explain                  interactive mode."
    echo "explain 'cmd -o | ...'   one quoted command to explain it."
  fi
}

gs() {
    cd $(ghq list --full-path --exact $1)
}

_gs_complete() {
    _values 'gs' $(ghq list --unique)
}

compdef _gs_complete gs

# colorful man pages
man() {
    env \
        LESS_TERMCAP_mb=$(printf "\e[1;31m") \
        LESS_TERMCAP_md=$(printf "\e[1;31m") \
        LESS_TERMCAP_me=$(printf "\e[0m") \
        LESS_TERMCAP_se=$(printf "\e[0m") \
        LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
        LESS_TERMCAP_ue=$(printf "\e[0m") \
        LESS_TERMCAP_us=$(printf "\e[1;32m") \
            man "$@"
}
