To create all the Serverless demos use 
```
$ ./setup-4demo-projects.sh
```

To add the faas demo run 
```
$ ./setup-coolserv5.sh agcoolserve4
```
To add a "normal" coolstore deployment run
```
$ cd ../agcoolstore
$ ./setup.sh
$ ./setup-gateway-dotnet.sh
```
Prune down any additional deployments running such as inventory-dotnet as required from this project

This should create 
- agcoolstore0 = web UI Serverless
- agcoolserve1 = everything Serverless
- agcoolserve2 = Serverless with eventing
- agcoolserve3 = optimised Serverless and eventing
- agcoolserve4 = optimised serverless with FaaS filter
- agcoolstore = coolstore as normal

These demos all uses a mix of http and https to communicate. Knative Serving now supports mTLS which is fine when working between 
other KSVC but an edge route is required when talking to an ordinary gateway service. When there are no KSVC present, http is used.

You can force Serverless to disable mTLS. https://docs.openshift.com/container-platform/4.8/serverless/serverless-release-notes.html

You can override the default by adding the following YAML to your KnativeServing custom resource (CR):

```
...
spec:
  config:
    network:
      defaultExternalScheme: "http"
...
```
