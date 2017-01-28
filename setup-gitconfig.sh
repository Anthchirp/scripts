#!/bin/bash

if [ -e ~/.gitconfig ]; then
  echo Skipping .gitconfig
else
  echo Installing .gitconfig
  cat > ~/.gitconfig <<EOF
[user]
        email = Anthchirp@users.noreply.github.com
        name = Anthchirp
[core]
        editor = vim
[alias]
        ff = pull --ff-only --no-rebase
        up = pull --rebase
        st = status
        hist = log --pretty=format:\"%h %ad | %s%d [%an]\" --graph --date=short
        lol = !git --no-pager log --graph --pretty=oneline --abbrev-commit -20 --decorate
        unstage = reset HEAD
        mkremotebranch = push origin -u
        rmremotebranch = push origin --delete
        obliterate = clean -dffx
        stale = remote prune origin --dry-run
        cleantags = remote prune origin
        mkremotetag = push origin
        rmremotetag = push --delete origin

[color]
        ui = auto
[color "diff"]
        meta = dim white
        func = bold yellow
[push]
        default = current
[pull]
        rebase = true
EOF
fi
