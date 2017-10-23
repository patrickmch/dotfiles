#!/bin/bash
# WIP

# install homebrew
# ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
# install npm
# ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew install zsh
# set zsh as default shell
sudo -s 'echo /usr/local/bin/zsh >> /etc/shells' && chsh -s /usr/local/bin/zsh

# install fonts (copy them to Fonts directory)
cp -R ~/dotfiles/fonts/. ~/Library/Fonts

pip install ipython
pip install bpython
pip install pdbpp
pip install homely
pip install pep8
pip install virtualenvwrapper
# export WORKON_HOME=~/virtualenvs

npm install -g jshint
