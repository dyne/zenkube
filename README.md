# Zenswarm

Orchestrating VMlets as a Swarm of Oracles

![image](https://user-images.githubusercontent.com/148059/149499339-af8c430d-6d3c-4dd7-9029-6bf514867b56.png)

# Requirements

Install on server: working kubernetes node with volume storage

Install on client (not from distro packages!)

- GNU make
- docker
- kubectl
- helm
- golang >= 1.17
- tarantool *
- cartridge-cli *

Make sure you have kubectl configured with credentials to a kubernetes
cluster and docker connected to its hub to push images.

* = on Devuan use: `sudo bash ./tarantool-install-devuan.sh`

# Usage

Type `make` for an overview of commands:

```
Usage:
  make <target>

General
  help             Display this help.
  show-config      Show the current configuration
  install-deps     install dependencies: golang, kubectl, helm (needs root)

App management
  app-create       Create a new app with APP
  app-defaults     Reset defaults in an existing app with APP
  app-build        Build Docker image from APP/cartridge
  app-push         Push the Docker image of APP
  app-install      Install the Helm APP/chart in namespace zenswarm-APP
  app-port-fwd     Open access to APP via localhost (Ctrl-C to stop)
  app-logs         Show logs of all running pods of APP
  app-status       Check the status of installed APP
  app-uninstall    Uninstall the APP
  app-uninstall-f  Force uninstall the APP (--no-hooks)

Cluster setup
  op-download      clone tarantool-operator from github
  op-build         Build docker image
  op-push          Push docker to repo (default needs credentials)
  op-install       Helm install operator on Kubernetes
  op-uninstall     Helm uninstall operator on Kubernetes
  op-restart       Helm restart operator
  op-status        Show status of operator
  op-logs          Show logs of operator

Cluster administration
  list             List all apps in our namespaces
  list-pods        List pods in our namespace
  list-all         List all in all namespaces
  logs             Show logs for all running APPs
```

## Quick Start

1. `make op-download` will clone `tarantool-operator`
2. `make op-build` will build the docker image of `tarantool-operator`
3. `make op-push` will push the docker image of `tarantool-operator` on your docker hub account
4. `make op-install` will tell your kubernetes cluster to install your `tarantool-operator` docker image and make it run in its own namespace

Now you are ready to create tarantool apps that include the [zenroom](https://github.com/dyne/lua-zenroom) extension for crypto operations, the example one is `benchmark.app` showing results of zenroom's benchmarks on `/benchmark`. To build and deploy it:

1. `APP=benchmark make app-build` to build the `zenswarm-benchmark` docker image
2. `APP=benchmark make app-push` to push the app on your docker hub
3. `APP=benchmark make app-install` to tell your kubernetes cluster to install the app and start its pods
4. `APP=benchmark make app-list` to check that the app is running
5. `APP=benchmark make app-port-fwd` to open a tunnel to your app on localhost port 8081

## App development

To create a new app just specify its name and use app-create:
`APP=myapp make app-create` and `APP=myapp make app-create-chart`.

Then step inside the `myapp.app` folder and write your code in
`custom.app`, it can require more Lua code if you put it inside
`myapp.app/cartridge`. You can open new roles by creating them in
`myapp.app/cartridge/app/roles/`.

Once done build your app into a docker image with `APP=myapp make
app-build` and push it to your docker hub with `APP=myapp make
app-push` where it will be named `zenswarm-myapp`.

At this point to install your app on the kubernetes cluster,
eventually edit `values.yaml` (see tarantool-operator documentation
for details) and use `APP=myapp make app-install`.

## App Management

Using `make list` one can see all apps (and their pods) running on the cluster.

Using `make logs` one can see all the logs of all pods running on the cluster.

# Acknowledgements

Tarantool operator is Copyright (c) 2019, Tarantool, BSD 2-Clause License

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
