# script to install agcoolstore components
oc new-app java:11~https://github.com/alexgroom/cnw3.git --context-dir=catalog-spring-boot --name=catalog  -l app.openshift.io/runtime=spring --as-deployment-config
oc expose svc catalog
#
# Take the maria branch of inventory simce it support db access
oc new-app java:11~https://github.com/alexgroom/cnw3.git#maria --context-dir=inventory-quarkus --name=inventory  -l app.openshift.io/runtime=quarkus --as-deployment-config
oc expose svc inventory
# create gateway and apply environment variables
oc new-app java:11~https://github.com/alexgroom/cnw3.git --context-dir=gateway-vertx --name=gateway --as-deployment-config\
   -l app.openshift.io/runtime=vertx \
  -e COMPONENT_CATALOG_HOST=catalog -e COMPONENT_INVENTORY_HOST=inventory -e COMPONENT_CATALOG_PORT=8080 -e COMPONENT_INVENTORY_PORT=8080
oc expose svc gateway
oc new-app https://github.com/alexgroom/cnw3.git --context-dir=web-nodejs --name=web -l app.openshift.io/runtime=nodejs --as-deployment-config
oc expose svc web
oc new-app dotnet:6.0~https://github.com/alexgroom/inventory-api-1st-dotnet.git --context-dir=src/Coolstore.Inventory --name=inventory-dotnet \
  -l app.openshift.io/runtime=dotnet --as-deployment-config
oc expose svc inventory-dotnet
# Add component labels to group services
oc label dc gateway app.kubernetes.io/part-of=coolstore
oc label dc catalog app.kubernetes.io/part-of=coolstore
oc label dc inventory app.kubernetes.io/part-of=coolstore
oc label dc web app.kubernetes.io/part-of=coolstore
oc label dc inventory-dotnet app.kubernetes.io/part-of=coolstore
# add databases components for inventory and catalog
#
oc process -n openshift postgresql-ephemeral --param=DATABASE_SERVICE_NAME=catalog-postgresql \
        --param=POSTGRESQL_DATABASE=catalogdb --param=POSTGRESQL_USER=catalog \
        --param=POSTGRESQL_PASSWORD=catalog \
        --labels=app=catalog \
        --labels=app.openshift.io/runtime=postgresql \
          | oc create -f -

oc process -n openshift mariadb-ephemeral --param=DATABASE_SERVICE_NAME=inventory-mariadb \
        --param=MYSQL_DATABASE=inventorydb --param=MYSQL_USER=inventory \
        --param=MYSQL_PASSWORD=inventory --param=MYSQL_ROOT_PASSWORD=inventoryadmin \
        --labels=app=inventory \
        --labels=app.openshift.io/runtime=mariadb \
        | oc create -f -

# modift config maps
cat <<EOF > catalog-application.properties
spring.datasource.url=jdbc:postgresql://catalog-postgresql:5432/catalogdb
spring.datasource.username=catalog
spring.datasource.password=catalog
spring.datasource.driver-class-name=org.postgresql.Driver
spring.jpa.hibernate.ddl-auto=create
EOF
oc create configmap catalog --from-file=catalog-application.properties
#
# enable service account to allow Spring to access the config map
oc policy add-role-to-user view system:serviceaccount:agcoolstore:default
#
#

