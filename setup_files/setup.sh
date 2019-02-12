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

pip install pep8
pip install virtualenvwrapper
# export WORKON_HOME=~/virtualenvs

npm install -g jshint

brew intstall git
brew install nvim
# symlink some things, probably I'm forgetting some stuff
ln -s ~/dotfiles/vimrcs/.vimrc ~/.vimrc
ln -s ~/dotfiles/zsh/.zshrc ~/.zshrc

brew install --HEAD universal-ctags/universal-ctags/universal-ctags
# for already setup projects just do a `git init` in the same directory as .git
# https://tbaggery.com/2011/08/08/effortless-ctags-with-git.html
git config --global init.templatedir '~/.git_template'
mkdir -p ~/.git_template/hooks
cp ~/dotfiles/setup_files/ctags ~/.git_template/hooks/ctags
sudo chmod a+x ~/.git_template/hooks/ctags

for f in post-commit post-merge post-checkout
do
echo '
#!/bin/sh
.git/hooks/ctags >/dev/null 2>&1 &
' >  ~/.git_template/hooks/$f
sudo chmod a+x ~/.git_template/hooks/$f
done

echo '
#!/bin/sh
case "$1" in
  rebase) exec .git/hooks/post-merge ;;
esac
' > ~/.git_template/hooks/post-rewrite
sudo chmod a+x ~/.git_template/hooks/post-rewrite
