
Coolstore Service Mesh Deployment
===

## Table of Contents

[TOC]

## Introduction

This is Service Mesh Coolstore application deployment. It consist of a web front end, a gateway (API orchestrator service) and then two data driven microservices to return information about the products (catalog) and then the stock levels (inventory).

in addtion, montioring services are installed to explore the component metrics and display them with Prometheus and Grafana.

## Scripts

* setup.sh loads all the elements needed to deploy the Coolstore app in a Service Mesh configuration based around DeploymentConfigs
``` 
$ oc login ...
$ ./setup.sh agcoolstoresm
```

* setup-deployment.sh uses Deployments instead
``` 
$ oc login ...
$ ./setup-deployment.sh agcoolstoresm
```

* isto-gateway.yml defines the top level mesh entry point
* virtualservice.yml defines the top level virtual service for inbound traffic and also the 50/50 traffic split for microservices
* monitoring.sh installs the seperate monitoring components
* Prometheus.yaml defines the configuration and the services to scrape


## Manual Prereqs

* Assumes OCP 4.4 onwards
* Cluster operators for Elastic Search, Jaeger, Kiali and Service Mesh must be installed.
* Service Mesh (as documented) should be further installed into the `istio-system` project where the control plane and service member roll are added.
* The name of the deployed project eg `agcoolstoresm` must be added to the member roll list.
* Check that the allow-from-all-namspaces Network Policy is installed in the project
* The istio ingress URL needs to be discovered and then used as the `COOLSTORE_GW_ENDPOINT` environment variable value for the web component

## Inventory
Quarkus based Java service, configured without database

## Catalog
Spring Boot based Java component.

## Inventory-dotnet
Dotnet based version of the inventory service, but using an internal database. The Service Mesh configuration incorporates both this and the inventory service with a 50/50 traffic split between them.

## Web
Web front end written in Angular and web server written in Javascript for Nodejs. The web server serves up the static content for the UI.

## Gateway
This is a simple Vert.x Java based component that orchestrates the data from the two microservices. The browser based UI calls this service directly for data. It is configured via environment variables to consume the catalog and inventory services in the script here (but then )

```
-e COMPONENT_CATALOG_HOST=catalog 
-e COMPONENT_INVENTORY_HOST=inventory 
-e COMPONENT_CATALOG_PORT=8080 
-e COMPONENT_INVENTORY_PORT=8080
```

## Databases

To simplify the example no external databases are used in this demo.

## Service Mesh Local Configuration
* All components have sidecar injection enabled by patching the deployment config
* All components have `maistra.io/expose-route` enabled to allow normal routes into the application to still work
* The inventory services are patched with a much simpler pod selector than oc new-app generates by default
* The web server is configured to explicitly use the ingress router to access the Gateway component

## Network

All components have both a service and external route configured (mainly for debugging) but on the the web and gateway route are essential for normal operation. 

The Service Mesh ingress gateway route is required for correct operation between web and gateway service.

## Monitoring
The `monitoring.sh` script installs and enables Prometheus and Grafana components in the project

Both components should be created with external routes.

Note Grafana initial credentials are: `admin/admin`

Components metrics are viewable at `http://service-name:8080/metrics`

## Multi-tennant Istio
OpenShift Service Mesh operator supports multi-tennant deployments of Istio. To deploy the app in this scenario you need to pass the 
name of the local istio project as a parameter otherwise `istio-system` is assumed. eg:-

``` 
$ oc login ...
$ ./setup-deployment.sh agcoolstoresm-user1 user1-istio
```


