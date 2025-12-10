#!/bin/bash
#
# Audits CI configuration files to find OpenStack e2e test jobs and reports
# their run_if_changed and skip_if_only_changed settings.
#
# Usage: ./openstack-job-audit.sh <config_base_path> [output_file]
#   config_base_path: Path to ci-operator/config directory
#   output_file: Output file path (default: ./report.yaml)
#
# Example: ./openstack-job-audit.sh ci-operator/config ./report.yaml

config_base_path=$1
output_file=${2:-./report.yaml}

jobs=(
"openshift-e2e-openstack-additional-ipv6-network"
"openshift-e2e-openstack-dualstack"
"openshift-e2e-openstack-dualstack-upi"
"openshift-e2e-openstack-dualstack-v6primary"
"openshift-e2e-openstack-dualstack-techpreview"
"openshift-e2e-openstack-singlestackv6"
"openshift-e2e-openstack-proxy"
"openshift-e2e-openstack-csi-cinder"
"openshift-e2e-openstack-csi-manila"
"openshift-e2e-openstack-externallb"
"openshift-e2e-openstack-ccpmso-zone"
"openshift-e2e-openstack-proxy"
"openshift-e2e-openstack-csi-cinder"
"openshift-e2e-openstack-csi-manila"
"openshift-e2e-openstack-externallb"
"openshift-e2e-openstack-ingress-perf"
"openshift-e2e-openstack-network-perf"
"openshift-e2e-openstack"
)


joined=$(IFS='|'; echo "${jobs[*]}")

projects=$(grep -RlE \"$joined\" $config_base_path | rev | awk -F '/' '{print $2 "/" $3}' | rev |sort -u)

> "$output_file"

for project in ${projects[@]}; do
    echo "$project:" >> "$output_file"
    for file in $(grep -REl "$joined" "$config_base_path/$project/" | sort -u); do
        yq -r "
            \"  - \(filename):\" ,
            (.tests[]
                | select(.steps.workflow | test(\"$joined\"))
                | \"      - \" + .as + \":\" +
                  \"\n          run_if_changed: \" + (.run_if_changed // \"null\") +
                  \"\n          skip_if_only_changed: \" + (.skip_if_only_changed // \"null\")
            )
        " "$file" >> "$output_file"
    done
done
