# OpenStack CI Analysis Reporting Toolkit

This directory contains a complete toolkit for analyzing OpenStack CI job health, performance, and configuration. Use these scripts to generate comprehensive assessment reports.

## Overview

The toolkit provides data-driven analysis of OpenStack CI jobs by:
1. Extracting job inventory from CI configuration files
2. Fetching runtime metrics from Sippy API
3. Analyzing job health, coverage, and optimization opportunities
4. Comparing OpenStack against other cloud platforms
5. Categorizing failures by root cause

## Prerequisites

Before running the scripts, ensure:

```bash
# Python 3.6+ with pyyaml
python3 -m pip install pyyaml
```

## Running from Any Path

All scripts support the `--output-dir` parameter, allowing you to run them from anywhere in the filesystem:

```bash
# Run from any directory, specify output location
python3 /path/to/reporting-toolkit/extract_openstack_jobs.py \
    --config-dir /path/to/release/ci-operator/config \
    --output-dir /tmp/my-analysis \
    --summary

# Scripts will read input files from and write output files to --output-dir
python3 /path/to/reporting-toolkit/fetch_job_metrics.py --output-dir /tmp/my-analysis
```

### Using the Shell Script

The easiest way to run all analysis is with the shell script:

```bash
# From repo root - outputs to current directory
./hack/openstack-ci-analysis/reporting-toolkit/run_analysis.sh

# From anywhere - specify both directories
/path/to/reporting-toolkit/run_analysis.sh \
    --config-dir /path/to/release/ci-operator/config \
    --output-dir /tmp/my-analysis

# View help
./run_analysis.sh --help
```

### Common Options

All scripts support:
- `--output-dir DIR`: Directory for input/output files (default: script directory or current directory)
- `--help`: Show usage information

Additional script-specific options:
- `extract_openstack_jobs.py`: `--config-dir` to specify CI config location
- `fetch_job_metrics.py`: `--force` to refetch cached data

## Script Execution Order

**IMPORTANT:** Scripts have dependencies and must be run in the correct order.

### Phase 1: Data Collection

Run these scripts first to gather raw data:

```bash
# Set your output directory
OUTPUT_DIR=/tmp/openstack-analysis

# 1. Extract job inventory from CI configuration
python3 hack/openstack-ci-analysis/reporting-toolkit/extract_openstack_jobs.py \
    --config-dir ci-operator/config \
    --output-dir $OUTPUT_DIR \
    --summary

# 2. Fetch job metrics from Sippy API
python3 hack/openstack-ci-analysis/reporting-toolkit/fetch_job_metrics.py \
    --output-dir $OUTPUT_DIR

# 3. Calculate extended metrics (requires step 2)
python3 hack/openstack-ci-analysis/reporting-toolkit/fetch_extended_metrics.py \
    --output-dir $OUTPUT_DIR

# 4. Fetch platform comparison data
python3 hack/openstack-ci-analysis/reporting-toolkit/fetch_comparison_data.py \
    --output-dir $OUTPUT_DIR
```

### Phase 2: Configuration Analysis

These scripts analyze the job configuration (from Phase 1, step 1):

```bash
# Analyze potential redundancy
python3 hack/openstack-ci-analysis/reporting-toolkit/analyze_redundancy.py \
    --output-dir $OUTPUT_DIR

# Analyze coverage gaps across releases
python3 hack/openstack-ci-analysis/reporting-toolkit/analyze_coverage.py \
    --output-dir $OUTPUT_DIR

# Analyze trigger optimization opportunities
python3 hack/openstack-ci-analysis/reporting-toolkit/analyze_triggers.py \
    --output-dir $OUTPUT_DIR
```

### Phase 3: Runtime Analysis

These scripts analyze runtime metrics (requires Phase 1):

```bash
# Analyze platform comparison
python3 hack/openstack-ci-analysis/reporting-toolkit/analyze_platform_comparison.py \
    --output-dir $OUTPUT_DIR

# Analyze workflow pass rates
python3 hack/openstack-ci-analysis/reporting-toolkit/analyze_workflow_passrate.py \
    --output-dir $OUTPUT_DIR

# Categorize failures by root cause
python3 hack/openstack-ci-analysis/reporting-toolkit/categorize_failures.py \
    --output-dir $OUTPUT_DIR
```

## Script Descriptions

### Data Collection Scripts

#### extract_openstack_jobs.py
Extracts all OpenStack CI jobs from `ci-operator/config/` files.

**Input:** CI configuration YAML files
**Output:**
- `openstack_jobs_inventory.csv` - Complete job inventory
- `openstack_jobs_inventory.json` - Job inventory (JSON format)

**Key fields extracted:**
- job_name, cluster_profile, job_type (presubmit/periodic)
- workflow, schedule, minimum_interval
- optional, always_run, skip_if_only_changed, run_if_changed
- org, repo, branch, variant, config_file

**Options:**
- `--config-dir`: Path to config directory (default: ci-operator/config)
- `--output-csv`: Output CSV file path
- `--output-json`: Output JSON file path
- `--summary`: Print summary statistics

#### fetch_job_metrics.py
Fetches job pass rate metrics from Sippy API.

**Input:** None (fetches from Sippy API)
**Output:**
- `sippy_jobs_raw.json` - Raw Sippy API data (cached)
- `job_metrics_report.md` - Pass rate metrics report
- `job_metrics_summary.json` - Metrics summary

**Data collected per job:**
- current_pass_percentage, current_runs, current_passes
- previous_pass_percentage, previous_runs, previous_passes
- open_bugs, last_pass date

**Options:**
- `--force`: Refetch data even if cache exists

#### fetch_extended_metrics.py
Calculates extended metrics combining current + previous periods (~14 days).

**Requires:** `sippy_jobs_raw.json` from fetch_job_metrics.py

**Output:**
- `extended_metrics.json` - Extended metrics data
- `extended_metrics_jobs.json` - Per-job extended metrics
- `extended_metrics_report.md` - Extended metrics report

**Calculations:**
- Combined pass rates across 14-day window
- Trend analysis (improving/degrading/stable)
- Problem job identification (<80% pass rate)
- Estimated job durations by cluster profile

#### fetch_comparison_data.py
Fetches platform comparison data from Sippy API.

**Input:** None (fetches from Sippy API)
**Output:**
- `platform_comparison_raw.json` - Raw platform data

**Platforms compared:**
- OpenStack, AWS, GCP, Azure, vSphere, Metal

**Data collected:**
- Job counts per platform per release
- Total runs and passes
- Pass rates by platform

### Configuration Analysis Scripts

#### analyze_redundancy.py
Identifies redundant jobs and consolidation opportunities.

**Requires:** `openstack_jobs_inventory.json`

**Output:**
- `redundant_jobs_report.md` - Redundancy analysis report
- `redundant_jobs_report_data.json` - Raw analysis data

**Analyzes:**
- Jobs duplicated between openshift/ and openshift-priv/
- Multiple jobs using same workflow + cluster in one repo
- Presubmit trigger patterns

#### analyze_coverage.py
Analyzes test coverage across releases.

**Requires:** `openstack_jobs_inventory.json`

**Output:**
- `coverage_gaps_report.md` - Coverage analysis report
- `coverage_gaps_report_data.json` - Raw analysis data

**Analyzes:**
- Jobs per release
- Cluster profile usage by release
- Coverage gaps (tests missing from some releases)

#### analyze_triggers.py
Identifies trigger optimization opportunities.

**Requires:** `openstack_jobs_inventory.json`

**Output:**
- `trigger_optimization_report.md` - Trigger optimization report
- `trigger_optimization_report_data.json` - Raw analysis data

**Analyzes:**
- Jobs missing skip_if_only_changed patterns
- Jobs missing run_if_changed patterns
- Repos that could benefit from smarter triggering

### Runtime Analysis Scripts

#### analyze_platform_comparison.py
Analyzes platform comparison data.

**Requires:** `platform_comparison_raw.json`

**Output:**
- `platform_comparison_analysis.json` - Analysis results
- `platform_comparison_report.md` - Platform comparison report

**Provides:**
- Platform ranking by pass rate
- OpenStack vs other platforms comparison
- Per-release platform breakdown
- Gap analysis

#### analyze_workflow_passrate.py
Analyzes pass rates grouped by workflow/test scenario.

**Requires:**
- `openstack_jobs_inventory.json`
- `sippy_jobs_raw.json`
- `extended_metrics_jobs.json` (optional, enhances analysis)

**Output:**
- `workflow_passrate_analysis.json` - Analysis results
- `workflow_passrate_report.md` - Workflow pass rate report

**Workflow classification:**
- Extracts workflow type from job names
- Groups jobs by scenario (fips, dualstack, serial, etc.)
- Categorizes as Critical (<50%), Warning (50-70%), OK (>70%)

#### categorize_failures.py
Categorizes job failures using heuristic classification.

**Requires:**
- `extended_metrics_jobs.json`
- `sippy_jobs_raw.json` (optional, for bug counts)

**Output:**
- `failure_categories.json` - Categorized failures
- `failure_categories_report.md` - Failure categorization report

**Categories:**
| Category | Criteria |
|----------|----------|
| Infrastructure | Low pass rate on install/provision jobs |
| Flaky | 30-70% pass rate (inconsistent) |
| Product Bug | 0% or low pass rate with bugs filed |
| Needs Triage | Unknown cause, requires investigation |

## Output Files Summary

| Category | File | Description |
|----------|------|-------------|
| **Inventory** | openstack_jobs_inventory.json | Complete job inventory |
| | openstack_jobs_inventory.csv | Job inventory (CSV) |
| **Config Analysis** | redundant_jobs_report.md | Workflow duplication analysis |
| | coverage_gaps_report.md | Cross-release coverage gaps |
| | trigger_optimization_report.md | Trigger pattern analysis |
| **Sippy Metrics** | sippy_jobs_raw.json | Cached Sippy API data |
| | job_metrics_report.md | Pass rate metrics |
| | extended_metrics_report.md | 14-day combined metrics |
| **Platform Comparison** | platform_comparison_raw.json | Raw platform data |
| | platform_comparison_report.md | Platform comparison report |
| **Workflow Analysis** | workflow_passrate_report.md | Workflow pass rate report |
| **Failure Categories** | failure_categories_report.md | Categorized failures |

## Creating a Complete Assessment Report

To create a comprehensive assessment report like `TEAM_REVIEW_OpenStack_CI_Assessment.md`, follow this process:

### Step 1: Run All Scripts

```bash
# Set up environment
cd /path/to/release

# Phase 1: Data Collection
python3 hack/openstack-ci-analysis/reporting-toolkit/extract_openstack_jobs.py --summary
python3 hack/openstack-ci-analysis/reporting-toolkit/fetch_job_metrics.py
python3 hack/openstack-ci-analysis/reporting-toolkit/fetch_extended_metrics.py
python3 hack/openstack-ci-analysis/reporting-toolkit/fetch_comparison_data.py

# Phase 2: Configuration Analysis
python3 hack/openstack-ci-analysis/reporting-toolkit/analyze_redundancy.py
python3 hack/openstack-ci-analysis/reporting-toolkit/analyze_coverage.py
python3 hack/openstack-ci-analysis/reporting-toolkit/analyze_triggers.py

# Phase 3: Runtime Analysis
python3 hack/openstack-ci-analysis/reporting-toolkit/analyze_platform_comparison.py
python3 hack/openstack-ci-analysis/reporting-toolkit/analyze_workflow_passrate.py
python3 hack/openstack-ci-analysis/reporting-toolkit/categorize_failures.py
```

### Step 2: Review Generated Reports

Read all generated `.md` reports to understand the findings:

1. `job_metrics_report.md` - Overall pass rates by release
2. `extended_metrics_report.md` - 14-day trends and problem jobs
3. `platform_comparison_report.md` - OpenStack vs other platforms
4. `workflow_passrate_report.md` - Which workflows are problematic
5. `failure_categories_report.md` - Root cause categorization
6. `coverage_gaps_report.md` - Missing test coverage
7. `trigger_optimization_report.md` - Quick win optimizations
8. `redundant_jobs_report.md` - Potential consolidation

### Step 3: Create Executive Summary

Structure the report with these sections:

1. **Executive Summary**
   - Total jobs analyzed
   - Overall pass rate
   - Number of problem jobs
   - Key priorities

2. **Job Inventory Overview**
   - Distribution by cluster profile
   - Distribution by organization
   - Jobs by type (presubmit/periodic)

3. **Periodic Job Health Analysis**
   - Overall health metrics
   - Pass rate by release
   - Critical failures (0% pass rate)
   - Degrading jobs
   - Platform comparison
   - Workflow analysis
   - Failure categorization

4. **Trigger Optimization**
   - Jobs missing filters
   - Recommended patterns

5. **Coverage Gaps**
   - Missing tests across releases
   - CAPI/other notable gaps

6. **Action Items**
   - Immediate actions
   - Short-term improvements
   - Medium-term investigations

### Step 4: Key Data Points to Include

From the JSON data files, extract these key metrics:

**From extended_metrics.json:**
```python
import json
data = json.load(open('extended_metrics.json'))
print(f"Total jobs: {data['overall']['total_jobs']}")
print(f"Pass rate: {data['overall']['combined_pass_rate']:.1f}%")
print(f"Problem jobs: {data['overall']['problem_job_count']}")
```

**From platform_comparison_analysis.json:**
```python
data = json.load(open('platform_comparison_analysis.json'))
for p in data['overall']['platforms']:
    print(f"{p['platform']}: {p['pass_rate']:.1f}%")
```

**From workflow_passrate_analysis.json:**
```python
data = json.load(open('workflow_passrate_analysis.json'))
critical = [w for w in data['workflows'] if w['severity'] == 'critical']
for w in critical:
    print(f"{w['workflow']}: {w['pass_rate']:.1f}%")
```

**From failure_categories.json:**
```python
data = json.load(open('failure_categories.json'))
for cat, count in data['summary']['by_category'].items():
    pct = data['summary']['percentages'][cat]
    print(f"{cat}: {count} ({pct}%)")
```

## Customization

### Adding New Cluster Profiles

Edit `extract_openstack_jobs.py` to add new profiles:

```python
OPENSTACK_CLUSTER_PROFILES = [
    "openstack-vexxhost",
    "openstack-vh-mecha-central",
    # Add new profiles here
]
```

### Adjusting Pass Rate Thresholds

Edit `categorize_failures.py` to change thresholds:

```python
# Current thresholds
CRITICAL_THRESHOLD = 50  # Below this = critical
WARNING_THRESHOLD = 70   # Below this = warning
PROBLEM_THRESHOLD = 80   # Below this = problem job
```

### Adding New Workflow Patterns

Edit `analyze_workflow_passrate.py` to recognize new patterns:

```python
def extract_workflow_from_name(job_name):
    # Add new patterns here
    if "newpattern" in name_lower:
        characteristics.append("newpattern")
```

## Sippy API Reference

The scripts use these Sippy API endpoints:

| Endpoint | Description |
|----------|-------------|
| `/api/jobs?release=X` | All jobs for a release |
| `/api/variants?release=X` | Variant (platform) data |

**Base URL:** https://sippy.dptools.openshift.org/api

**Rate limiting:** Scripts include 1-second delays between requests.

## Troubleshooting

### "No Sippy data found"
Run `fetch_job_metrics.py` before running analysis scripts that require Sippy data.

### "No job inventory found"
Run `extract_openstack_jobs.py` before running configuration analysis scripts.

### Script fails with import error
Ensure pyyaml is installed: `python3 -m pip install pyyaml`

### Old cached data
Use `--force` flag with fetch scripts to refresh cached data:
```bash
python3 fetch_job_metrics.py --force
```

## Example Analysis Session

Here's a complete example of running an analysis and interpreting results:

```bash
# Run all scripts
cd /path/to/release
for script in extract_openstack_jobs fetch_job_metrics fetch_extended_metrics \
              fetch_comparison_data analyze_redundancy analyze_coverage \
              analyze_triggers analyze_platform_comparison \
              analyze_workflow_passrate categorize_failures; do
    echo "Running $script..."
    python3 hack/openstack-ci-analysis/reporting-toolkit/${script}.py
done

# Check key findings
echo "=== Key Findings ==="
python3 -c "
import json
ext = json.load(open('extended_metrics.json'))
plat = json.load(open('platform_comparison_analysis.json'))
fail = json.load(open('failure_categories.json'))

print(f'Overall pass rate: {ext[\"overall\"][\"combined_pass_rate\"]:.1f}%')
print(f'Problem jobs: {ext[\"overall\"][\"problem_job_count\"]}')
print(f'OpenStack rank: #{plat[\"openstack_position\"][\"rank\"]} of {plat[\"openstack_position\"][\"total\"]}')
print(f'Flaky jobs: {fail[\"summary\"][\"by_category\"][\"flaky\"]}')
print(f'Needs triage: {fail[\"summary\"][\"by_category\"][\"needs_triage\"]}')
"
```

## Maintenance

### Updating for New Releases

When new OpenShift releases are added, update the RELEASES list in each script:

```python
RELEASES = ["4.17", "4.18", "4.19", "4.20", "4.21", "4.22", "4.23"]
```

### Refreshing Data

For fresh analysis, delete cached JSON files and re-run:

```bash
rm -f *_raw.json *_jobs.json
# Then run all fetch scripts again
```
