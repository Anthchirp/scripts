#!/bin/bash
set -eux

# Increase swap file to 8GB
swapoff -a
fallocate -l 8G /swap.img
mkswap /swap.img

# Allow / to fill up to 99%
tune2fs -m 1 $(findmnt -nuT / --output=source)

# Set up Jenkins workspace
ln /home/jenkins /jenkins -s
mkdir /jenkins/workspace
chown jenkins.jenkins /jenkins/workspace

# Update system and install useful packages
export NEEDRESTART_SUSPEND=1
apt-get update -y
apt-get dist-upgrade -y
apt-get install \
    build-essential \
    default-jre-headless \
    git \
    make \
    nano \
    open-vm-tools \
    python3-pip \
    vim \
    -y

# Install earthly
wget https://github.com/earthly/earthly/releases/latest/download/earthly-linux-amd64 -O /usr/local/bin/earthly
chmod +x /usr/local/bin/earthly
/usr/local/bin/earthly bootstrap --with-autocomplete

# Eye candy
rm /etc/update-motd.d/{10,60}-*
sed -i 's/Welcome to %s/Welcome to \\033[1m%s\\033[0m/' /etc/update-motd.d/00-*

for bashrc in /home/jenkins/.bashrc /root/.bashrc; do
cat <<'EOF' >>$bashrc

function __ps1_git () {
 # preserve exit status
 local exit=$?
 local repo_info
 repo_info="$(git rev-parse --git-dir --is-inside-git-dir --is-inside-work-tree 2>/dev/null)"
 if [ -z "$repo_info" ]; then
  return $exit
 fi

 local inside_worktree="${repo_info##*$'\n'}"
 repo_info="${repo_info%$'\n'*}"
 local inside_gitdir="${repo_info##*$'\n'}"
 local gitdir="${repo_info%$'\n'*}"

 echo -en "\001\033[1;33m\002["
 if [ "true" = "$inside_gitdir" ]; then
  echo -n ".git"
 elif [ "true" = "$inside_worktree" ]; then
  if [[ -z $(git status --porcelain) ]]; then
   echo -ne "\001\033[0;32m\002"
  else
   echo -ne "\001\033[1;31m\002"
  fi
  BRANCH=`git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
  echo -n $BRANCH
  REMOTE=`git for-each-ref --format='%(upstream:short)' $(git symbolic-ref -q HEAD)`
  if [ "$REMOTE" != "" ]; then
   AHEAD=`git rev-list $REMOTE..HEAD --count`
   BEHIND=`git rev-list HEAD..$REMOTE --count`
   if [ "$BEHIND" != "0" ]; then echo -ne "\001\033[1;31m\002-$BEHIND"; fi
   if [ "$AHEAD" != "0" ]; then echo -ne "\001\033[1;32m\002+$AHEAD"; fi
  fi
  local extmode=""
  if [ -d "$gitdir/rebase-merge" ]; then
   extmode="rebase"
  elif [ -d "$gitdir/rebase-apply" ]; then
   extmode="rebase"
  elif [ -f "$gitdir/MERGE_HEAD" ]; then
   extmode="merge"
  elif [ -f "$gitdir/CHERRY_PICK_HEAD" ]; then
   extmode="cherry"
  elif [ -f "$gitdir/REVERT_HEAD" ]; then
   extmode="revert"
  elif [ -f "$gitdir/BISECT_LOG" ]; then
   extmode="bisect"
  fi
  if [ ! -z "$extmode" ]; then
   echo -en "\001\033[1;33m\002|$extmode"
  fi
  if [ "bisect" = "$extmode" ]; then
   echo -en "\001\033[1;34m\002:`git bisect visualize --oneline 2>/dev/null | wc -l`"
  fi
 fi
 echo -en "\001\033[1;33m\002] "
}
EOF
done

cat <<'EOF' >>/home/jenkins/.bashrc
PS1="\[\033[1;35m\]\h \[\033[1;34m\]\W \`if [ \$? = 0 ]; then echo '\[\033[1;32m\]:)'; else echo '\[\033[1;31m\]:('; fi\` \`__ps1_git\`\[\033[0m\]\$ "
function gitoff () {
 PS1="\[\033[1;35m\]\h \[\033[1;34m\]\W \`if [ \$? = 0 ]; then echo '\[\033[1;32m\]:)'; else echo '\[\033[1;31m\]:('; fi\` \[\033[0m\]\$ "
}
EOF
cat <<'EOF' >>/root/.bashrc
PS1="\[\033[1;31m\]\h \[\033[1;34m\]\W \`if [ \$? = 0 ]; then echo '\[\033[1;32m\]:)'; else echo '\[\033[1;31m\]:('; fi\` \`__ps1_git\`\[\033[0m\]\$ "
function gitoff () {
 PS1="\[\033[1;31m\]\h \[\033[1;34m\]\W \`if [ \$? = 0 ]; then echo '\[\033[1;32m\]:)'; else echo '\[\033[1;31m\]:('; fi\` \[\033[0m\]\$ "
}
EOF

reboot
