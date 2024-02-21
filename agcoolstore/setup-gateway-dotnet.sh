# script to install agcoolstore components
oc delete all --selector app=gateway
# create gateway and apply environment variables
oc new-app dotnet:6.0~https://github.com/alexgroom/cnw3.git --context-dir=gateway-dotnet --name=gateway \
   -l app.openshift.io/runtime=dotnet \
  -e COMPONENT_CATALOG_HOST=catalog -e COMPONENT_INVENTORY_HOST=inventory -e COMPONENT_CATALOG_PORT=8080 -e COMPONENT_INVENTORY_PORT=8080
oc expose svc gateway
# Add component labels to group services
oc label deployment gateway app.kubernetes.io/part-of=coolstore

