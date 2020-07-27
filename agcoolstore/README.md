
Coolstore Basic deployment
===

## Table of Contents

[TOC]

## Introduction

This is the basic Coolstore application deployment. It consist of a web front end, a gateway (API orchestrator service) and then two data driven microservices to return information about the products (catalog) and then the stock levels (inventory).

## Setup.sh

This script loads all the elements needed to deploy the Coolstore app.


## Prereqs

The cluster obvsiouly must be installed and the user excuting the scrip needs rights to create a project.

The only privileges required is the right to create an SA for a config map in the project

## Inventory
Quarkus based Java service, configured to use Maria database.

## Catalog
Spring Boot based Java component.

## Inventory-dotnet
Dotnet based version of the inventory service, but using an internal database. This service is not actually utlized in the initial configuration but can be incorporated by changing the ENV variables in the Gateway service.

## Web
Web front end written in Angular and web server written in Javascript for Nodejs. The web server serves up the static content for the UI.

## Gateway
This is a simple Vert.x Java based component that orchestrates the data from the two microservices. The browser based UI calls this service directly for data. It is configured via environment variables to consume the catalog and inventory services in the script here:

```
-e COMPONENT_CATALOG_HOST=catalog 
-e COMPONENT_INVENTORY_HOST=inventory 
-e COMPONENT_CATALOG_PORT=8080 
-e COMPONENT_INVENTORY_PORT=8080
```

## Databases

The components can use in memory database eg H2, but in this configuration two database types are supported. Postgres (catalog) and Mariadb (inventory).

The databases are deployed and run as separate pods outsidse of the application with the database configuration injected at runtime via a ConfigMap.

## Network

All components have both a service and external route configured (mainly for debugging) but on the the web and gateway route are essential for normal operation

