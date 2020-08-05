#!/bin/bash
mkdir -p /pocfs/user-vols/pv{1..50}
echo "Creating PV for users.."
for pvnum in {1..50} ; do   echo "/pocfs/user-vols/pv${pvnum} *(rw,root_squash)" >> /etc/exports.d/openshift-uservols.exports;   chown -R nfsnobody.nfsnobody /pocfs;   chmod -R 777 /pocfs; done
systemctl restart nfs-server
#
export nfshost=10.239.232.150
mkdir -p pvs
export volsize="10Gi"

for volume in pv{26..50} ; do
cat << EOF > pvs/${volume}
{
  "apiVersion": "v1",
  "kind": "PersistentVolume",
  "metadata": {
    "name": "${volume}"
  },
  "spec": {
    "capacity": {
        "storage": "${volsize}"
    },
    "accessModes": [ "ReadWriteMany" ],
    "nfs": {
        "path": "/pocfs/user-vols/${volume}",
        "server": "${nfshost}"
    },
    "persistentVolumeReclaimPolicy": "Retain"
  }
}
EOF
echo "Created def file for ${volume}";
done;
#
export volsize="5Gi"
for volume in pv{1..25} ; do
cat << EOF > pvs/${volume}
{
  "apiVersion": "v1",
  "kind": "PersistentVolume",
  "metadata": {
    "name": "${volume}"
  },
  "spec": {
    "capacity": {
        "storage": "${volsize}"
    },
    "accessModes": [ "ReadWriteOnce" ],
    "nfs": {
        "path": "/pocfs/user-vols/${volume}",
        "server": "${nfshost}"
    },
    "persistentVolumeReclaimPolicy": "Recycle"
  }
}
EOF
echo "Created def file for ${volume}";
done;
systemctl restart nfs-server
cat pvs/* | oc create -f -
