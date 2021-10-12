To create all the Serverless demos use 
```
$ ./setup-4demo-projects.sh
```

To add the faas demo run 
```
$ ./setup-coolserve5.sh agcoolserve4
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

