#!/bin/bash
kubectl apply -f ELK_Namespace.yaml
sleep 1s
kubectl apply -f ELK_Secret.yaml
kubectl apply -f elasticsearch/ES_StorageClass.yaml
kubectl apply -f elasticsearch/ES_ConfigMap.yaml
kubectl apply -f elasticsearch/ES_Deployment_Master.yaml
kubectl apply -f elasticsearch/ES_Deployment_Client.yaml
kubectl apply -f elasticsearch/ES_StatefulSet_Data.yaml
kubectl apply -f elasticsearch/ES_Service.yaml
kubectl apply -f elasticsearch/ES_Service_Data.yaml
kubectl apply -f elasticsearch/ES_Service_Discovery.yaml
kubectl apply -f kibana/Kibana_ConfigMap.yaml
kubectl apply -f kibana/Kibana_Deployment.yaml
kubectl apply -f kibana/Kibana_Service.yaml
kubectl apply -f filebeat/Filebeat_ConfigMap.yaml
kubectl apply -f filebeat/Filebeat_DaemonSet.yaml
kubectl apply -f logstash/Logstash_ConfigMap.yaml
kubectl apply -f logstash/Logstash_Deployment.yaml
kubectl apply -f logstash/Logstash_Service.yaml
kubectl apply -f ELK_Ingress.yaml
