# System-wide .bashrc file for interactive bash(1) shells.
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
export BASH_SILENCE_DEPRECATION_WARNING=1
export POWERLINE_BASH_CONTINUATION=1
export POWERLINE_BASH_SELECT=1

# Powerline
if [ -z "$PS1" ]; then
  return
fi

_update_ps1() {
  PS1=$(powerline-shell $?)
}

if [[ $TERM != linux && ! $PROMPT_COMMAND =~ _update_ps1 ]]; then
  PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
fi

powerline-daemon -q

# Functions
klogin() {
  if [[ -z ${1} ]]; then
    echo "error: you must provide a profile. Ex: 'kuali-build' or 'kuali-student'"
  else
    saml2aws login -a $1 --session-duration=28800
    export AWS_PROFILE=$1
    export KUBECONFIG=~/.kube/config 
  fi
}

iampod() {
  if [[ $# -lt 2 ]]; then
    echo "error: you must provide a serviceAccountName and namespace to test"
  else 
    kubectl run -n ${2} --overrides='{ "spec": { "serviceAccount": "'${1}'" }  }' -it iampod --image=xueshanf/awscli -- bash && kubectl -n ${2} delete po iampod
  fi
}

finalize() {
  kubectl proxy &
  kubectl get namespace ${1} -o json |jq '.spec = {"finalizers":[]}' >temp.json
  curl -k -H "Content-Type: application/json" -X PUT --data-binary @temp.json 127.0.0.1:8001/api/v1/namespaces/${1}/finalize
  kill %1
}

euse() {
  local cluster=${1}
  local region=${2}
  if [[ -z ${cluster} || -z ${region} ]]; then
    echo "You must provide a cluster and a region!"
    echo "Usage: euse [cluster] [region]"
  else
    aws eks --region ${region} update-kubeconfig --name ${cluster} --alias ${cluster}
    kubectl config set-context ${cluster} --namespace=argocd
  fi
}

use () {
  kubectl config use-context ${1}
}

# Aliases 
alias bbox="kubectl run -i --tty busybox --image=gcr.io/google-containers/busybox:latest -- sh && kubectl delete po busybox"
alias fargatepod="kubectl run -n fargate -i --tty alpine --image=alpine:latest -- sh && kubectl -n fargate delete po alpine"
alias alinux="kubectl run -i --tty alpine --image=alpine:latest -- sh && kubectl delete po alpine"
alias armlinux="kubectl apply -f /Users/shiggle/Repos/scripts/kubernetes && sleep 3 && kubectl attach alpine -i -t && kubectl delete po alpine"
alias k="kubectl"
alias l1-ecr="kerb-sts &>/dev/null && aws --profile l1-ops-dev ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 310865762107.dkr.ecr.us-east-1.amazonaws.com"
alias kt="kubectl get nodes -o=custom-columns=NAME:.metadata.name,TAINTS:.spec.taints"
alias evicted="k get po -A | grep Evicted | awk '{print $2, "--namespace", $1}' | xargs kubectl delete pod"
