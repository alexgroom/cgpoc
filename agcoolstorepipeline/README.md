
Coolstore Pipeline Deployment
===

## Table of Contents

[TOC]

## Introduction

This is the basic Coolstore application deployment. It consist of a web front end, a gateway (API orchestrator service) and then two data driven microservices to return information about the products (catalog) and then the stock levels (inventory).

This configuration uses a simple Tekton pipelien scheme to build from source code and deploy 4 components to OpenShift.

## Scripts

* Setup.sh loads all the yaml elements needed to build and deploy the Coolstore app - but doesn't actually execute the build
* simple_pipeline.yaml is the overarching pipeline description
* pipelineresources.yaml defines a collection of image definitions to make the build run easier
* The deployments folder contains base deploment definitions for each component, these provide the shell that will be filled with the build image. The deployment also includes the service creation and export to route.


## Prereqs

The cluster obvsiouly must be installed and the user excuting the scrip needs rights to create a project.

The Pipelines operator must be installed.

The project `agcoolstorepipeline` is assumed to be the namespace by the script files.

## Inventory
Quarkus based Java service.

## Catalog
Spring Boot based Java component.

## Web
Web front end written in Angular and web server written in Javascript for Nodejs. The web server serves up the static content for the UI.

## Gateway
This is a simple Vert.x Java based component that orchestrates the data from the two microservices. The browser based UI calls this service directly for data. It is configured via environment variables to consume the catalog and inventory services in the yaml script here:

```
          env:
            - name: COMPONENT_CATALOG_HOST
              value: catalog
            - name: COMPONENT_INVENTORY_HOST
              value: inventory
            - name: COMPONENT_CATALOG_PORT
              value: '8080'
            - name: COMPONENT_INVENTORY_PORT
              value: '8080'

```

## Network

All components have both a service and external route configured (mainly for debugging) but on the the web and gateway route are essential for normal operation

## First Pipeline Run
The pipeline is executed from the web console by selecting Pipelines | build-all | Start.

This presents a configuration template for the build. Most of the values have been defaulted by a few must be supplied

* Git Repo: `http://github.com/alexgroom/cnw3.git`
* Image Resources: All the image resources have been pre-created, however the UI drop downs must be used to select the correct image name, eg `web-image = image-registry.openshift-image-registry.svc:5000/agcoolstorepipeline/web`
* All 4 images need to be correctly selected

On subsequent runs, use `Start last Run` to avoid having to enter the same information.

![](https://github.com/alexgroom/cgpoc/blob/master/images/startpipeline.png)

On completion the run should show all aspects are green.

![](https://github.com/alexgroom/cgpoc/blob/master/images/pipelinerun.png)

The web UI components should be accessable from the Topology view and the web URL.

![](https://github.com/alexgroom/cgpoc/blob/master/images/webrun.png)


## Scripted Pipeline run
To run the piepline from the CLI the `tkn` CLI tool must be installed locally and then the user logged on via `oc login...`. At that point the porject can be selected and the build-all pipeline specified and run.

