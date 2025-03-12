# Overview

This repo is a step by step guide to build the Cloud Native PostgreSQL demo as shown in the Kubecon London 2025 talk [Stateful Superpowers: Explore High Performance and Scaleable Stateful Workloads on K8s - Alex Chircop, Chris Milsted & Alex Reid, Akamai; Lori Lorusso, Percona](https://kccnceu2025.sched.com/event/1txEs/stateful-superpowers-explore-high-performance-and-scaleable-stateful-workloads-on-k8s-alex-chircop-chris-milsted-alex-reid-akamai-lori-lorusso-percona)

The guide will cover all of the k8s and database setup, it assumes that you already have an object storage bucket created as well for backups and wal archives. To setup a buckets and access/secret keys please refer to the akamai technical docs here [create and manage buckets](https://techdocs.akamai.com/cloud-computing/docs/create-and-manage-buckets).

## First step - create an LKE cluster

This repository provides a template for deploying an LKE cluster with the [Linode LKE Firewall Controller](https://github.com/linode/cloud-firewall-controller).   If you need to deploy LKE clusters frequently for testing and experimentation this repo can help streamline your ability to deploy a starting cluster that is secured with a sane default set of firewall rules.  The idea is that it provides you with something that works immediately out-of-the-box but also allows you to use as an initial template that you can take pieces from for building your own project.

## How to Use

1. Clone this repo locally.
2. Ensure you have [Terraform CLI installed](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).
3. Setup the Linode provider with local configuration for authentication or setup the token as an environment variable per the [documentation](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).
    1. If you are using a local config file with your API token it attempts to set the environment variable from that.  
    2. If you are not using a local configuration file then you should set the `LINODE_TOKEN` environment variable with your API token before running
4. Modify the [`deploy.sh`](http://deploy.sh) file to be executable.
5. To create a cluster with the default settings in the script you can run `./deploy.sh` and it will provision a 3-node LKE cluster by default using dedicated 8GB instances and apply the cloud firewall controller with default firewall rules
6. To destroy your cluster and the associated firewall it created you can run `./deploy.sh destroy`

## Configuration Options

This repo was intentionally kept simple to act as a template or to use as a basic demonstration for deploying LKE with a default secure firewall.  There are a few configurable elements in [`deploy.sh`](http://deploy.sh) including:

- `K8S_VERSION` which corresponds to a current supported version of Kubernetes on LKE
- `linode_credentials_file` which can be changed if your file is hosted elsewhere than the default location that Terraform uses

You could also setup a `terraform.tfvars` file in the `terraform/provision-lke` directory if you wanted to override any default variables provided for the deployment.  This repo wasn’t meant to enable extensive configuration and that is left for those consuming this repo to fork and use for their own projects if desired.  This repo without additional configuration will give you a starting cluster that you can then use to run imperative commands against for experimenting while having a more secure and compliant default set of firewall rules applied.

## Install encrypted storage classes 

CNPG relies on the storage providers to provide encryption at rest for the data, we are going to add in the linode encryption annotations to our storage classes and map to these encrypted versions by applying the yaml here [sc-encryption.yaml](./k8s/sc-encrypted.yaml)

## Install CNPG with helm

The next step is to install CNPG, I used version 1.25 as part of the demo, so linking these install instructions as the next step in the instructions. [Install instructions for CNPG](https://cloudnative-pg.io/documentation/1.25/installation_upgrade/), please of course do check for any updates.

The outcome of this step should be the cnpg operator running in the cluster we created with terraform.

## Install the Barman plugin

The next step is to install the barman plugin, again I am going to link to the product pages I used for the demo. There is a pre-requisite for cert-manager so please install cert manager into the cluster following [cert manager install instructions](https://cert-manager.io/docs/installation/).

We can then install the barman plugin following the instructions here[barmain plugin install instrcutions](https://github.com/cloudnative-pg/plugin-barman-cloud).

## Create the barman object store and then the cnpg cluster

We are now set to create our cluster, I have supplied the yaml I used for these steps. Before you apply these you will also need to create you secret which will contain the access key and secret key to access the object store you want to backup to. You can do this in a similar way to:

```bash
kubectl create secret generic backup-creds \
  --from-literal=ACCESS_KEY_ID=ACCESS_KEY_STRING \
  --from-literal=ACCESS_SECRET_KEY=SECRET_KEY_STRING \
  --from-literal=REGION=paris 
```

The next step is to create the barman backup object, you can do this with the following yaml file [barmanObjectStore.yaml](./cnpg/barmanObjectStore.yaml)

We are now ready to deploy our database which we can deploy with [cluster-example-full.yaml](./cnpg/cluster-example-full.yaml)

## Take a full backup to a remote object store, and then restore from it

The first step we can now take is to create a complete backup to a remote object store. Using the plugin we can do this by creating a backup object. Apply the file [backup.yaml](./cnpg/backup.yaml) to do this.

We can then restore this backup to a new database to test the complete end to end workflow, you can restore this using the following yaml file [restore-from-backup.yaml](./cnpg/restore-from-backup.yaml)

## Tearing down

That completes the demo steps, you can tear everything down by just running the [deploy.sh](./deploy.sh) script again, but passing the argument `destroy` to it.