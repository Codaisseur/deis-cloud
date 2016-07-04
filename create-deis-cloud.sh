#!/bin/bash

# https://deis.com/blog/2016/first-kubernetes-cluster-gke
# https://deis.com/docs/workflow/installing-workflow/

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
    WORKFLOW_VER=2.1.0
    which helmc || echo "\n!!! No helmc !!!\n" 
    helmc --version
    helmc target
    sleep 5
    
    helmc repo add deis https://github.com/deis/charts
    helmc fetch deis/workflow-v${WORKFLOW_VER}
    helmc generate -x manifests workflow-v${WORKFLOW_VER}
    helmc install workflow-v${WORKFLOW_VER}
    for i in $(seq 10);
    do
        kubectl --namespace=deis get pods
        sleep 5
        echo "\n-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n"
        n=$(kubectl --namespace=deis get pods|grep Running|wc -l)
        [ "${n}" == "15" ] && break
    done
    
fi

echo "================================="
echo "DEIS cluster deploy finished ..."
echo "================================="
kubectl --namespace=deis get pods

exit 0;
