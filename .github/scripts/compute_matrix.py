#!/usr/bin/env python3
"""Builds the CI deploy matrix from playbook_triggers.yml and a list of changed files.

Reads changed files (JSON array) from $CHANGED_FILES, matches them against
playbook_triggers.yml, and writes `matrix` and `has_deploys` to $GITHUB_OUTPUT.
"""
import ast
import fnmatch
import json
import os

import yaml

with open("playbook_triggers.yml") as f:
    config = yaml.safe_load(f)

raw_changed_files = os.environ["CHANGED_FILES"].strip()
if not raw_changed_files:
    changed_files = []
else:
    try:
        # Expected format: a JSON array, e.g. ["file1","file2"]
        changed_files = json.loads(raw_changed_files)
    except json.JSONDecodeError:
        # GitHub Actions sometimes stringifies array outputs interpolated via
        # ${{ }} as a Python/Ruby-style repr, e.g. ['file1','file2'], instead
        # of valid JSON. ast.literal_eval handles that single-quoted form.
        changed_files = ast.literal_eval(raw_changed_files)


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
