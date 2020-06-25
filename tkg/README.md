# How to deploy eduk8s on a TKG cluster
For the time being, a TKG workload cluster is different than the workload clusters you get trhough TMC, so a set of additional steps need to be taken care when using TKG.


## Register the eduk8s template
We provide a plan template for eduk8s so that some of these steps are done for you just by using the plan. Copy the [cluster template](cluster-template-eduk8s.yaml) to `~/.tkg/providers/infrastructure-aws/v0.5.3/` (or whatever the latest/current version of the provider you're using).

For now, this template is based of the `development plan` template, and changes/adds:
* Enable the PSP admission controller so that we can use PSPs
* Use m5.xlarge AWS instance types for Nodes

## Create a TKG cluster
Now that you have the template, you should be able to create your cluster.

__NOTE__: Remember that you should have a TKG management cluster to create workload clusters.

```
tkg create cluster <my-cluster-name> --plan=eduk8s
```

__NOTE__: If you want more worker nodes, just use `-w <num>` in the previous command.

### Get the cluster credentials
By default, your kubeconfig should have been modified by the tkg cli to have the workload kubeconfig file, but if you want to get the credentials to provide to someone else, you can easily do it by querying the TKG management cluster.

```
kubectl get secret <my-cluster-name>-kubeconfig -n default -o json  | jq -r .data.value | base64 -D -
```

__NOTE__: By default, and unless you specified it otherwise when creating your cluster, the secret with the kubeconfig will be stored in the `default` namespace of the management cluster and will have the name of your cluster with `-kubeconfig` suffix.

__NOTE__: You can redirect this output to a file.

## Post installation steps
TKG cluster does not provide (when compared to a TMC provisioned workload clsuter):

* A default Storage Class
* The VMware PSPs

To apply these you should do:

```
kubectl apply -f storage-class.yaml
kubectl apply -f psp.yaml
```

__NOTE__: Remember you should be connected to your newly created TKG cluster. You can use `--kubeconfig=my-tkg-cluster.yaml` argument to the previous commands.