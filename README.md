This project is designed to have:

1- Automatic continuous deployment for deploying monitoring metric scraping resources (servicemonitors and blackboxes), alertmanagers and rules on kubernetes cluster by managing large amount of helm charts using helmfile module.

2- Long-term storage solution for scraped metrics in part 1 by utilizing thanos application.


These goals are achieved by:
1. Generate targets to be processed by thanos (By deploying servicemonitor and blackbox resources) using helmfile (a self-deployed chart) and gitlab-ci.
2. Add rules to be processed by prometheus instance using hekmfile (a self-deployed chart) and gitlab-ci.
3. install alertmanager using helmfile (prometheus-community/alertmanager chart) and gitlab-ci.
4. Install prometheus instances using helm (kube-prometheus chart) by running a shellscript.
5. Long-term storage solution for scraped metrics by installing thanos.

Each prometheus instance (in prometheus-helm-values folder) is responsible for scraping some paramethers. also they are installed in seperate namespaces. To create prometehus instances using namespaces-bucketsecrets-crds.sh script, prometheus-helm-values folder should be added to project as submodule (I did not do it already in this project).

Also my advise is to limit where each prometheus is looking for servicemonitors to its related prometheus namespace (do it in helm chart values.yaml file), so the CPU of apiserver can't go very high.    

All rules are deployed on thanos namespace (but process by prometheus instances).

Alertmanager is deployed on thanos namespaces. this alertmanaget is the endpoint of alertmanger endpoint which is specified on helm values of prometheus instances. the value.yaml related to alert manager is determined at chart/alertmanager/values.yaml

All of the helm charts in chart folder are deployed to K8S cluster using helmfile (see helmfile.yaml file) which will be run (after any commit) in the namespace where gitlab-runner is deployed => [This link](https://https://github.com/rezaebrahimi1/helm-gitlabrunner-monitoring
)

Installing process

Prerequisites

At first, prepare your cluster by deploying:

1- Gitlab-runner for automating CD process of changing metric scraping values (servicemonitors and blackboxes) and also alertmanagers and rules configs.

2- Installing required namespaces and thanos bucket secrets on them.

3- Installing required CRDs.

4- Installing prometheus instances.

Gitlab-runner

The tool which is used to deploy many helm charts in this project is helmfile. To use automatic CD process defined in gitlab-ci.yml, install gitlab-runner in K8S cluster using  this link => https://https://github.com/rezaebrahimi1/helm-gitlabrunner-monitoring

Notice that roles defined here are all needed, so the default SA (serviceaccount) in gitlab-runner namespace be able to deploy resources (servicemonitors, blackboxes, rules and alertmanagers) on specified namespaces. also all effort are made to have least privileged principle for RBAC rules related to mentioned SA.

Installing namespaces, secrets, CRDs and prometheus instances

Specify your namespaces and required CRDs file path (with remote path) in namespaces-crds file with below condition:

 - Declare Namespaces between following lines: 

      ### MonitoringNamespaces ###   and   ### MonitoringCRDs ####

 - Declare CRDs between following lines:

      ### MonitoringCRDs #### and ### EndOfFile ####

All resources related to this part, are deployed using namespaces-bucketsecrets-crds.sh script. running this scripts give following options:

1- Pressing "1" lead to creation of namespaces and thanos bucket secrets. also it prompts you to enter access_key, secret_key and endpoint of your bucket.

2- Pressing "2" lead to creation of CRDs.

3- Pressing "3" lead to creation of Prometheus instances.

4- Pressing "4" lead to deletion of secrets.

5- Pressing "5" lead to creation of prometehus instances (PVCs remain untouched).

Do following steps respectively to have mentioned required resources:

Create required namespaces and thanos bucket secrets

Run

sh namespaces-bucketsecrets-crds.sh

and then press 1 and then determine access_key, secret_key and endpoint.

Create CRDs

Run

sh namespaces-bucketsecrets-crds.sh

and then press 2.
Create prometheus instances

Run

sh namespaces-bucketsecrets-crds.sh

and then press 3.

Installing thanos

This component is deployed using helm application. Modify values.yaml as below:

    Under stores add headless service path of prometheus instances so thanos can communicate with thanos sidecar in prometheus pods.
    Under ingress set
        enabled: true
        hostname: <Your thanos url>

After these modifications, to deploy thanos run following commands:

helm repo add bitnami https://charts.bitnami.com/bitnami

helm upgrade --install thanos bitnami/thanos -f values.yaml -n thanos --version 11.4.0