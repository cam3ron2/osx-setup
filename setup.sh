#!/usr/bin/env bash
# script to setup osx the way I like it
# feel free to change this to match your own preferences

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

# install xcode
if [[ ! -f ~/Applications/Xcode.app ]]; then
  echo "${yellow}Please install Xcode${reset}"
  echo "${yellow}WARNING: This may take a while${reset}"
  open -a App\ Store.app
fi

# install xcode command-line tools
echo "${yellow}Checking prerequisites${reset}"
xcode-select --install 2>/dev/null
softwareupdate --all --install --force &>/dev/null

# install homebrew, jq, and python3
if ! hash brew 2>/dev/null; then
  brewinstall
fi
checkins jq
checkins python3
checkins git

# configure git
echo "${yellow}Configuring git${reset}"
read -e -p "What is your name? " name
read -e -p "What is your email? " email
if hash git 2>/dev/null; then
  git config --global user.email "${email}"
  git config --global user.name "${name}"
fi

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
source ~/.bash_profile

# install fonts
read -e -p "Install fonts? [y/n] " ans
ans=$(echo ${ans} | tr '[:upper:]' '[:lower:]')
if [[ ${ans} == "y" ]]; then
  echo "${yellow}Installing fonts${reset}"
  oldcwd=$(pwd)
  cd ~/Library
  curl -Ss -L https://github.com/cam3ron2/osx-setup/raw/main/fonts.tgz | tar xz --strip 1 -C Fonts
  cd ${oldcwd}
fi

# install general packages
echo "${yellow}Installing general packages${reset}"
for i in $(curl -Ss https://raw.githubusercontent.com/cam3ron2/osx-setup/main/apps.json | jq -r '.apps.system[]'); do
  checkins ${i}
done

# install docker
echo "${yellow}Installing Docker (without docker desktop)${reset}"
for i in $(curl -Ss https://raw.githubusercontent.com/cam3ron2/osx-setup/main/apps.json | jq -r '.apps.docker[]'); do
  checkins ${i}
done
# Tell Docker CLI to talk to minikube's VM
minikube start &>/dev/null
minikube pause &>/dev/null
minikube docker-env >> ~/.bash_profile
eval $(minikube docker-env)
echo "`minikube ip` docker.local" | sudo tee -a /etc/hosts > /dev/null

# install languages
echo "${yellow}Installing languages${reset}"
for i in $(curl -Ss https://raw.githubusercontent.com/cam3ron2/osx-setup/main/apps.json | jq -r '.apps.lang[]'); do
  checkins ${i}
done
curl -Ss https://raw.githubusercontent.com/cam3ron2/osx-setup/main/go.sh >> ~/.bash_profile
source ~/.bash_profile

# install aws tools
read -e -p "Install aws tools? [y/n] " ans
ans=$(echo ${ans} | tr '[:upper:]' '[:lower:]')
if [[ ${ans} == "y" ]]; then
  echo "${yellow}Installing AWS tools${reset}"
  for i in $(curl -Ss https://raw.githubusercontent.com/cam3ron2/osx-setup/main/apps.json | jq -r '.apps.aws[]'); do
    checkins ${i}
  done
fi 

# install gcp tools
read -e -p "Install GCP tools? [y/n] " ans
ans=$(echo ${ans} | tr '[:upper:]' '[:lower:]')
if [[ ${ans} == "y" ]]; then
  echo "${yellow}Installing GCP tools${reset}"
  for i in $(curl -Ss https://raw.githubusercontent.com/cam3ron2/osx-setup/main/apps.json | jq -r '.apps.gcp[]'); do
    checkins ${i}
  done
fi

# installing azure tools
read -e -p "Install Azure tools? [y/n] " ans
ans=$(echo ${ans} | tr '[:upper:]' '[:lower:]')
if [[ ${ans} == "y" ]]; then
  echo "${yellow}Installing Azure tools${reset}"
  for i in $(curl -Ss https://raw.githubusercontent.com/cam3ron2/osx-setup/main/apps.json | jq -r '.apps.azure[]'); do
    checkins ${i}
  done
fi

# installing kubernetes tools
read -e -p "Install kubernetes tools? [y/n] " ans
ans=$(echo ${ans} | tr '[:upper:]' '[:lower:]')
if [[ ${ans} == "y" ]]; then
  echo "${yellow}Installing Kubernetes tools${reset}"
  for i in $(curl -Ss https://raw.githubusercontent.com/cam3ron2/osx-setup/main/apps.json | jq -r '.apps.kubernetes[]'); do
    checkins ${i}
  done
  curl -Ss https://raw.githubusercontent.com/cam3ron2/osx-setup/main/.bash_profile >> ~/.bash_profile
fi

# installing GNU Utils
read -e -p "Install GNU Utils? [y/n] " ans
ans=$(echo ${ans} | tr '[:upper:]' '[:lower:]')
if [[ ${ans} == "y" ]]; then
  echo "${yellow}Installing GNU Utils${reset}"
  for i in $(curl -Ss https://raw.githubusercontent.com/cam3ron2/osx-setup/main/apps.json | jq -r '.apps.gnu-utils[]'); do
    checkins ${i}
  done
fi 

# installing powerline
read -e -p "Install powerline? [y/n] " ans
ans=$(echo ${ans} | tr '[:upper:]' '[:lower:]')
if [[ ${ans} == "y" ]]; then
  echo "${yellow}Installing Powerline${reset}"
  for i in $(curl -Ss https://raw.githubusercontent.com/cam3ron2/osx-setup/main/apps.json | jq -r '.apps.powerline[]'); do
    checkins ${i}
  done
  curl -Ss https://raw.githubusercontent.com/cam3ron2/osx-setup/main/powerline.sh >> ~/.bash_profile
  source ~/.bash_profile
fi

# wait for xcode
echo "${yellow}Waiting for Xcode to be installed...${reset}"
until [[ -f ~/Applications/Xcode.app ]]; do 
  sleep 1
done
echo "${green}SUCCESS${reset}: Xcode is installed"


# install browser
echo "${yellow}What browser would you like to install?${reset}"
select b in waterfox waterfox-classic chrome chromium firefox vivaldi none; do
  echo "${yellow}Installing ${b}!${reset}"
  case ${b} in
    firefox)
      checkins firefox
      break
    ;;
    waterfox)
      checkins waterfox
      break
    ;;
    waterfox-classic)
      checkins waterfox-classic
      break
    ;;
    chrome)
      checkins google-chrome
      break
    ;;
    chromium)
      checkins chromium
      break
    ;;
    vivaldi)
      checkins vivaldi
      break
    ;;
    edge)
      checkins microsoft-edge
      break
    ;;
    none)
      break
    ;;
  esac
done

# install editor
echo "${yellow}What editor would you like to install?${reset}"
select e in atom vscode sublime none; do
  echo "${yellow}Installing ${e}!${reset}"
  case ${e} in 
    atom)
      checkins atom
      break
    ;;
    vscode)
      checkins visual-studio-code
      break
    ;;
    sublime)
      checkins sublime-text
      break
    ;;
    none)
      break
    ;;
  esac
done

echo "${yellow}Logging in to github...${reset}"
gh auth login

echo "${green}COMPLETE${reset}: Setup is complete!"