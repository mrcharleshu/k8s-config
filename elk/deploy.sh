#!/bin/bash
kubectl apply -f ES_PersistentVolumeClaim.yaml
kubectl apply -f ES_ConfigMap.yaml
kubectl apply -f ES_StatefulSet.yaml
kubectl apply -f ES_Service.yaml
kubectl apply -f Kibana_ConfigMap.yaml
kubectl apply -f Kibana_Deployment.yaml
kubectl apply -f Kibana_Service.yaml
kubectl apply -f Filebeat_ConfigMap.yaml
kubectl apply -f Filebeat_DaemonSet.yaml
kubectl apply -f Logstash_ConfigMap.yaml
kubectl apply -f Logstash_Deployment.yaml
kubectl apply -f Logstash_Service.yaml
kubectl apply -f ELK_Ingress.yaml