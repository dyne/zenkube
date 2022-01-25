
# Notes on setting up monitoring

Tested using AWS, your mileage may vary

## Install the metrics server

```
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Now `kubectl top` works.

## Install prometheus

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install --namespace monitoring prometheus-operator prometheus-community/kube-prometheus-stack --set grafana.enabled=true
```

Then to monitor a specific service: https://sysdig.com/blog/kubernetes-monitoring-prometheus/#exporters
