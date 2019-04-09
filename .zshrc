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

export GOPATH="$HOME/go"
export PATH=~/bin:/usr/local/sbin:/usr/local/bin:$PATH
export PATH=/usr/local/opt/ruby/bin:$PATH
export PATH=${PATH}:${HOME}/.composer/vendor/bin;
export PATH="$GOPATH/bin:$PATH"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export NODE_PATH=/usr/local/lib/node_modules
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_162.jdk/Contents/Home
export C_INCLUDE_PATH=/user/local/include
export LIBRARY_PATH=/usr/local/lib
export LANG="en_US.UTF-8"
#export LDFLAGS="-L/usr/local/opt/ruby/lib"
#export CPPFLAGS="-I/usr/local/opt/ruby/include"
#export PKG_CONFIG_PATH="/usr/local/opt/ruby/lib/pkgconfig"
#alias ls="colorls"
alias ll="exa -l -a --git"
#alias cat="bat"
alias ping='prettyping --nolegend'
export ZPLUG_HOME=/usr/local/opt/zplug
source $ZPLUG_HOME/init.zsh

zplug "mafredri/zsh-async", from:github, use:async.plugin.zsh
zplug "zsh-users/zsh-autosuggestions", from:github
zplug "bashofmann/pure", use:pure.zsh, from:github, as:theme
zplug "plugins/composer", from:oh-my-zsh
zplug "plugins/docker", from:oh-my-zsh
zplug "plugins/npm", from:oh-my-zsh
zplug "nojanath/ansible-zsh-completion", from:github
zplug "srijanshetty/zsh-pip-completion", from:github

if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

zplug load

source <(kubectl completion zsh)
source "/usr/local/opt/kube-ps1/share/kube-ps1.sh"
source <(helm completion zsh | sed -E 's/\["(.+)"\]/\[\1\]/g')
source <(velero completion zsh)

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

# tabtab source for serverless package
# uninstall by removing these lines or running `tabtab uninstall serverless`
[[ -f /usr/local/lib/node_modules/serverless/node_modules/tabtab/.completions/serverless.zsh ]] && . /usr/local/lib/node_modules/serverless/node_modules/tabtab/.completions/serverless.zsh
# tabtab source for sls package
# uninstall by removing these lines or running `tabtab uninstall sls`
[[ -f /usr/local/lib/node_modules/serverless/node_modules/tabtab/.completions/sls.zsh ]] && . /usr/local/lib/node_modules/serverless/node_modules/tabtab/.completions/sls.zsh
# tabtab source for slss package
# uninstall by removing these lines or running `tabtab uninstall slss`
[[ -f /usr/local/lib/node_modules/serverless/node_modules/tabtab/.completions/slss.zsh ]] && . /usr/local/lib/node_modules/serverless/node_modules/tabtab/.completions/slss.zsh