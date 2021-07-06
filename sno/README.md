Registry by default is disabled, but after adding storage it can be enabled by doing this:

Add the PVC yaml file

```
oc apply -f sno-reg-pvc.yaml
```

Set the state to "managed"

```
oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Managed"}}'
```

Add the storage reference:

oc edit configs.imageregistry.operator.openshift.io

```
storage:
  pvc:
    claim:
```
