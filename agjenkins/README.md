

Jenkins Pipeline Deployment
===

## Table of Contents

[TOC]

## Introduction

Rather than trying to recreate a good Jenkins pipeline example using the Coolstore app it is actually much easier to just reference an existing example that is already frequently maintained.

This pipeline example uses a JBoss Java build fetching source from a local Gogs git server, tags and stashes in Nexus deploys the app to dev, validates it with Sonarqube and then deploys to staging based on approval in the Jenkins build.

Jenkins, Gogs, Sonar, Nexus are all deployed as a servers in OpenShift

## Scripts


```
$ git clone https://github.com/siamaksade/openshift-cd-demo.git
$ ./scripts/provision.sh deploy
```

Jenkins is the start point of the demo and can be found in the cicd-XXXX project, use the developer Topology to access routes to all the servers installed.


## Prereqs

This demo is all-inclusive, no prereqs are required, however note that kubeadmin is not a good user to excecute the scripts they are best run with a normal user.

## Sonoar Authentication

Recent changes to Sonorqube means authentication is enabled by default so the piepline as-is wont run. Typically Sonar takes about 30s to process the application where it will fail with authentication in about 5s. Two options here, either inject some credentials into the Jenkins script (eg hard code them) or disable Sonor authemtication. This is not entirely desirable but it is only a demo. 

Login to Sonar as admin, change the passsword from the default at this stage then go into the Administration | Security section. There should be an option "Force user authnentication" this needs to be set off/false for the pipeline to run.

