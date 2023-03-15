# wipe rook

kubectl delete -n rook-ceph cephblockpool --all
kubectl delete -n rook-ceph cephfilesystems --all
kubectl delete -n rook-ceph cephobjectstores --all

kubectl delete sc ceph-block
kubectl delete sc ceph-bucket
kubectl delete sc ceph-filesystem

kubectl -n rook-ceph patch cephcluster rook-ceph --type merge -p '{"spec":{"cleanupPolicy":{"confirmation":"yes-really-destroy-data"}}}'

kubectl -n rook-ceph delete cephcluster rook-ceph

kubectl get cephcluster -n rook-ceph

# wipe storage

kubectl apply -f wipe-rook-data.yaml
kubectl apply -f wipe-rook-disk.yaml