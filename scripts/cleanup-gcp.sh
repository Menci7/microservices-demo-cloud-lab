#!/bin/bash

set -e  #Exit on error

echo "=== GCP Cleanup Script ==="

PROJECT_ID=$(gcloud config get-value project)
CLUSTER_NAME="online-boutique-cluster"
CLUSTER_ZONE="europe-west9-b"
REGION="europe-west9"

# Delete GKE cluster
echo "Checking for GKE clusters..."
gcloud container clusters list
read -p "Delete all clusters? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    gcloud container clusters delete $CLUSTER_NAME --zone=$CLUSTER_ZONE --quiet
fi

# Delete VMs
echo "Checking for VMs..."
gcloud compute instances list
read -p "Delete all VMs? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    gcloud compute instances list --format="value(name,zone)" | while read name zone; do
        gcloud compute instances delete $name --zone=$zone --quiet
    done
fi

# Delete disks
echo "Checking for orphaned disks..."
gcloud compute disks list
read -p "Delete all disks? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    gcloud compute disks list --format="value(name,zone)" | while read name zone; do
        gcloud compute disks delete $name --zone=$zone --quiet
    done
fi

# List remaining resources
echo "=== Remaining Resources ==="
echo "Forwarding rules:"
gcloud compute forwarding-rules list
echo "Addresses:"
gcloud compute addresses list
echo "Firewall rules (custom):"
gcloud compute firewall-rules list --format=json --filter="name~loadgen OR name~locust"

echo "=== Cleanup Complete ==="
echo "Check billing report: https://console.cloud.google.com/billing"
