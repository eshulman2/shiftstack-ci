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

true > "$output_file"

 grep -RlE 'cluster_profile:.*vexxhost.*' "$config_base_path" | rev | awk -F '/' '{print $2 "/" $3}' | rev | sort -u | while read -r project; do
    echo "$project:" >> "$output_file"

    grep -RlE 'cluster_profile:.*vexxhost.*' "$config_base_path/$project/" | sort -u | while read -r file; do
        yq -r "
            \"  - \(filename):\" ,
            (.tests[]
                | select(.steps.cluster_profile | match(\".*vexxhost.*\"))
                | \"      - \" + .as + \":\" +
                  \"\n          run_if_changed: \" + (.run_if_changed // \"null\") +
                  \"\n          skip_if_only_changed: \" + (.skip_if_only_changed // \"null\")
            )
        " "$file" >> "$output_file"
    done
done
