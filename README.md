# secscan-oci

This is a small wrapper for creating an up to date docker/rock image, exporting it as an OCI `.tar`/`.rock` and uploading it for scanning using the [canonical-secscan-client](https://snapcraft.io/canonical-secscan-client) tool.

## Usage

Run `./scan.sh /path/to/the/project` and wait. Append the `--rock` flag if the project is built with rockcraft.

## Getting the reports

Once your project has successfully been uploaded and scanned you can use the following to get both a simple result list of CVEs or a full report:

`secscan-client result --token /path/to/the/project/project.token`

`secscan-client report --token /path/to/the/project/project.token`

## Requirements
- [canonical-secscan-client snap](https://snapcraft.io/canonical-secscan-client)
- Docker
- Connected to the VPN.
