#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path
from string import Template


REQUIRED = [
    "LOCAL_PROXY_PORT",
    "MIHOMO_API_PORT",
    "NETWORK_SERVICE",
    "RELAY_SSH_TARGET",
    "RELAY_SING_BOX_CONFIG_PATH",
    "RELAY_SING_BOX_SERVICE",
    "AI_RELAY_HOST",
    "AI_RELAY_PORT",
    "HY2_PASSWORD",
    "HY2_SNI",
    "HY2_SKIP_CERT_VERIFY",
    "HY2_UP",
    "HY2_DOWN",
    "STABLE_EGRESS_HTTP_HOST",
    "STABLE_EGRESS_HTTP_PORT",
    "STABLE_EGRESS_HTTP_USERNAME",
    "STABLE_EGRESS_HTTP_PASSWORD",
    "AI_DOMAINS",
]


def parse_env(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for raw in path.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            raise SystemExit(f"Invalid env line: {raw}")
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if not re.fullmatch(r"[A-Z0-9_]+", key):
            raise SystemExit(f"Invalid env key: {key}")
        values[key] = value
    missing = [key for key in REQUIRED if not values.get(key)]
    if missing:
        raise SystemExit("Missing required values: " + ", ".join(missing))
    return values


def csv_list(value: str) -> list[str]:
    return [item.strip() for item in value.split(",") if item.strip()]


def indented_yaml_map(domains: list[str], value: str, indent: int = 4) -> str:
    prefix = " " * indent
    if not domains:
        return f"{prefix}# no entries\n"
    return "".join(f'{prefix}"+.{domain}": {value}\n' for domain in domains)


def domain_rules(domains: list[str], target: str, indent: int = 2) -> str:
    prefix = " " * indent
    if not domains:
        return f"{prefix}# no {target} domain rules\n"
    return "".join(f"{prefix}- DOMAIN-SUFFIX,{domain},{target}\n" for domain in domains)


def render_template(src: Path, dst: Path, values: dict[str, str]) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    text = Template(src.read_text()).safe_substitute(values)
    dst.write_text(text)


def main() -> None:
    parser = argparse.ArgumentParser(description="Render AgentRouteKit configs.")
    parser.add_argument("--env", default="agent-input.env", help="private env input file")
    parser.add_argument("--out", default="build", help="output directory")
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[1]
    values = parse_env(Path(args.env))

    ai_domains = csv_list(values["AI_DOMAINS"])
    corporate_domains = csv_list(values.get("CORPORATE_DOMAINS", ""))
    direct_domains = csv_list(values.get("DIRECT_DOMAINS", ""))

    values = {
        **values,
        "AI_DOMAIN_JSON_ARRAY": json.dumps(ai_domains, indent=8),
        "AI_RULES": domain_rules(ai_domains, "ai-route"),
        "CORPORATE_DNS_POLICY": indented_yaml_map(corporate_domains, "system"),
        "CORPORATE_RULES": domain_rules(corporate_domains, "DIRECT"),
        "DIRECT_DOMAIN_RULES": domain_rules(direct_domains, "DIRECT"),
    }

    out = Path(args.out)
    render_template(root / "configs/mihomo/config.template.yaml", out / "mihomo/config.yaml", values)
    render_template(root / "configs/sing-box/relay.template.json", out / "sing-box/config.json", values)
    render_template(root / "configs/claude-code/settings.template.json", out / "claude-code/settings.json", values)

    metadata = {
        "local_proxy": f"127.0.0.1:{values['LOCAL_PROXY_PORT']}",
        "mihomo_api": f"127.0.0.1:{values['MIHOMO_API_PORT']}",
        "relay_ssh_target": values["RELAY_SSH_TARGET"],
        "relay_config_path": values["RELAY_SING_BOX_CONFIG_PATH"],
        "relay_service": values["RELAY_SING_BOX_SERVICE"],
        "ai_domains": ai_domains,
        "corporate_domains_count": len(corporate_domains),
        "direct_domains_count": len(direct_domains),
    }
    (out / "deployment-metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
    print(f"Rendered configs to {out}")


if __name__ == "__main__":
    main()
