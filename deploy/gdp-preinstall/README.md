# GDP preinstall chart

The chart is used to preinstall components for the gdp platform - ArgoCD, ingress-nginx, cert-manager, sealed-secrets 
and creating a namespace for cert-manager.

Specify **_ingress-nginx.controller.service.loadBalancerIP_** if you want to use an IP-bound domain with ingress.

For argocd, tls is disabled by default, since it is assumed that the domain and common ingress with tls for all resources will be used.
