# OpenStack CI Analysis Reporting Toolkit

A portable toolkit for analyzing OpenStack CI job health, performance, and configuration in OpenShift CI infrastructure.

## Overview

This toolkit provides comprehensive analysis of OpenStack CI jobs by:

- **Extracting** job inventory from CI configuration files
- **Fetching** runtime metrics from the [Sippy API](https://sippy.dptools.openshift.org/)
- **Analyzing** job health, coverage gaps, and optimization opportunities
- **Comparing** OpenStack pass rates against other cloud platforms (AWS, GCP, Azure, vSphere)
- **Categorizing** failures by root cause (flaky, product bug, infrastructure, needs triage)

## Prerequisites

- Python 3.6+
- PyYAML library

```bash
pip install pyyaml
```

## Quick Start

### Option 1: Using the Shell Script (Recommended)

```bash
# Clone the release repository (or use existing clone)
git clone https://github.com/openshift/release.git
cd release

# Run complete analysis - outputs to current directory
./path/to/reporting-toolkit/run_analysis.sh

# Or specify custom paths
./path/to/reporting-toolkit/run_analysis.sh \
    --config-dir /path/to/release/ci-operator/config \
    --output-dir /tmp/my-analysis
```

### Option 2: Running Scripts Individually

```bash
# Set your paths
TOOLKIT=/path/to/reporting-toolkit
CONFIG_DIR=/path/to/release/ci-operator/config
OUTPUT_DIR=/tmp/my-analysis

# Phase 1: Data Collection
python3 $TOOLKIT/extract_openstack_jobs.py --config-dir $CONFIG_DIR --output-dir $OUTPUT_DIR --summary
python3 $TOOLKIT/fetch_job_metrics.py --output-dir $OUTPUT_DIR
python3 $TOOLKIT/fetch_extended_metrics.py --output-dir $OUTPUT_DIR
python3 $TOOLKIT/fetch_comparison_data.py --output-dir $OUTPUT_DIR

# Phase 2: Configuration Analysis
python3 $TOOLKIT/analyze_redundancy.py --output-dir $OUTPUT_DIR
python3 $TOOLKIT/analyze_coverage.py --output-dir $OUTPUT_DIR
python3 $TOOLKIT/analyze_triggers.py --output-dir $OUTPUT_DIR

# Phase 3: Runtime Analysis
python3 $TOOLKIT/analyze_platform_comparison.py --output-dir $OUTPUT_DIR
python3 $TOOLKIT/analyze_workflow_passrate.py --output-dir $OUTPUT_DIR
python3 $TOOLKIT/categorize_failures.py --output-dir $OUTPUT_DIR
```

## Scripts

### Data Collection

| Script | Description |
|--------|-------------|
| `extract_openstack_jobs.py` | Extracts job inventory from `ci-operator/config/` YAML files |
| `fetch_job_metrics.py` | Fetches pass rates and run counts from Sippy API |
| `fetch_extended_metrics.py` | Calculates 14-day combined metrics and trends |
| `fetch_comparison_data.py` | Fetches platform comparison data from Sippy |

### Configuration Analysis

| Script | Description |
|--------|-------------|
| `analyze_redundancy.py` | Identifies duplicate/overlapping jobs |
| `analyze_coverage.py` | Finds test coverage gaps across releases |
| `analyze_triggers.py` | Identifies trigger optimization opportunities |

### Runtime Analysis

| Script | Description |
|--------|-------------|
| `analyze_platform_comparison.py` | Compares OpenStack vs AWS/GCP/Azure/vSphere |
| `analyze_workflow_passrate.py` | Analyzes pass rates by workflow/test type |
| `categorize_failures.py` | Classifies failures by root cause |

## Command Line Options

All scripts support:
- `--output-dir DIR` - Directory for input/output files (default: script directory)
- `--help` - Show usage information

Additional options:
- `extract_openstack_jobs.py`: `--config-dir` for CI config location
- `fetch_job_metrics.py`: `--force` to refresh cached data

## Output Files

### Reports (Markdown)

| File | Description |
|------|-------------|
| `job_metrics_report.md` | Pass rate metrics by release |
| `extended_metrics_report.md` | 14-day trends and problem jobs |
| `platform_comparison_report.md` | OpenStack vs other platforms |
| `workflow_passrate_report.md` | Pass rates by workflow type |
| `failure_categories_report.md` | Failures by root cause |
| `coverage_gaps_report.md` | Missing test coverage |
| `trigger_optimization_report.md` | Trigger pattern improvements |
| `redundant_jobs_report.md` | Potential job consolidation |

### Data (JSON)

| File | Description |
|------|-------------|
| `openstack_jobs_inventory.json` | Complete job inventory |
| `sippy_jobs_raw.json` | Cached Sippy API data |
| `extended_metrics.json` | Extended metrics data |
| `platform_comparison_raw.json` | Platform comparison data |
| `workflow_passrate_analysis.json` | Workflow analysis data |
| `failure_categories.json` | Categorized failures |

## Example Output

After running the analysis, you'll see key findings like:

```
Platform Comparison:
  1. vSphere: 80.7%
  2. AWS: 73.9%
  3. GCP: 71.2%
  4. Metal: 69.8%
  5. Azure: 68.2%
  6. OpenStack: 50.4% <-- Gap to address

Failure Categories:
  - Flaky: 41.6%
  - Needs Triage: 36.0%
  - Product Bug: 22.5%

Critical Workflows (0% pass rate):
  - ccpmso
  - upgrade
  - singlestackv6
```

## Portability

This toolkit is designed to be portable:

1. **No hardcoded paths** - All paths are configurable via command-line options
2. **Self-contained** - All scripts are in a single directory
3. **Minimal dependencies** - Only requires Python 3.6+ and PyYAML

To use in another project:
```bash
# Copy the toolkit
cp -r reporting-toolkit /path/to/your/project/

# Run from anywhere
/path/to/your/project/reporting-toolkit/run_analysis.sh \
    --config-dir /path/to/release/ci-operator/config \
    --output-dir /path/to/output
```

## Data Sources

- **CI Configuration**: `ci-operator/config/` in the [openshift/release](https://github.com/openshift/release) repository
- **Runtime Metrics**: [Sippy API](https://sippy.dptools.openshift.org/) - OpenShift CI analytics platform

## Cluster Profiles Analyzed

The toolkit analyzes jobs using these OpenStack cluster profiles:
- `openstack-vexxhost`
- `openstack-vh-mecha-central`
- `openstack-vh-mecha-az0`
- `openstack-vh-bm-rhos`
- `openstack-hwoffload`
- `openstack-nfv`

## Refreshing Data

Sippy data is cached to avoid repeated API calls. To refresh:

```bash
# Refresh all data
./run_analysis.sh --force

# Or refresh just job metrics
python3 fetch_job_metrics.py --output-dir $OUTPUT_DIR --force
```

## Troubleshooting

### "No Sippy data found"
Run `fetch_job_metrics.py` before analysis scripts that require Sippy data.

### "No job inventory found"
Run `extract_openstack_jobs.py` before configuration analysis scripts.

### Import error for yaml
Install PyYAML: `pip install pyyaml`

### Config directory not found
Ensure the path to `ci-operator/config` is correct. This should point to the config directory in the openshift/release repository.

## For Claude Code Users

See `CLAUDE.md` for detailed instructions on using this toolkit with Claude Code, including:
- Step-by-step execution guide
- Creating comprehensive assessment reports
- Customization options
- API reference

## License

This toolkit is part of the OpenShift CI infrastructure. See the main repository for license information.
