# Oracle Swarm

WIP

# Requirements

Install on server: working kubernetes node with volume storage

Install on client (not from distro packages!)

- kubectl
- helm
- golang
- tarantool *
- cartridge-cli *

* = on Devuan use: `sudo bash ./tarantool-install-devuan.sh`

# Quick start

make download

make deploy-operator

make deploy-cartridge

make list pods

# Configurations

[operator values.yaml](operator-helm-chart-values.yaml)

[cartridge values.yaml](cartridge-helm-chart-values.yaml)

