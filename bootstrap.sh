#!/bin/bash
set -euo pipefail
set -x

have() { command -v "$1" >/dev/null 2>&1; }
# VENV FOR ANSIBLE-PULL
# VENV_DIR="${HOME}/.config/ansible-zsh/venv"
      #  --use-feature <feature>
      #         Enable new functionality, that may be backward incompatible.

      #         (environment variable: PIP_USE_FEATURE)
export PIP_USE_FEATURE=fast-deps
export PIP_NO_BUILD_ISOLATION=true
export PIP_DISABLE_PIP_VERSION_CHECK=true
# --- Python / Pip behavior tuning (still useful even with pipx) ---
export PIP_PREFER_BINARY=1
export PYTHONOPTIMIZE=2
export PYTHONNOUSERSITE=1
export PYTHONDONTWRITEBYTECODE=1
export PYTHONHASHSEED=0
# Always use a shared pip cache for speed
export PIP_CACHE_DIR="${PIP_CACHE_DIR:-$HOME/.cache/pip}"

# Optional helper if you want to export these in your shell later
ansible_local_env() {
  export ANSIBLE_CONNECTION=local
  export ANSIBLE_FORKS=20
  export ANSIBLE_GATHERING=explicit
  export ANSIBLE_HOST_KEY_CHECKING=False
}

# You no longer need a venv dir; ansible is managed by pipx
: "${ANSIBLE_VERSION:=ansible>=9}"   # e.g. ansible==9.5.1 if you want pinning

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

ensure_path_has_local_bin() {
  # Make sure ~/.local/bin is on PATH so pipx shims are found
  if [ -d "$HOME/.local/bin" ]; then
    case ":$PATH:" in
      *":$HOME/.local/bin:"*) : ;;
      *) export PATH="$HOME/.local/bin:$PATH" ;;
    esac
  fi
}

# 1) Ensure Python + pipx exist (brew on macOS, apt/dnf/etc on Linux)
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
      # pipx pulls Python as a dep; git is just useful
      brew install -q pipx git >/dev/null 2>&1 || true
      ;;

    Linux)
      if have apt-get; then
        sudo env DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTS update -y -qq
        sudo env DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTS install -y -qq \
          python3 python3-pip pipx git
      elif have dnf; then
        sudo dnf install -y python3 python3-pip pipx git || {
          # Fallback if pipx package missing
          sudo dnf install -y python3 python3-pip git
          python3 -m pip install --user pipx
        }
      elif have yum; then
        sudo yum install -y python3 python3-pip git
        python3 -m pip install --user pipx
      elif have pacman; then
        sudo pacman -Sy --noconfirm --needed python python-pipx git || {
          sudo pacman -Sy --noconfirm --needed python python-pip git
          python -m pip install --user pipx
        }
      elif have zypper; then
        sudo zypper --non-interactive in python3 python3-pip pipx git || {
          sudo zypper --non-interactive in python3 python3-pip git
          python3 -m pip install --user pipx
        }
      else
        echo "No supported package manager found; trying to install pipx via pip" >&2
        if have python3; then
          python3 -m pip install --user pipx
        elif have python; then
          python -m pip install --user pipx
        else
          echo "Python not found; cannot install pipx" >&2
          exit 1
        fi
      fi
      ;;

    *)
      echo "Unsupported OS: $(uname -s)" >&2
      exit 1
      ;;
  esac

  ensure_path_has_local_bin

  # Make sure pipx knows to add itself to PATH (it prints a message if needed)
  if have pipx; then
    pipx ensurepath || true
  fi
}

# 2) Ensure ansible is installed via pipx
ensure_ansible_pipx() {
  if ! have pipx; then
    ensure_prereqs
  fi

  ensure_path_has_local_bin

  # If ansible is already on PATH, assume user is happy with it.
  # If you *always* want pipx to own ansible, remove the `have ansible` guard.
  if ! have ansible; then
    # Install Ansible via pipx; include deps so its bundled tools work
    pipx install "${ANSIBLE_VERSION}" --include-deps || {
      echo "Failed to install Ansible via pipx" >&2
      exit 1
    }
  fi
}

# 3) Bootstrap: ensure pipx + ansible, then exit
ensure_ansible_pipx

# Optional: if you want the script to also prep env vars for local runs,
# uncomment this:
# ansible_local_env

# At this point, `ansible` (and ansible-playbook, etc.) should be available
# on your normal PATH, managed by pipx.
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
