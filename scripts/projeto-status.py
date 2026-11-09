#!/usr/bin/env python3
"""Garante a issue num GitHub Project (v2) e grava o Status pelo NOME da opção, conferindo depois.

Uso:
  python3 projeto-status.py <owner#numero> <url-da-issue> "<status>" [--dry-run]
  python3 projeto-status.py <owner#numero> --opcoes          # lista as opções de Status

O nome casa sem acento, emoji ou caixa: "Desenvolvimento" casa "⚙ Em desenvolvimento".
Os workflows dos Projects regravam o Status logo depois de item-add; por isso o script espera,
confere com item-list e grava de novo (até 3 vezes).
"""
import json
import re
import subprocess
import sys
import time
import unicodedata


def gh(args):
    r = subprocess.run(["gh", *args], capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f"projeto-status: gh {' '.join(args[:3])}… falhou: {r.stderr.strip()}")
    return r.stdout.strip()


def norm(s):
    s = unicodedata.normalize("NFKD", s)
    return re.sub(r"[^a-z0-9]", "", "".join(c for c in s if not unicodedata.combining(c)).lower())


def opcao(opcoes, nome):
    alvo = norm(nome)
    exatas = [o for o in opcoes if norm(o["name"]) == alvo]
    if exatas:
        return exatas[0]
    parciais = [o for o in opcoes if alvo in norm(o["name"])]
    if len(parciais) == 1:
        return parciais[0]
    nomes = ", ".join(o["name"] for o in opcoes)
    sys.exit(f"projeto-status: Status '{nome}' {'ambíguo' if parciais else 'não existe'}; opções: {nomes}")


def main():
    argv = sys.argv[1:]
    dry = "--dry-run" in argv
    argv = [x for x in argv if x != "--dry-run"]
    if not argv or "#" not in argv[0]:
        sys.exit(__doc__)
    owner, numero = argv[0].split("#")

    pid = gh(["project", "view", numero, "--owner", owner, "--format", "json", "-q", ".id"])
    campos = json.loads(gh(["project", "field-list", numero, "--owner", owner, "--format", "json"]))["fields"]
    status = next((f for f in campos if f["name"] == "Status"), None) or sys.exit("projeto-status: campo Status ausente")

    if len(argv) >= 2 and argv[1] == "--opcoes":
        for o in status["options"]:
            print(f"{o['id']}\t{o['name']}")
        return
    if len(argv) < 3:
        sys.exit(__doc__)
    url, nome = argv[1], argv[2]
    op = opcao(status["options"], nome)

    if dry:
        print(f"[dry-run] {owner}#{numero} ({pid}): {url} → '{op['name']}' ({op['id']}), campo {status['id']}")
        return

    item = gh(["project", "item-add", numero, "--owner", owner, "--url", url, "--format", "json", "-q", ".id"])
    for tentativa in range(3):
        gh(["project", "item-edit", "--project-id", pid, "--id", item,
            "--field-id", status["id"], "--single-select-option-id", op["id"]])
        time.sleep(4)
        itens = json.loads(gh(["project", "item-list", numero, "--owner", owner, "--limit", "1000", "--format", "json"]))["items"]
        atual = next((i.get("status") for i in itens if i["id"] == item), None)
        if atual == op["name"]:
            print(f"{owner}#{numero}: {url} → {atual}")
            return
    sys.exit(f"projeto-status: {url} ficou em '{atual}' em {owner}#{numero} (esperado '{op['name']}')")


if __name__ == "__main__":
    main()
