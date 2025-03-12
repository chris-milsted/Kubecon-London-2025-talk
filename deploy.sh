#!/usr/bin/env bash

### Environment Variables ###

#export TF_LOG=trace
#export TF_LOG_PATH=./terraform.log

export TF_PLUGIN_CACHE_DIR=$PWD/terraform/terraform-plugin-cache

### Script Variables ###

K8S_VERSION=1.32

### Main Script ###

### setup variables ###

lke_tf_dir="./terraform/provision-lke"
cfw_tf_dir="./terraform/provision-cfw"

# default file used for terraform provider
linode_credentials_file=~/.config/linode

# hydrate API token if not set.  NOTE: it currently expects one token in the file so
# you might need to change this logic if you are using multiple profiles in your 
# configuration file
if [ "$LINODE_TOKEN" = "" ] && [ -f $linode_credentials_file ];
  then
  export LINODE_TOKEN=$(grep "token" $linode_credentials_file | awk '{print $3}')
fi

# destroy cluster when parameter is provided

if [ "$1" = "destroy" ];
  then
  lke_cloud_firewall_id=$(terraform -chdir=$cfw_tf_dir output -raw lke_cloud_firewall_id)
  terraform -chdir=$lke_tf_dir apply -auto-approve -var "k8s_version=$K8S_VERSION" -destroy
  firewall_delete_result=$(curl -s -s -o /dev/null -w "%{http_code}" -X DELETE "https://api.linode.com/v4/networking/firewalls/$lke_cloud_firewall_id" \
    -H "Authorization: Bearer $LINODE_TOKEN" \
  )
  if [ $firewall_delete_result == 200 ];
  then
    echo "Cloud firewall deleted successfully"
  else
    echo "Cloud firewall deletion failed"
  fi
fi

# otherwise deploy

if [ "$1" != "destroy" ];
  then

  terraform -chdir=$lke_tf_dir init
  terraform -chdir=$cfw_tf_dir init

  terraform -chdir=$lke_tf_dir apply -auto-approve -var "k8s_version=$K8S_VERSION" 

  LKE_CLUSTER_ID=$(terraform -chdir=$lke_tf_dir output -raw lke_cluster_id)

  terraform -chdir=$cfw_tf_dir apply -auto-approve -var "lke_cluster_id=$LKE_CLUSTER_ID"

  # I haven't identified why the output "lke_cloud_firewall_id" runs before the implicit dependency
  # but adding a try statement prevents it from erroring early, and doing another apply will allow
  # it to hydrate on the 2nd time through.  So this is why we run apply again below.
  terraform -chdir=$cfw_tf_dir apply -auto-approve -var "lke_cluster_id=$LKE_CLUSTER_ID"
fi