# script to install agcoolstoresm  components
#oc new-project agcoolstoresm
oc new-app java:11~https://github.com/alexgroom/cnw3.git --context-dir=catalog-spring-boot --name=catalog  -l app.openshift.io/runtime=java
oc expose svc catalog
oc new-app java:11~https://github.com/alexgroom/cnw3.git --context-dir=inventory-quarkus --name=inventory  -l app.openshift.io/runtime=java
oc expose svc inventory
# create gateway and apply environment variables
oc new-app java:11~https://github.com/alexgroom/cnw3.git --context-dir=gateway-vertx --name=gateway \
   -l app.openshift.io/runtime=java \
  -e COMPONENT_CATALOG_HOST=catalog -e COMPONENT_INVENTORY_HOST=inventory -e COMPONENT_CATALOG_PORT=8080 -e COMPONENT_INVENTORY_PORT=8080
oc expose svc gateway
oc new-app https://github.com/alexgroom/cnw3.git --context-dir=web-nodejs --name=web -l app.openshift.io/runtime=nodejs
oc expose svc web
oc new-app dotnet:2.1~https://github.com/alexgroom/inventory-api-1st-dotnet.git#dotnet2.1 --context-dir=src/Coolstore.Inventory --name=inventory-dotnet \
  -l app.openshift.io/runtime=dotnet
oc expose svc inventory-dotnet
# Add component labels to group services
oc label dc gateway app.kubernetes.io/part-of=coolstore
oc label dc catalog app.kubernetes.io/part-of=coolstore
oc label dc inventory app.kubernetes.io/part-of=coolstore
oc label dc web app.kubernetes.io/part-of=coolstore
oc label dc inventory-dotnet app.kubernetes.io/part-of=coolstore
# configure service mesh
