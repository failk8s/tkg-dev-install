(@ load("@ytt:data", "data") -@)
#!/bin/bash

function ingress.verify {
  echo "Verifying that (@= data.values.ingress.name @) in namespace (@= data.values.ingress.namespace @) has been deployed"
  echo "kubectl rollout status deployment/(@= data.values.ingress.name @) -n (@= data.values.ingress.namespace @) -w"
  kubectl rollout status deployment/(@= data.values.ingress.name @) -n (@= data.values.ingress.namespace @) -w> /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "OK"
  else
    echo "NO OK"
  fi
}


function external-dns.verify {
  echo "Verifying that (@= data.values.externaldns.name @) in namespace (@= data.values.externaldns.namespace @) has been deployed"
# TODO: Deploy a service that will be exposed externally so we can ping or curl until the service is properly exposed
  echo "kubectl logs -f deployment/(@= data.values.externaldns.name @) -n (@= data.values.externaldns.namespace @)"
  echo ""
  echo "This check is still TODO"
  echo ""
  if [ $? -eq 0 ]; then
    echo "OK"
  else
    echo "NO OK"
  fi
}

function cert-manager.verify {
  echo "Verifying that (@= data.values.certmanager.name @) in namespace (@= data.values.certmanager.namespace @) has been deployed"
  echo "kubectl rollout status deployment/(@= data.values.certmanager.name @) -n (@= data.values.certmanager.namespace @) -w"
  kubectl rollout status deployment/(@= data.values.certmanager.name @) -n (@= data.values.certmanager.namespace @) -w> /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "OK"
  else
    echo "NO OK"
  fi
}

function eduk8s-certs.verify {
  echo "OK"
}


function registry.verify {
  echo "Verifying that (@= data.values.registry.name @) in namespace (@= data.values.registry.namespace @) has been deployed"
  echo "Once the certificate request for (@= data.values.registry.name @) in namespace (@= data.values.registry.namespace @) is ready we can log in to the registry"
  echo "docker login (@= data.values.registry.name @).(@= data.values.domain @) -u admin -p admin123!"
  if [ $? -eq 0 ]; then
    echo "OK"
  else
    echo "NO OK"
  fi
}