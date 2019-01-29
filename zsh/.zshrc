# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=~/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
# ZSH_THEME="agnoster"
# ZSH_THEME="af-magic"

 if [ "${TERM_PROGRAM}" != "iTerm.app" ]; then
     ZSH_THEME="af-magic"
 else
     ZSH_THEME="powerlevel9k/powerlevel9k"
     source ~/.powerlevel_config
 fi

source ~/.zsh_theme_config
# if [ -f ~/.zsh_theme_config ]; then
#
# else
#     echo "404: ~/.zsh_theme_config not found."
# fi

# zplug: https://github.com/zplug/zplug
export ZPLUG_HOME=/usr/local/opt/zplug
source $ZPLUG_HOME/init.zsh

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git brew npm)

source $ZSH/oh-my-zsh.sh
source ~/.oh-my-zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"
# vim stuff
export VIMCONFIG="~/dotfiles/vimrcs"
export "VIMRC=${VIMCONFIG}/.vimrc"

# ssh
export SSH_KEY_PATH="~/.ssh/rsa_id"

# bpython configuration to work with django:
export PYTHONSTARTUP="/Users/mchey/.pythonrc"
# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Aliases
alias pyhton="python"
alias li="ls -lah"
# alias djrsl='echo hi; cd ~/code/website/nols_website; python manage.py runsslserver 0.0.0.0:8888 --nothreading --settings=mchey_local_settings'
alias startweb='source $NOLSCODE/scripts/start_website.sh'
alias resetdb='source $NOLSCODE/scripts/restart_vm.sh'
alias vim='nvim'
# other configs
. `brew --prefix`/etc/profile.d/z.sh

# add direnv (https://github.com/direnv/direnv) hook
eval "$(direnv hook zsh)"
source ~/.bash_profile
source ${NOLSTOOLS}/nols_env


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
