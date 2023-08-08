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

set -eu

gen_key() {
  keytype=$1
  ks="${keytype}_"
  key="keys/ssh_host_${ks}key"
  if [[ ! -e "${key}" ]] ; then
    ssh-keygen -t "${keytype}" -f "${key}" -N '' &>/dev/null
  fi
  SIG=$(ssh-keygen -l -f "$key.pub" | cut -d ' ' -f 2)
}

mkdir -p keys
gen_key rsa
RSA_SIG=$SIG
gen_key ed25519
ED25519_SIG=$SIG

echo "## Use this configuration in your .tmate.conf:"
echo ""
echo "set -g tmate-server-host ${SSH_SVC_HOSTNAME:-localhost}"
echo "set -g tmate-server-port ${SSH_SVC_PORT:-22}"
echo "set -g tmate-server-rsa-fingerprint ${RSA_SIG}"
echo "set -g tmate-server-ed25519-fingerprint ${ED25519_SIG}"
