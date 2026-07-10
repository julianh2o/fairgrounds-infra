#!/usr/bin/env python3
"""Builds the CI deploy matrix from playbook_triggers.yml and a list of changed files.

Reads changed files (JSON array) from $CHANGED_FILES, matches them against
playbook_triggers.yml, and writes `matrix` and `has_deploys` to $GITHUB_OUTPUT.
"""
import fnmatch
import json
import os

import yaml

with open("playbook_triggers.yml") as f:
    config = yaml.safe_load(f)

changed_files = json.loads(os.environ["CHANGED_FILES"])


def matched_pattern(patterns, files):
    for pattern in patterns:
        for path in files:
            if fnmatch.fnmatch(path, pattern):
                return pattern
    return None


matrix = []
for service in config["services"]:
    reason = matched_pattern(service["paths"], changed_files)
    if reason:
        matrix.append({"name": service["name"], "playbook": service["playbook"]})
        print(f"deploy {service['name']}: matched '{reason}'")

github_output = os.environ["GITHUB_OUTPUT"]
with open(github_output, "a") as f:
    f.write(f"matrix={json.dumps(matrix)}\n")
    f.write(f"has_deploys={'true' if matrix else 'false'}\n")

if not matrix:
    print("No services matched changed files; nothing to deploy.")
