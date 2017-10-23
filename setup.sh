#!/bin/bash
# WIP

# install homebrew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
# install npm
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"


# install nerd-fonts for powerline stuff
brew tap caskroom/fonts
brew cask install font-hack-nerd-font
