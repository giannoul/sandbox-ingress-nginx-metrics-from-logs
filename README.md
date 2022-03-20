# sandbox-ingress-nginx-metrics-from-logs
Trying to get metrics from ingress nginx by parsing the logs


## k3d information
k3d configuration:
* https://k3d.io/v5.0.0/usage/configfile/

k3s configuration options through k3d:
* https://www.suse.com/c/introduction-k3d-run-k3s-docker-src/#:~:text=as%20Code%E2%80%9D%20Way-,As%20of%20k3d%20v4.0.0,-(January%202021)%2C%20we

### k3s without traefik
By default the k3s cluster deployed by k3d will use `traefik` as ingress. If we want to swith to `nginx` ingress then we need to use the option `--no-deploy traefik` and intstall `nginx` ingress via helm. For more details you can check here:
* https://www.suse.com/support/kb/doc/?id=000020082
* https://kubernetes.github.io/ingress-nginx/deploy/#quick-start

What Ingress Controller we are after:
```
~$ kubectl describe daemonsets nginx-ingress-controller -n ingress-nginx | grep Image
    Image:       rancher/nginx-ingress-controller:nginx-0.43.0-rancher1
```
however as per this https://github.com/rancher/ingress-nginx it seems that they have forked it from the upstream official `kubernetes/ingress-nginx`.

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml


ingress-nginx-controller configuration:
* https://kubernetes.github.io/ingress-nginx/examples/customization/custom-configuration/
* https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#log-format-upstream

fluentbit:
* https://coralogix.com/blog/fluent-bit-guide/
* https://fluentbit.io/blog/2020/12/02/supercharge-your-logging-pipeline-with-fluent-bit-stream-processing/ 
