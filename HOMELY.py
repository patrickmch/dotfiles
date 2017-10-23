from homely.files import mkdir, symlink
from os import listdir, path

dotfiles = '%s/dotfiles/' % path.expanduser('~')

mkdir('%szsh' % dotfiles)
mkdir('%spython' % dotfiles)
symlink('.config')
symlink('.ipython')
symlink('.jupyter')
symlink('.atom')

# create symlinks in home directory from a source directory
def symlinks_from_dir(directory):
    for item in listdir(dotfiles + directory):
        if item == '.DS_Store':
            continue
        file_path = directory + '/' + item
        symlink(file_path, item)


symlinks_from_dir('zsh')
