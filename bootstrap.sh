#!/bin/bash

# slightly modified
# https://raw.github.com/gf3/dotfiles/master/bootstrap.sh,
# that is exactly what i needed

#-----------------------------------------------------------------------------
# Functions
#-----------------------------------------------------------------------------

# Notice title
notice() { printf  "\033[1;32m=> $1\033[0m\n"; }

# Error title
error() { printf "\033[1;31m=> Error: $1\033[0m\n"; }

# List item
c_list() { printf  "  \033[1;32m✔\033[0m $1\n"; }

# Error list item
e_list() { printf  "  \033[1;31m✖\033[0m $1\n"; }

# Check for dependency
dep() {
  type -p $1 &> /dev/null
  local installed=$?
  if [ $installed -eq 0 ]; then
    c_list $1
  else
    e_list $1
  fi
  return $installed
}

backup() {
  mkdir -p $backupdir
  cd $HOME/.dotfiles
  local files=( $(ls -a) )
  for file in "${files[@]}"; do
      if [ -e $HOME/$file ]; then
          in_array $file "${excluded[@]}" || cp -Rf "$HOME/$file" "$backupdir/$file"
      fi
  done
}

install() {
  local files=( $(ls -a) )
  for file in "${files[@]}"; do
    in_array $file "${excluded[@]}"
    should_install=$?
    if [ $should_install -gt 0 ]; then
      [ -d "$HOME/$file" ] && rm -rf "$HOME/$file"
      cp -Rf "$file" "$HOME/$file"
    fi
  done
}

in_array() {
  local hay needle=$1
  shift
  for hay; do
    [[ $hay == $needle ]] && return 0
  done
  return 1
}


#-----------------------------------------------------------------------------
# Initialize
#-----------------------------------------------------------------------------

backupdir="$HOME/.dotfiles-backup/$(date "+%F-%M")"
dependencies=(git emacs)
excluded=(. .. .git .gitignore bootstrap.sh  README.md)


#-----------------------------------------------------------------------------
# Dependencies
#-----------------------------------------------------------------------------

notice "Checking dependencies"

not_met=0
for need in "${dependencies[@]}"; do
  dep $need
  met=$?
  not_met=$(echo "$not_met + $met" | bc)
done

if [ $not_met -gt 0 ]; then
  error "$not_met dependencies not met!"
  exit 1
fi


#-----------------------------------------------------------------------------
# Install
#-----------------------------------------------------------------------------

# Assumes $HOME/.dotfiles is *ours*
if [ -d $HOME/.dotfiles ]; then
  pushd $HOME/.dotfiles

  # Update Repo
  notice "Updating"
  git pull origin master
  git submodule init
  git submodule update

  # Backup
  notice "Backup up old files ($backupdir)"
  backup

  # Install
  notice "Installing"
  install
else
  # Clone Repo
  notice "Downloading"
  git clone --recursive git://github.com/k4rthik/dotfiles.git $HOME/.dotfiles
  if [ $? != 0 ]; then
    error "Could not git clone, dying"
    exit -1
  fi
  
  pushd $HOME/.dotfiles

  # Backup
  notice "Backup up old files ($backupdir)"
  backup

  # Install
  notice "Installing"
  install
fi


#-----------------------------------------------------------------------------
# Finished
#-----------------------------------------------------------------------------

popd
notice "Done"
exec $SHELL -l
