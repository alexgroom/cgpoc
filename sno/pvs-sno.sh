#!/bin/bash
mkdir -p /var/pocfs/user-vols/pv{1..21}
echo "Creating PV for users.."
for pvnum in {1..21} ; do   echo "/var/pocfs/user-vols/pv${pvnum} *(rw,root_squash)" >> /etc/exports.d/openshift-uservols.exports;  done
chown -R nfsnobody.nfsnobody /var/pocfs
chmod -R 777 /var/pocfs
systemctl restart nfs-server
#
# make sure it starts at boot
systemctl enable nfs-server
#
export nfshost=localhost
mkdir -p pvs

export volsize="50Gi"

for volume in pv{21} ; do
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
        "path": "/var/pocfs/user-vols/${volume}",
        "server": "${nfshost}"
    },
    "persistentVolumeReclaimPolicy": "Retain"
  }
}
EOF
echo "Created def file for ${volume}";
done;
#

export volsize="10Gi"

for volume in pv{11..20} ; do
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
        "path": "/var/pocfs/user-vols/${volume}",
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
for volume in pv{1..10} ; do
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
        "path": "/var/pocfs/user-vols/${volume}",
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
