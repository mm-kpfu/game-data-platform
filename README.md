# Game data platform

This repository allows you to easily rotate and scale the platform for data processing in Yandex Cloud. 

Platform main components: 
* ManagedKafka
* ManagedClickhouse 
* ManagedKubernetes
* * Apache Flink (via flink-kubernetes-operator)
  * Apache Superset
  * Cert-manager
  * Sealed secrets
  * ArgoCD
  * Ingress nginx

Almost every component can be disabled if you don't need it.
Platform deployment consists of 3 steps:
```
terraform apply
helm install gdp-preinstall
helm install gdp
```
For detailed settings, go to the appropriate directories.

The platform undertakes:
* Configuring the entire network and security groups
* Deploying a load balancer and configuring tls for it. 
* Automatic deployment when your values.yaml changes with ArgoCD
* Thanks to sealed secrets and scripts for integration into your CI-CD pipeline, encryption of your secrets based on environment variables
* As well as setting up roles in the kubernetes cluster and an image with Yandex SSL Certificate and pyflink.
