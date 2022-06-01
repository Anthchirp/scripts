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
mkdir -p /jenkins/workspace
chown jenkins.jenkins /jenkins/workspace

# Set up Jenkins SSH key
mkdir -p /home/jenkins/.ssh
echo no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBfj+MX42Y9TW8Tg0qM6TCudkFPICst4Y3P4FbANXy4U jenkins@jenkins-controller > /home/jenkins/.ssh/authorized_keys2
chown -R jenkins.jenkins /home/jenkins/.ssh
chmod 755 /home/jenkins/.ssh
chmod 644 /home/jenkins/.ssh/authorized_keys2

# Update system and install useful packages
export NEEDRESTART_SUSPEND=1
apt-get update -y
apt-get dist-upgrade -y
apt-get install \
    build-essential \
    default-jre-headless \
    git \
    libldap2-dev \
    libsasl2-dev \
    make \
    nano \
    open-vm-tools \
    vim \
    -y
snap refresh

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

# Install various Python versions using micromamba
cd /home/jenkins
cat <<'EOF' > install-python-environments
#!/bin/bash
set -eux
cd /home/jenkins
rm -rf micromamba
if [ ! -x bin/micromamba ]; then
curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba
fi
PATH=/home/jenkins/bin:$PATH
micromamba create -y -n python37 -c conda-forge python=3.7
micromamba create -y -n python38 -c conda-forge python=3.8
micromamba create -y -n python39 -c conda-forge python=3.9
micromamba create -y -n python310 -c conda-forge python=3.10 conda-wrappers

# One installation of conda-wrappers is enough to generate all wrappers
set +ux
eval "$(micromamba shell hook --shell=bash)"
micromamba activate python310
set -ux
create-wrappers -t conda -f python3.7 --conda-env-dir ~/micromamba/envs/python37 -d ~/bin --use-exec --inline
create-wrappers -t conda -f python3.8 --conda-env-dir ~/micromamba/envs/python38 -d ~/bin --use-exec --inline
create-wrappers -t conda -f python3.9 --conda-env-dir ~/micromamba/envs/python39 -d ~/bin --use-exec --inline
create-wrappers -t conda -f python3.10 --conda-env-dir ~/micromamba/envs/python310 -d ~/bin --use-exec --inline
EOF
chmod +x install-python-environments
chown jenkins.jenkins install-python-environments
su -c - jenkins ./install-python-environments

sed -i '1s;^;export PATH=/home/jenkins/bin:$PATH\n;' /home/jenkins/.bashrc
# this needs prepending as the ubuntu ~/.bashrc bails on non-interactive
# invocation, and Jenkins does not source ~/.profile

# Installation complete. Switch machine off for template cloning
poweroff
