#!/usr/bin/env bash
# esteira-ondas — dispara ondas de desenvolvimento de forma agnóstica
set -euo pipefail

ORG="${ESTEIRA_ORG:-x-men-evolution}"
ROOT="${DEV_LOCALHOST:-$HOME/src/github.com/x-men-evolution/dev.localhost}"

die() { echo "esteira-ondas: $*" >&2; exit 1; }
usage() { echo "Uso: esteira-ondas <plano.md> <onda> [--base <branch>] [--projeto <proj>] [--taxonomia <tax>] [--dry-run] [--forcar]"; exit "${1:-0}"; }

[[ $# -ge 1 ]] || usage 1
PLANO="$1"; shift
[[ -f "$PLANO" ]] || die "plano não encontrado: $PLANO"
PLANO="$(realpath "$PLANO")"

ONDA="" DRY=0 FORCAR=0 COORD=0 STATUS=0 BASE_CLI="" PROJ_CLI="" TAX_CLI=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) BASE_CLI="${2:-}"; shift ;;
    --projeto) PROJ_CLI="${2:-}"; shift ;;
    --taxonomia) TAX_CLI="${2:-}"; shift ;;
    --dry-run) DRY=1 ;;
    --forcar) FORCAR=1 ;;
    --coordenador) COORD=1 ;;
    --status) STATUS=1 ;;
    [0-9]*) ONDA="$1" ;;
    *) die "opção desconhecida: $1" ;;
  esac
  shift
done

BLOCO="$(awk '/^```esteira-ondas[[:space:]]*$/{f=1;next} f&&/^```/{exit} f' "$PLANO")"
[[ -n "$BLOCO" ]] || die "bloco \`\`\`esteira-ondas não encontrado em $PLANO"

BASE="${BASE_CLI:-$(sed -n 's/^base:[[:space:]]*//p' <<<"$BLOCO" | head -1)}"
[[ -n "$BASE" ]] || die "ERRO OBRIGATÓRIO: Nenhuma branch base informada (via --base ou no plano)."

PROJETO="${PROJ_CLI:-$(sed -n 's/^projeto:[[:space:]]*//p' <<<"$BLOCO" | head -1)}"
TAXONOMIA="${TAX_CLI:-$(sed -n 's/^taxonomia:[[:space:]]*//p' <<<"$BLOCO" | head -1)}"

echo "==> Configuração Ativa:"
echo "    - Branch Base: $BASE"
echo "    - Projeto:     ${PROJETO:-[Padrão do Repositório]}"
echo "    - Taxonomia:   ${TAXONOMIA:-[Padrão do Repositório]}"
