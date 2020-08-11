#!/bin/bash
oc new-project agmssql
oc create secret generic mssql --from-literal=SA_PASSWORD="Sql2019isfast"
oc apply -f storage.yaml
oc apply -f sqldeployment.yaml
