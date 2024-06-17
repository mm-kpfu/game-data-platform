#!/bin/bash

apt-get install curl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
chmod +x kubectl
mkdir -p ~/.local/bin
mv ./kubectl ~/.local/bin/kubectl
echo "$GDP_KUBECONFING" > gdp_config.conf

KUBECONFIG="$(pwd)/gdp_config.conf"
export KUBECONFIG

KUBESEAL_VERSION='0.26.2'
wget "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION:?}/kubeseal-${KUBESEAL_VERSION:?}-linux-amd64.tar.gz"
tar -xvzf kubeseal-${KUBESEAL_VERSION:?}-linux-amd64.tar.gz kubeseal
install -m 755 kubeseal /usr/local/bin/kubeseal

python3 prepare_helm_values.py
