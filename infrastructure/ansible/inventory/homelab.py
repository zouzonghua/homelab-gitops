#!/usr/bin/env python3
"""将仓库 Inventory 转换为 Ansible 动态 Inventory。"""

import json
from pathlib import Path

import yaml


REPOSITORY_ROOT = Path(__file__).resolve().parents[3]


def load_yaml(path: Path) -> dict:
    with path.open(encoding="utf-8") as stream:
        return yaml.safe_load(stream)


hosts = load_yaml(REPOSITORY_ROOT / "inventory/hosts.yaml")["hosts"]

k3s_servers = sorted(
    (
        host
        for host in hosts
        if host["site"] == "chengdu"
        and host["role"] == "k3s-server"
        and host["status"] == "active"
    ),
    key=lambda host: host["startup_order"],
)

inventory = {
    "_meta": {
        "hostvars": {
            host["name"]: {
                "ansible_host": host["address"],
            }
            for host in k3s_servers
        }
    },
    "k3s_servers": {"hosts": [host["name"] for host in k3s_servers]},
    "k3s_bootstrap": {"hosts": [k3s_servers[0]["name"]]},
}

print(json.dumps(inventory))
