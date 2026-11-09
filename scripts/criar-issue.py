#!/usr/bin/env python3
"""Cria uma issue no GitHub (atribuída a @me) e, se pedido, liga como sub-issue do pai.

Uso:
  python3 criar-issue.py --repo api --titulo "..." --corpo corpo.md \
      [--tipo Feature] [--pai api#2428] [--rotulo atribuicao ...] [--org x-men-evolution] [--dry-run]

Imprime a URL da issue criada na última linha da saída.
Rótulo que não existe no repositório é ignorado com aviso (ex.: `atribuicao` só existe no portal-professor).
"""
import argparse
import json
import subprocess
import sys


def gh(args, dry=False):
    if dry:
        print("[dry-run] gh " + " ".join(repr(a) if " " in a else a for a in args))
        return ""
    r = subprocess.run(["gh", *args], capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f"criar-issue: gh {' '.join(args[:3])}… falhou: {r.stderr.strip()}")
    return r.stdout.strip()


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--org", default="x-men-evolution")
    p.add_argument("--repo", required=True)
    p.add_argument("--titulo", required=True)
    p.add_argument("--corpo", required=True, help="arquivo com o corpo em Markdown")
    p.add_argument("--tipo", default="Feature")
    p.add_argument("--pai", help="repo#numero da issue pai (sub-épico)")
    p.add_argument("--rotulo", action="append", default=[])
    p.add_argument("--dry-run", action="store_true")
    a = p.parse_args()

    full = f"{a.org}/{a.repo}"
    rotulos = []
    if a.rotulo:
        lista = gh(["label", "list", "-R", full, "--limit", "500", "--json", "name"])
        existentes = {l["name"] for l in json.loads(lista or "[]")}
        for r in a.rotulo:
            if r in existentes:
                rotulos.append(r)
            else:
                print(f"aviso: rótulo '{r}' não existe em {full}; ignorado", file=sys.stderr)

    cmd = ["issue", "create", "-R", full, "--title", a.titulo, "--body-file", a.corpo,
           "--assignee", "@me", "--type", a.tipo]
    for r in rotulos:
        cmd += ["--label", r]
    url = gh(cmd, a.dry_run) or f"https://github.com/{full}/issues/<novo>"

    if a.pai:
        prepo, pnum = a.pai.split("#")
        numero = url.rstrip("/").split("/")[-1]
        if a.dry_run:
            print(f"[dry-run] ligar {full}#{numero} como sub-issue de {a.org}/{prepo}#{pnum}")
        else:
            sub_id = gh(["api", f"repos/{full}/issues/{numero}", "-q", ".id"])
            gh(["api", "-X", "POST", f"repos/{a.org}/{prepo}/issues/{pnum}/sub_issues",
                "-F", f"sub_issue_id={sub_id}"])
    print(url)


if __name__ == "__main__":
    main()
