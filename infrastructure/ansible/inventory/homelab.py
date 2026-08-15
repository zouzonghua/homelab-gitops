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
services = load_yaml(REPOSITORY_ROOT / "inventory/services.yaml")["services"]

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
k3s_api_vip = next(
    service["address"]
    for service in services
    if service["name"] == "chengdu-k3s-api"
)
k3s_ingress_vip = next(
    service["address"]
    for service in services
    if service["name"] == "chengdu-k3s-ingress"
)

bootstrap = k3s_servers[0]["name"]
inventory = {
    "_meta": {
        "hostvars": {
            host["name"]: {
                "ansible_host": host["address"],
                "k3s_api_vip": k3s_api_vip,
                "k3s_ingress_vip": k3s_ingress_vip,
            }
            for host in k3s_servers
        }
    },
    "k3s_servers": {"hosts": [host["name"] for host in k3s_servers]},
    "k3s_bootstrap": {"hosts": [bootstrap]},
    "k3s_joiners": {
        "hosts": [host["name"] for host in k3s_servers if host["name"] != bootstrap]
    },
}

print(json.dumps(inventory))
