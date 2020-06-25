# Deploy wavefront

Provide the required values in values.yaml or in an override file, and deploy with ytt/kapp:

```
export OVERRIDE="-f override-file.yaml"
ytt -f values.yaml $OVERRIDE -f wavefront-proxy.yaml -f kube-state-metrics.yaml -f wavefront-collector.yaml | kapp deploy -a wavefront -n default -y -f -
```