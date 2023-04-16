#! /bin/bash -e 

latest_version=$(curl --silent "https://api.github.com/repos/kubernetes/dashboard/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/${latest_version}/aio/deploy/recommended.yaml

kubectl apply -f dashboard-user.yaml

kubectl -n kubernetes-dashboard create token dashboard-user 

echo "RUN: kubectl proxy, to enable access to the Dashboard"