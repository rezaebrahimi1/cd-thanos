**This project is designed to have:**

1- Automatic continuous deployment for deploying monitoring metric scraping resources (servicemonitors and blackboxes), alertmanagers and rules on kubernetes cluster by managing large amount of helm charts using helmfile module.

2- Long-term storage solution for scraped metrics in part 1 by utilizing thanos application.


>It is notable that this project is just an example of automate CD process of prometheus instances configuration manipulation using helmfile. The real project has about 40 helm charts to deploy different resources. All charts are execute on less than 1 minutes that reaches the power of helmfile module. 

**These goals are achieved by:**
1. Generate targets to be processed by thanos (By deploying servicemonitor and blackbox resources using helmfile and gitlab-ci).
2. Add rules to be processed by prometheus instance using helmfile and gitlab-ci.
3. install alertmanager using helmfile (prometheus-community/alertmanager chart) and gitlab-ci.
4. Install prometheus instances using helm (kube-prometheus chart) by running a shellscript.
5. Long-term storage solution for scraped metrics by installing thanos.

>Each prometheus instance (in prometheus-helm-values folder) is responsible for scraping some paramethers. also they are installed in seperate namespaces. To create prometehus instances using namespaces-bucketsecrets-crds.sh script, prometheus-helm-values folder should be added to project as submodule (I did not do it already in this example project). The values.path in prometheus-helm-values sub-directories show the difference of modified values with original one.

>Also my advise is to limit where each prometheus is looking for servicemonitors to its related prometheus namespace (do it in helm chart values.yaml file as i did), so the CPU of apiserver can't go very high.    

>All rules are deployed on thanos namespace (but process by all prometheus instances). but this cause no duplication on triggered rules, since each prometheus instance process its related target on its specified namespace. 

>Alertmanager is also deployed on thanos namespaces. this alertmanaget is the endpoint of alertmanger endpoint which is specified on helm values of prometheus instances. the value.yaml related to this alertmanager is determined at chart/alertmanager/values.yaml

# Installing process

## Prerequisites

At first, prepare your cluster by deploying:

1- Gitlab-runner for automating CD process of changing metric scraping values (servicemonitors and blackboxes) and also alertmanagers and rules configs.

2- Installing required namespaces and thanos bucket secrets on them.

3- Installing required CRDs.

4- Installing prometheus instances.

## Gitlab-runner

The tool which is used to deploy many helm charts in this project is helmfile. To use automatic CD process defined in gitlab-ci.yml, install gitlab-runner in K8S cluster using this link => https://github.com/rezaebrahimi1/helm-gitlabrunner-monitoring

Notice that roles defined here are all needed, so the default SA (serviceaccount) in gitlab-runner namespace be able to deploy resources (servicemonitors, blackboxes, rules and alertmanagers) on specified namespaces. also all effort are made to have least privileged principle for RBAC rules related to mentioned SA.

## Installing namespaces, secrets, CRDs and prometheus instances

Specify your namespaces and required CRDs file path (with remote path) in namespaces-crds file with below condition:

 - Declare Namespaces between following lines: 

       MonitoringNamespaces and MonitoringCRDs 

 - Declare CRDs between following lines:

       MonitoringCRDs and EndOfFile 

All resources related to this part, are deployed using namespaces-bucketsecrets-crds.sh script. running this scripts give following options:

1- Pressing "1" lead to creation of namespaces and thanos bucket secrets. also it prompts you to enter access_key, secret_key and endpoint of your bucket.

2- Pressing "2" lead to creation of CRDs.

3- Pressing "3" lead to creation of Prometheus instances.

4- Pressing "4" lead to deletion of secrets.

5- Pressing "5" lead to creation of prometehus instances (PVCs remain untouched).

Do following steps respectively to have mentioned required resources:

Create required namespaces and thanos bucket secrets

*Run*

`sh namespaces-bucketsecrets-crds.sh`

and then press 1 and then determine access_key, secret_key and endpoint.

Create CRDs

*Run*

`sh namespaces-bucketsecrets-crds.sh`

and then press 2.
Create prometheus instances

*Run*

`sh namespaces-bucketsecrets-crds.sh`

and then press 3.

# Installing thanos

This component is deployed using helm application. Modify values.yaml as below:

    Under stores add headless service path of prometheus instances so thanos can communicate with thanos sidecar in prometheus pods.
    Under ingress set
        enabled: true
        hostname: <Your thanos url>

After these modifications, to deploy thanos run following commands:

`helm repo add bitnami https://charts.bitnami.com/bitnami`

`helm upgrade --install thanos bitnami/thanos -f values.yaml -n thanos --version 11.4.0`

After successful completion of helm command, you can see thanos UI on <Your thanos url>.

file:///home/reza/Downloads/thanos-sidecar.png![image](https://user-images.githubusercontent.com/71483991/227737287-bd2ce692-92f3-4221-97d4-d87fdd9e258c.png)

# Automate installation, deletion and modification

To part deals with installation, deletion and modification of monitoring metric scraping resources (servicemonitors and blackboxes), alertmanagers and rules automatically by utilizing helmfile this link and using pipeline in .gitlab-ci.yml file.

you can trigger .gitlab-ci.yml by changing values.yaml of:

1- Servicemonitor helm chart.

2- Black-box exporter helm chart.

3- Alertmanager helm chart.

4- rules helm chart.

and also helmfile.yaml lead to helmfile module execution.

In helmfile.yaml Manipulate

    installed: true to install
    installed: false to uninstall

the resources.

Pipeline status shows following logs for successful installation execution:

file:///home/reza/Downloads/deployes-charts.png![image](https://user-images.githubusercontent.com/71483991/227737186-406a9f9e-e599-4792-a257-53918936266b.png)
