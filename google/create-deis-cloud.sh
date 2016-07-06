#!/bin/bash

# https://deis.com/blog/2016/first-kubernetes-cluster-gke
# https://deis.com/docs/workflow/installing-workflow/
# https://deis.com/docs/workflow/quickstart/provider/gke/dns/
# https://deis.com/docs/workflow/quickstart/deploy-an-app/

CREATE_KUBE=NO
CREATE_DEIS_WORKFLOW=NO

### KUBERNETES CLUSTER ###

if [ "${CREATE_KUBE}" == "YES" ];
then
    GCE_ZONE=europe-west1-b
    CLUSTER_NAME=test-lab1
    CLUSTER_NODES=2
    DISK_SIZE=200
    
    cp -v ~/.kube/config ~/.kube/config.bak
    
    gcloud config set project codaisseurcloud
    gcloud config set compute/zone ${GCE_ZONE}
    
    gcloud container clusters create ${CLUSTER_NAME} \
      --disk-size ${DISK_SIZE} \
      --zone ${GCE_ZONE} \
      --enable-cloud-logging \
      --machine-type n1-standard-2 \
      --num-nodes ${CLUSTER_NODES}
    
    gcloud config set container/cluster ${CLUSTER_NAME}
    gcloud container clusters get-credentials ${CLUSTER_NAME}
    kubectl cluster-info
fi

### DEIS DEPLOYMENT ###

if [ "${CREATE_DEIS_WORKFLOW}" == "YES" ];
then
    WORKFLOW_VER=2.0.0
    which helmc || echo "\n!!! No helmc !!!\n" 
    helmc --version
    helmc target
    sleep 5
    
    helmc repo add deis https://github.com/deis/charts
    helmc fetch deis/workflow-v${WORKFLOW_VER}
    helmc generate -x manifests workflow-v${WORKFLOW_VER}
    helmc install workflow-v${WORKFLOW_VER}
    for i in $(seq 24);
    do
        clear
        kubectl --namespace=deis get pods
        sleep 10
        n=$(kubectl --namespace=deis get pods|grep Running|grep '1/1'|wc -l)
        [ "${n}" == "15" ] && break
    done
    
fi

echo "================================="
echo "DEIS cluster deploy finished ..."
echo "================================="
clear
kubectl --namespace=deis get pods

kubectl --namespace=deis describe svc deis-router | grep LoadBalancer
echo "Run:  curl -sSL http://deis.io/deis-cli/install-v2.sh | bash"
echo "      deis register http://deis.<LB>.nip.io"
echo "      deis keys:add ~/.ssh/deis.pub"

exit 0;
