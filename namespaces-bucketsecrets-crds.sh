#!/bin/bash
create_namespace_secret()
{
  echo Create namespace and thanos bucket secret respectively:
  echo ====================================
  read -p 'Bucket access key: ' access_key
  read -p 'Bucket secret key: ' secret_key
  read -p 'Bucket end point: ' endpoint
  yes | cp -rf objstore.yml.sample objstore.yml
  sed -i "s/ACCESS_KEY/'"${access_key}"'/g" objstore.yml
  sed -i "s/SECRET_KEY/'"${secret_key}"'/g" objstore.yml
  sed -i "s/ENDPOINT/'"${endpoint}"'/g" objstore.yml
  echo
  for namespace in $(cat ./namespaces-crds | awk '/MonitoringNamespaces/{f=1;next} /MonitoringCRDs/{f=0} f');do kubectl create ns $namespace; kubectl create secret generic thanos-objstore-config --from-file=objstore.yml -n $namespace; done
  rm -rf objstore.yml
}

create_crds()
{
  echo Create CRDs:
  echo ====================================
  echo
  for CRD in $(cat ./namespaces-crds | awk '/MonitoringCRDs/{f=1;next} /EndOfFile/{f=0} f');do kubectl create -f $CRD; done
}
# To create prometehus instances using this script, prometheus-helm-values folder should be added to project as submodule.
create_prometheus_instances()
{
  rootPath=$PWD
  for instance in $(ls $rootPath/prometheus-helm-values); do cd $rootPath/prometheus-helm-values/$instance; git apply values.patch; helm upgrade --install p-$instance bitnami/kube-prometheus -f values.yaml -n prometheus-$instance --version 8.2.2; git reset --hard HEAD ; done
  cd $rootPath
}

delete_prometheus_instances()
{
  rootPath=$PWD
  for instance in $(ls $rootPath/prometheus-helm-values); do helm uninstall p-$instance -n prometheus-$instance; done
}

delete_secrets()
{
echo Delete secrets:
echo ====================================
echo
for namespace in $(cat ./namespaces-crds | awk '/MonitoringNamespaces/{f=1;next} /MonitoringCRDs/{f=0} f');do kubectl delete secret thanos-objstore-config -n $namespace; done
}

echo -e " 
  What do you want to do:
    Press 1 to create namespaces and thanos buckets
    Press 2 to create crds
    Press 3 to create prometehus instances
    Press 4 to delete prometheus instance 
    Press 5 to delete secrets
"

read -p 'Press 1, 2, 3, 4 or 5: ' uservar
case $uservar in
	1)
		create_namespace_secret
		;;
        2)
		create_crds
		;;
        3)
		create_prometheus_instances
		;;
        4)
		delete_prometheus_instances
		;;
        5)
		delete_secrets
		;;
	*)
		echo "Please just type 1, 2, 3, 4 or 5 based on your need"
esac