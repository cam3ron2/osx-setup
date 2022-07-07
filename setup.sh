#!/usr/bin/env bash
# script to setup osx the way I like it
# feel free to change this to match your own preferences

set -ex

export TERM="xterm-256color"
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

checkins() {
  local pkg flags
  read pkg flags <<< ${@}
  if ! hash ${pkg} 2>/dev/null; then
    brew install --quiet ${pkg} ${flags} &>/dev/null
  else
    echo " * ${green}SUCCESS${reset}: ${pkg} is installed"
  fi
}

# install homebrew
brewinstall() {
  local dir ans oldcwd=$(pwd)
  echo "${yellow}Installing Homebrew${reset}"
  read -e -p "What directory should we install to? (ex: /usr/local/bin): " dir
  while [[ ! -d ${dir} ]]; do
    echo " * ${yellow}WARN${reset}: supplied direcotry does not exist"
    read -e -p "Would you like to create it? [y/n] " ans
    ans=$(echo ${ans} | tr '[:upper:]' '[:lower:]')
    if [[ ${ans} == "y" ]]; then
      mkdir -p ${dir}
    else
      echo " * ${red}ERROR${reset}: please supply a valid directory"
    fi
    read -e -p "Homebrew Install Directory: " dir
  done
  sudo mkdir -p ${dir}/homebrew
  sudo chown -R $(whoami) ${dir}/homebrew
  cd ${dir}
  [[ ! -f ${dir}/homebrew/bin/brew ]] && curl -Ss -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
  eval "$(homebrew/bin/brew shellenv)"
  brew update --force --quiet
  chmod -R go-w "$(brew --prefix)/share/zsh"
  cd ${oldcwd}
  if hash brew 2>/dev/null; then
    echo " * ${green}SUCCESS${reset}: Homebrew installed"
    checkins jq
    checkins python3
  else
    echo " * ${red}ERROR${reset}: Homebrew failed to install"
  fi
}

checkgrp() {
  local ans grp ask=false
  read grp ask <<< ${@}
  if ${ask}; then
    read -e -p "${yellow}Install ${grp}?${reset} [y/n] " ans
    ans=$(echo ${ans} | tr '[:upper:]' '[:lower:]')
  else
    ans="y"
  fi
  if [[ ${ans} == "y" ]]; then
    case ${grp} in
      kubernetes-tools)
        grep '# Functions' ~/.bash_profile || curl -Ss https://raw.githubusercontent.com/cam3ron2/osx-setup/main/.bash_profile >> ~/.bash_profile
        ;;
      powerline)
        for i in $(curl -Ss https://raw.githubusercontent.com/cam3ron2/osx-setup/main/apps.json | jq -r --arg grp ${grp} ".apps.$grp[]"); do
          pip3 install ${i}
        done
        grep '# Powerline' ~/.bash_profile || curl -Ss https://raw.githubusercontent.com/cam3ron2/osx-setup/main/powerline.sh >> ~/.bash_profile
        ;;
      *)
        for i in $(curl -Ss https://raw.githubusercontent.com/cam3ron2/osx-setup/main/apps.json | jq -r --arg grp ${grp} ".apps.$grp[]"); do
          checkins ${i}
        done
        ;;
    esac 
  fi
}

# install xcode command-line tools
echo "${yellow}Checking prerequisites${reset}"
xcode-select --install 2>/dev/null || true
softwareupdate --all --install --force &>/dev/null
sudo xcodebuild -license accept

# install homebrew, jq, and python3
if ! hash brew 2>/dev/null; then
  brewinstall
fi
checkins jq
checkins python3
checkins git

# setup bash_profile
if grep 'BASH_SILENCE_DEPRECATION_WARNING' ~/.bash_profile &>/dev/null; then
  echo "export BASH_SILENCE_DEPRECATION_WARNING=1" >> ~/.bash_profile
fi
if grep 'HOMEBREW_PREFIX' ~/.bash_profile &>/dev/null; then
  if hash brew 2>/dev/null; then
    echo "# Homebrew" >> ~/.bash_profile
    brew shellenv >> ~/.bash_profile
    echo "# End Homebrew" >> ~/.bash_profile
  fi
fi

# install fonts
read -e -p "${yellow}Install fonts?${reset} [y/n] " ans
ans=$(echo ${ans} | tr '[:upper:]' '[:lower:]')
if [[ ${ans} == "y" ]]; then
  echo "${yellow}Installing fonts${reset}"
  oldcwd=$(pwd)
  cd ~/Library
  curl -Ss -L https://github.com/cam3ron2/osx-setup/raw/main/fonts.tgz | tar xz --strip 1 -C Fonts
  cd ${oldcwd}
fi

# install system packages
checkgrp system

# install docker
checkgrp docker

# Tell Docker CLI to talk to minikube's VM
status=$(minikube status 2>/dev/null)
[[ $(echo ${status} | grep host | awk '{print $2}') != "Running" ]] && minikube start &>/dev/null
[[ $(echo ${status} | grep kubelet | awk '{print $2}') == "Running" ]] && minikube pause &>/dev/null
[[ $(grep -c MINIKUBE_ACTIVE_DOCKERD ~/.bash_profile) -lt 1 ]] && minikube docker-env >> ~/.bash_profile
[[ $(grep -c docker.local /etc/hosts) -lt 1 ]] && echo "`minikube ip` docker.local" | sudo tee -a /etc/hosts > /dev/null
eval $(minikube docker-env)

# install packages
checkgrp languages
checkgrp aws-tools true
checkgrp gcp-tools true
checkgrp azure-tools true
checkgrp kubernetes-tools true
checkgrp gnu-utils true
checkgrp powerline

# install browser
echo "${yellow}What browser would you like to install?${reset}"
select b in firefox waterfox waterfox-classic google-chrome chromium vivaldi microsoft-edge none; do
  echo "${yellow}Installing ${b}!${reset}"
  case ${b} in
    none)
      break
    ;;
    *)
      checkins ${b}
      defaultbrowser ${b}
      break
    ;;
  esac
done

# install editor
echo "${yellow}What editor would you like to install?${reset}"
select e in atom visual-studio-code sublime-text none; do
  echo "${yellow}Installing ${e}!${reset}"
  case ${e} in
    none)
      break
    ;; 
    *)
      checkins ${e}
      break
    ;;
  esac
done

echo "${yellow}Logging in to github...${reset}"
gh auth login

source ~/.bash_profile
echo "${green}COMPLETE${reset}: Setup is complete!"