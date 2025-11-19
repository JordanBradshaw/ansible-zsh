#!/bin/bash
set -euo pipefail
set -x
have() { command -v "$1" >/dev/null 2>&1; }

# VENV_DIR="${HOME}/.config/ansible-zsh/venv"

export PIP_PREFER_BINARY=1
export PYTHONOPTIMIZE=2
export PYTHONNOUSERSITE=1
export PYTHONDONTWRITEBYTECODE=1
export PYTHONHASHSEED=0
  # Always use a shared pip cache for speed
export PIP_CACHE_DIR="${PIP_CACHE_DIR:-$HOME/.cache/pip}"
ansible_local_env() {
export ANSIBLE_CONNECTION=local
export ANSIBLE_FORKS=20
export ANSIBLE_GATHERING=explicit
export ANSIBLE_HOST_KEY_CHECKING=False
}
: "${VENV_DIR:=$HOME/.config/ansible-zsh/venv}"
: "${ANSIBLE_PYTHON:=python3}"
: "${ANSIBLE_VERSION:=ansible>=8}"   # override if you want pinning, e.g. ansible==9.5.1

APT_OPTS='
-o APT::Acquire::Retries=3
-o Acquire::http::Pipeline-Depth=0
-o Acquire::https::Pipeline-Depth=0
-o APT::Get::Max-Downloads=16
-o APT::Install-Recommends=false
-o Acquire::Languages=none
-o APT::Status-Fd=0
-o APT::Color=true
-o Dpkg::Use-Pty=0
'


# 1) Ensure Python + venv tools exist (brew on macOS, apt/dnf/etc on Linux)
ensure_prereqs() {
  case "$(uname -s)" in
    Darwin)
      if ! have brew; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Add brew to PATH for current shell if needed
        if [ -d /opt/homebrew/bin ]; then
          export PATH="/opt/homebrew/bin:$PATH"
        elif [ -d /usr/local/bin ]; then
          export PATH="/usr/local/bin:$PATH"
        fi
      fi
      brew install -q python git >/dev/null 2>&1 || true
      ;;

    Linux)
      if   have apt-get; then
        sudo env DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTS update -y -qq
        sudo env DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTS install -y -qq \
          ansible
          # python3 python3-venv python3-pip \
          # python3-packaging python3-cryptography python3-yaml python3-jinja2 python3-cffi \
          # libffi-dev libssl-dev git
      elif have dnf; then
        sudo dnf install -y python3 python3-venv python3-pip git
      elif have yum; then
        sudo yum install -y python3 python3-venv python3-pip git
      elif have pacman; then
        sudo pacman -Sy --noconfirm --needed python python-virtualenv git
      elif have zypper; then
        sudo zypper --non-interactive in python3 python3-virtualenv git
      else
        echo "No supported package manager found" >&2
        exit 1
      fi
      ;;

    *)
      echo "Unsupported OS: $(uname -s)" >&2
      exit 1
      ;;
  esac
}

# 2) Create or reuse venv with Ansible inside
ensure_venv() {
  # Create venv only if missing
  if [ ! -x "${VENV_DIR}/bin/python" ]; then
    "${ANSIBLE_PYTHON}" -m venv "${VENV_DIR}"
  fi



  # Upgrade pip tooling once per venv
  "${VENV_DIR}/bin/python" -m pip install --upgrade pip setuptools wheel >/dev/null
  # "${VENV_DIR}/bin/python" -m pip install cryptography cffi PyYAML Jinja2 MarkupSafe >/dev/null

  # Install Ansible only if not already present
  if ! "${VENV_DIR}/bin/python" -m pip show ansible >/dev/null 2>&1; then
    "${VENV_DIR}/bin/python" -m pip install \
      "${ANSIBLE_VERSION}" \
      # ansible-lint \
      >/dev/null
  fi

  # shellcheck disable=SC1091
  . "${VENV_DIR}/bin/activate"
}





# 3) If Ansible already on PATH, great; either way prefer the venv copy
if ! have ansible; then
  ensure_prereqs
fi


# Use it
ansible --version

# export ANSIBLE_ZSH_TARGET="${ANSIBLE_ZSH_TARGET:-$1}"
export ANSIBLE_ZSH_TARGET="${ANSIBLE_ZSH_TARGET:-${1:-default}}"
if [[ -n ${REMOTE_CONTAINERS-} ]]; then
    ansible_local_env
    ansible-playbook site.yml --skip-tags zsh-systemd
    # Fallback for default naming convention
elif [[ "${ANSIBLE_ZSH_TARGET,,}" == "devcontainer*" ]]; then
    ansible_local_env
    ansible-playbook site.yml --skip-tags zsh-systemd
elif [[ "${ANSIBLE_ZSH_TARGET,,}" == "wsl" ]]; then
    ansible_local_env
    ansible-playbook site.yml --skip-tags zsh-systemd -vv -K
fi




# ensure_venv

# zsh
