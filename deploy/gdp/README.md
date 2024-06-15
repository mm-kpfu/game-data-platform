# GDP Chart

Helm Chart for gdp components:
1. Flink-kubernetes-operator
2. ArgoCD app
3. Superset

values.yaml includes the parameters configured for gdp.

* The secrets department is compiled by [prepare_helm_values.py](https://github.com/mm-kpfu/game-data-platform/blob/main/deploy/scripts/prepare_helm_values.py) 
or values ​​manually sealed using [sealed-secrets](https://github.com/bitnami-labs/sealed-secrets), 
from which SealedSecret's are then generated.
* * When specifying a domain in the **_ingress.domain_** key, ingress routing via argocd, flink, superset is enabled.
Routing works based on subdomains: for argocd - argocd, for superset - superset, for flink - flink-{availability zone}. 
  * To use tls you need to specify the keys **_certManager.issuer.email_**={email} and **_ingress.use_tls_**=true. 
  Acme (let's encrypt) is used for encryption.
* You also need to specify **_argocd-apps.applications.gdp.repoURL_** and in **_argocd-apps.applications.gdp.valueFiles_** - $gdp-values/path/to/values.yaml.
* The **_deployments_** key stores information about the availability zones in which flinkdeployment should be deployed.

For other parameters, see the corresponding dependency documentation.
