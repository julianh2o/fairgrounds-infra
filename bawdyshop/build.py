#!/usr/bin/env python3
"""Build consent-cards.html from YAML data and Jinja2 template.

Usage: python3 build.py > consent-cards.html
"""
from pathlib import Path

import yaml
from jinja2 import Environment, FileSystemLoader

here = Path(__file__).parent
env = Environment(loader=FileSystemLoader(here), autoescape=True)

with open(here / "cards.yaml") as f:
    data = yaml.safe_load(f)

template = env.get_template("consent-cards.html.j2")
print(template.render(cards=data["cards"]))
