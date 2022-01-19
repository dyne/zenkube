# Zenswarm

Orchestrating VMlets as a Swarm of Oracles

![image](https://user-images.githubusercontent.com/148059/149499339-af8c430d-6d3c-4dd7-9029-6bf514867b56.png)

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

# Host setup

## minik8s

On a Debian or Ubuntu with "snapd" installed:

```
snap install core
snap install microk8s --classic
microk8s status
microk8s enable helm
microk8s enable storage
microk8s enable dns
microk8s enable ingress
microk8s enable registry
```

Then to export credentials
```
microk8s config > ~/.kube/config (for clients)
microk8s.kubectl config view > $HOME/.kube/config
```
