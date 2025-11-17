#!/bin/bash
set -euo pipefail

VENV_DIR="${HOME}/.config/ansible-zsh/venv"

have() { command -v "$1" >/dev/null 2>&1; }

# 1) Ensure Python + venv tools exist (brew on macOS, apt/dnf/etc on Linux)
ensure_prereqs() {
  case "$(uname -s)" in
    Darwin)
      have brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      brew install -q python git >/dev/null
      ;;
    Linux)
      if   have apt-get; then sudo apt-get update -y && sudo apt-get install -y python3 python3-venv python3-pip git
      elif have dnf;     then sudo dnf install -y python3 python3-venv python3-pip git
      elif have yum;     then sudo yum install -y python3 python3-venv python3-pip git
      elif have pacman;  then sudo pacman -Sy --noconfirm python python-virtualenv git
      elif have zypper;  then sudo zypper --non-interactive in python3 python3-virtualenv git
      else echo "No supported package manager found"; exit 1; fi
      ;;
    *) echo "Unsupported OS"; exit 1;;
  esac
}

# 2) Create or reuse venv with Ansible inside
ensure_venv() {
  if [ ! -x "${VENV_DIR}/bin/python" ]; then
    python3 -m venv "${VENV_DIR}"
    "${VENV_DIR}/bin/python" -m pip install --upgrade pip wheel
    "${VENV_DIR}/bin/pip" install "ansible>=9" ansible-lint
  fi
  # shellcheck disable=SC1091
  source "${VENV_DIR}/bin/activate"
}

# 3) If Ansible already on PATH, great; either way prefer the venv copy
if ! have ansible; then
  ensure_prereqs
fi

ensure_venv

# Use it
ansible --version

# export ANSIBLE_ZSH_TARGET="${ANSIBLE_ZSH_TARGET:-$1}"
export ANSIBLE_ZSH_TARGET="${ANSIBLE_ZSH_TARGET:-${1:-default}}"
if [[ -n "$REMOTE_CONTAINERS" ]]; then
    ansible-playbook site.yml --skip-tags zsh-systemd
    # Fallback for default naming convention
elif [[ "${ANSIBLE_ZSH_TARGET,,}" == "devcontainer*" ]]; then
    ansible-playbook site.yml --skip-tags zsh-systemd
fi


zsh
