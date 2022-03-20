# K3D

## Installation
On a Linux based system we can just use the command:
```
wget -q -O - https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
```
The installation options/instructions can be found here:
* https://k3d.io/v5.0.1/#install-current-latest-release

## Configuration
The configuration options along with their explanation can be found here:
* https://k3d.io/usage/configfile/#all-options-example

## Use locally created Docker images
In order to test locally developed Docker images in the local Kubernetes (k3d), we use a local image registry. In order to run a pod with a local alpine image we can use the following commands:
```
docker image tag alpine:3.14 k3d-registry-dev.localhost:5555/alpine/alpine:3.14
docker push k3d-registry-dev.localhost:5555/alpine/alpine:3.14
kubectl run --restart=Never myalpine --image=k3d-registry-dev.localhost:5555/alpine/alpine:3.14 -- /bin/sh -c "sleep 3600"
```