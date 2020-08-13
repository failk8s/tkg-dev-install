# Install Developer Tooling and capabilities on TKG
This repository will help with the deployment and integration of developer required capabilities with Tanzu Kubernetes Grid (TKG) clusters provided by Tanzu Mission Control (TMC).

TKG clusters are deployed on AWS, so you will need to be able to configure some things on AWS to get the full integration. If you have a full AWS account you can have the complete workflow automated. If you have a managed AWS account, you'll have to do some steps manually, mainly because cert-manager has [an issue yet to be resolved](https://github.com/jetstack/cert-manager/issues/2779).

Developers requires:
- Ingress controller
- A DNS domain name
- A wildcard certificate for that DNS domain name
- An image registry (OPTIONAL)
- KPack building capabilities

## Pre-requisites
You need to have your domain configured in Route53. Create a HostedZone for your domain. You can then, use cert-manager to generate a wildcard certificate with Let's Encrypt for your DNS domain, or you can generate the certificate manually and place it in a secret on the platform.

## Install with full AWS integration
These instructions assume you have [ytt](https://get-ytt.io/) and [kapp](https://get-kapp.io/) installed. If you don't have them, go ahead and install them, or use the [k14s docker image](https://hub.docker.com/r/k14s/image).

You will need an AWS IAM user/serviceaccount credentials to configure cert-manager for the DNS01 integration. You can read more [here](https://medium.com/@Amet13/wildcard-k8s-4998173b16c8)

__NOTE__: Before you start installation, you need to verify you're providing the required values in [values.yaml](.k8s/values.yaml) or that you use an override file as explained later.
  
### Deploy cert-manager to manage SSL certificates for you

```
./tkg-dev-install cert-manager [OPTIONS]
```

This will execute under the hood:
```
ytt -f k8s/values.yaml -f k8s/cert-manager --ignore-unknown-comments | kapp deploy -n default -a cert-manager -y -f -
```

### Create your ingress controller
You need to have 2 records in AWS Route53, for your hosted zone, the LB that the ingress controller will create.
  * *.<DOMAIN> 
  * *.apps.<DOMAIN>
Luckily, we have you covered. We will deploy external-dns so that the ingress will create this DNS records for you. Also, we will deploy an ingress controller that will handle your access to your wildcard domains.

```
./tkg-dev-install ingress [OPTIONS]
```

This will execute under the hood:
```
ytt -f k8s/values.yaml -f k8s/ingress --ignore-unknown-comments | kapp deploy -n default -a ingress -y -f -
```

__NOTE__: We will use the [failk8s-operator](https://github.com/failk8s/failk8s-operator) to copy the wildcard certificate into every namespace so that it can be used to secure any route on any namespace.

### Deploy an image registry
Along with the image registry, we deploy a controller that will copy the registry credentials secret in every namespace and add an imagePullSecret to the `default` ServiceAccount on every namespace. See [failk8s-operator](https://github.com/failk8s/failk8s-operator).

```
./tkg-dev-install registry [OPTIONS]
```

This will execute under the hood:
```
ytt -f k8s/values.yaml -f k8s/registry --ignore-unknown-comments | kapp deploy -n default -a registry -y -f -
```

### Deploy image building capabilities

```
./tkg-dev-install kpack [OPTIONS]
```

This will execute under the hood:
```
ytt -f k8s/values.yaml -f k8s/kpack --ignore-unknown-comments | kapp deploy -n default -a kpack -y -f -
```

### Deploy CI/CD/Pipelines building capabilities

```
./tkg-dev-install tekton [OPTIONS]
```

This will execute under the hood:
```
ytt -f k8s/values.yaml -f k8s/tekton/release --ignore-unknown-comments | kapp deploy -n default -a tekton -y -f -
ytt -f k8s/values.yaml -f k8s/tekton/triggers --ignore-unknown-comments | kapp deploy -n default -a tekton-triggers -y -f -
```

### Deploy Scale to Zero capabilities

```
./tkg-dev-install knative [OPTIONS]
```

This will execute under the hood:
```
ytt -f k8s/values.yaml -f k8s/knative --ignore-unknown-comments | kapp deploy -n default -a knative -y -f -
```

### Deploy Application Catalog capabilities

```
./tkg-dev-install kubeapps [OPTIONS]
```

This will execute under the hood:
```
ytt -f k8s/values.yaml -f k8s/kubeapps --ignore-unknown-comments | kapp deploy -n default -a kubeapps -y -f -
```

### Deploy Observability Capabilities

```
./tkg-dev-install wavefront [OPTIONS]
```

This will execute under the hood:
```
ytt -f k8s/values.yaml -f k8s/wavefront --ignore-unknown-comments | kapp deploy -n default -a wavefront -y -f -
```

### Deploy Eduk8s capabilities

```
./tkg-dev-install eduk8s [OPTIONS]
```

This will execute under the hood:
```
ytt -f k8s/values.yaml -f k8s/eduk8s --ignore-unknown-comments | kapp deploy -n default -a eduk8s -y -f -
```

## FULL INSTALLS
There are two complete installations that this installer targets:

- Development environments
- Eduk8s environment

`Eduk8s environment` will contain everything that this installer provides, and `Development environment` will provide the same except for `eduk8s` capabilities.

Choose between one of the following commands to install them.

```
./tkg-dev-install full-dev -c -f <override-file>
./tkg-dev-install full-eduk8s -c -f <override-file>
```

## Override information
If you need to provide your own configuration values, the easiest way is to use an override file instead of modifying the existing values.yaml file.

Create an override file like this, and name it override.yml (or similar). Note that you can have multiple overide files one for each environment if you have many.

```
#@data/values
---
domain: failk8s.dev
wildcard_domain: apps.failk8s.dev
```

__NOTE__: There is an [example override file](override.example.yml) for convenience. Just rename it and adapt your values.
__NOTE__: You can collapse all values into a single file and use it.

Use it with the `-f` flag:

```
./tkg-dev-install <OPTION> -c -f <override-file>
```

### Install without full AWS integration
In this scenario, you will not use cert-manager to create the wildcard certificate (as that is the dependency with AWS credentials) and you can use certbot for that purpose. 

* Follow the steps above to deploy the ingress controller. 
* Generate a wildcard SSL certificate using [certbot](https://jloh.co/posts/certbot-route53-dns-validation/) (or any other tool) and place that certificate in a secret named "" in the default namespace. (NOTE that the name of secret and namespace depends on your variable values.)
* Deploy eduks8-controller following the steps above.
* (OPTIONAL)
  * Deploy an image-registry (You will need to generate a certificate for the image registry yourself)


## NOTES

For external-dns to work, you need to:
* Add __external-dns.alpha.kubernetes.io/hostname__ annotation to the envoy service in the ingress
  * We used __external-dns.alpha.kubernetes.io/hostname: '*.test.eduk8s.io.,*.apps.test.eduk8s.io.'__ 
* Attach a wildcard policy to the assumed role that is being used. We used: 
  * role __nodes.tmc.cloud.vmware.com__
  * AWS policy:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "route53:GetChange",
            "Resource": "arn:aws:route53:::change/*"
        },
        {
            "Effect": "Allow",
            "Action": "route53:ChangeResourceRecordSets",
            "Resource": "arn:aws:route53:::hostedzone/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZones",
                "route53:ListResourceRecordSets"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZonesByName"
            ],
            "Resource": "*"
        }
    ]
}
```

After this, we have 2 new A records in the configured Hosted Zone with the provided domain and wildcard domains.

## Eduk8s usage
Refer to [eduk8s docs](https://docs.eduk8s.io) for info on how to deploy a workshop.

## Teardown

Remove all components.

```
kapp delete -a eduk8s -y -n default
kapp delete -a wavefront -y -n default
kapp delete -a kubeapps -y -n default
kapp delete -a knative -y -n default
kapp delete -a tekton -y -n default
kapp delete -a kpack -y -n default
kapp delete -a registry -y -n default
kapp delete -a ingress -y -n default
kapp delete -a cert-manager -y -n default
```

Also, You need to cleanup the records added to your Route53 hosted zone.
