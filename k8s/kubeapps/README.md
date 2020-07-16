# Get kubeapps token

```
kubectl get -n kubeapps secret $(kubectl get serviceaccount kubeapps-cluster-admin -n kubeapps -o jsonpath='{.secrets[].name}') -o jsonpath='{.data.token}' | base64 --decode
```