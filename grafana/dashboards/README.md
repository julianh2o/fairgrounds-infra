# Grafana Dashboards

This directory contains Grafana dashboard JSON files that are automatically provisioned to Grafana on deployment.

## Adding Dashboards

1. Create or export a dashboard from Grafana as JSON
2. Place the JSON file in this directory
3. Deploy Grafana: `ansible-playbook playbooks/services/deploy_grafana.yaml`

## Dashboard Format

Dashboards should be exported as JSON from Grafana. You can export a dashboard by:
1. Open the dashboard in Grafana
2. Click the Share icon (or dashboard settings)
3. Go to "Export" tab
4. Click "Save to file" or copy the JSON

## Auto-reload

The provisioning configuration is set to check for changes every 10 seconds, so new dashboards will appear automatically without needing to restart Grafana.

## Notes

- Dashboard files should have `.json` extension
- `allowUiUpdates: true` is set, so you can edit provisioned dashboards in the UI
- Changes made in the UI will not persist across deployments unless you export and save them back to this directory
