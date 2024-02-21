# script to install agcoolstore components
oc new-app java:11~https://github.com/alexgroom/cnw3.git --context-dir=catalog-spring-boot --name=catalog  -l app.openshift.io/runtime=spring 
oc expose svc catalog
#
# Build the inventory variant usig the external mariadb
oc new-app java:11~https://github.com/alexgroom/cnw3.git --context-dir=inventory-quarkus --name=inventory  -l app.openshift.io/runtime=quarkus  \
  --build-env=QUARKUS_DATASOURCE_DB_KIND=mariadb --build-env=QUARKUS_DATASOURCE_JDBC_URL=jdbc:mariadb://inventory-mariadb:3306/inventorydb \
  --build-env=QUARKUS_DATASOURCE_USERNAME=inventory --build-env=QUARKUS_DATASOURCE_PASSWORD=inventory

oc expose svc inventory
# create gateway and apply environment variables
oc new-app java:11~https://github.com/alexgroom/cnw3.git --context-dir=gateway-vertx --name=gateway \
   -l app.openshift.io/runtime=vertx \
  -e COMPONENT_CATALOG_HOST=catalog -e COMPONENT_INVENTORY_HOST=inventory -e COMPONENT_CATALOG_PORT=8080 -e COMPONENT_INVENTORY_PORT=8080
oc expose svc gateway
oc new-app https://github.com/alexgroom/cnw3.git --context-dir=web-nodejs --name=web -l app.openshift.io/runtime=nodejs 
oc expose svc web
oc new-app dotnet:6.0~https://github.com/alexgroom/inventory-api-1st-dotnet.git --context-dir=src/Coolstore.Inventory --name=inventory-dotnet \
  -l app.openshift.io/runtime=dotnet 
oc expose svc inventory-dotnet
# Add component labels to group services
oc label deployment gateway app.kubernetes.io/part-of=coolstore
oc label deployment catalog app.kubernetes.io/part-of=coolstore
oc label deployment inventory app.kubernetes.io/part-of=coolstore
oc label deployment web app.kubernetes.io/part-of=coolstore
oc label deployment inventory-dotnet app.kubernetes.io/part-of=coolstore
# add databases components for inventory and catalog
#
PROJECT_NAME=$(oc project -q)
oc get template -n openshift postgresql-ephemeral -o yaml | sed "s/namespace: openshift/namespace: ${PROJECT_NAME}/" | \
oc process  --param=DATABASE_SERVICE_NAME=catalog-postgresql \
        --param=POSTGRESQL_DATABASE=catalogdb --param=POSTGRESQL_USER=catalog \
        --param=POSTGRESQL_PASSWORD=catalog \
        --labels=app=catalog \
        --labels=app.openshift.io/runtime=postgresql \
          | oc create -f -

oc get template -n openshift mariadb-ephemeral  -o yaml | sed "s/namespace: openshift/namespace: ${PROJECT_NAME}/" | \
oc process  --param=DATABASE_SERVICE_NAME=inventory-mariadb \
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

