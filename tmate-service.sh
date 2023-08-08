#!/bin/bash
#
#  Copyright 2023 Tony García
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

SSH_SVC_HOSTNAME="${SSH_HOSTNAME:-localhost}"
SSH_TMATE_LISTEN="${SSH_TMATE_LISTEN:-22}"
SSH_SVC_PORT="${SSH_SVC_PORT:-2222}"
TMATE_IMAGE_REPO="${TMATE_IMAGE_REPO:-localhost/tmate-ssh-server:latest}"
TMATE_REPO="${TMATE_REPO:-https://github.com/tmate-io/tmate-ssh-server.git}"

build=""
force_clone=""
force_keys=""
run=""
push=""

# Print help function
function help() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  --build        Build tmate-ssh-server"
  echo "  --force-clone  Force clone tmate-ssh-server"
  echo "  --force-keys   Force generate keys"
  echo "  --run          Run tmate-ssh-server"
  echo "  --push         Push tmate-ssh-server image to registry"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --build)
            build="true"
            shift
            ;;
        --force-clone)
            force_clone="true"
            shift
            ;;
        --force-keys)
            force_keys="true"
            shift
            ;;
        --help)
            help
            exit 0
            ;;
        --push)
            push="true"
            shift
            ;;
        --run)
            run="true"
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            help
            exit 1
            ;;
    esac
done

# Clone tmate-ssh-server if it doesn't exist or if force_clone is set
if [[ ! -d "tmate-ssh-server" ]] ||
    [[ -n "${force_clone}" ]]; then
      rm -Rf tmate-ssh-server
      git clone "${TMATE_REPO}" tmate-ssh-server
fi

if [[ -n "${build}" ]]; then
    podman build \
      --file Containerfile \
      --tag "${TMATE_IMAGE_REPO}"
fi

if [[ -n "${push}" ]]; then
    podman push "${TMATE_IMAGE_REPO}"
fi

# Create keys if they don't exist or if force_keys is set
if [[ ! -d keys ]] ||
   [[ -n "${force_keys}" ]]; then
    rm -Rf keys config
    mkdir config
    export SSH_SVC_HOSTNAME
    export SSH_SVC_PORT
    ./create_keys.sh > config/client_tmate.conf
fi

# Run tmate-ssh-server when --run is set
if [[ -n "${run}" ]]; then
    podman run \
      --cap-add SYS_ADMIN \
      --detach \
      -e SSH_HOSTNAME="${SSH_HOSTNAME}" \
      -e SSH_KEYS_PATH=/keys \
      -e SSH_PORT_LISTEN="${SSH_TMATE_LISTEN}" \
      -e USE_PROXY_PROTOCOL=0 \
      --name=tmate-ssh-server \
      --publish "${SSH_SVC_PORT}":"${SSH_TMATE_LISTEN}" \
      --volume "${PWD}/keys":/keys:Z \
      "${TMATE_IMAGE_REPO}"
fi
