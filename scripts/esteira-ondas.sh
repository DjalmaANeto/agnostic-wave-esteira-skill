#!/usr/bin/env bash
# esteira-ondas — dispara uma onda de um plano de desenvolvimento: abre um terminal
# por task rodando `claude "/esteira <issue> ..."` no dev.localhost.
#
# O plano (nota .md) precisa ter um bloco cercado ```esteira-ondas:
#
#   base: feature/atribuicao
#   projetos: Djalma0multfacil#1 x-men-evolution#22   (opcional; padrão: Atribuição + Educafácil)
#   onda 1
#   AJ-07  portal-professor#1982
#   onda 2
#   AJ-09b portal-professor#1984  requer: portal-professor#1983 api#2523
#
# Uso:
#   esteira-ondas <plano.md> <onda> [--dry-run] [--forcar] [--coordenador] [--terminal ptyxis|tmux]
#   esteira-ondas <plano.md> --status
#
#   --dry-run      mostra o que seria aberto, sem abrir nada
#   --forcar       abre mesmo com dependência não mergeada ou worktree já existente
#   --coordenador  abre também uma sessão coordenadora (acompanha as outras, não desenvolve)
#   --terminal     ptyxis (padrão se houver display) ou tmux (sessão "esteira")
#   --status       lista as tasks de todas as ondas com o estado de worktree e dependências
set -euo pipefail

ORG="x-men-evolution"
ROOT="${DEV_LOCALHOST:-$HOME/src/github.com/x-men-evolution/dev.localhost}"
CLAUDE_BIN="${CLAUDE_BIN:-$(command -v claude || true)}"

die() { echo "esteira-ondas: $*" >&2; exit 1; }
usage() { sed -n '2,23p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

[[ $# -ge 1 ]] || usage 1
[[ "$1" == "-h" || "$1" == "--help" ]] && usage 0
PLANO="$1"; shift
[[ -f "$PLANO" ]] || die "plano não encontrado: $PLANO"
PLANO="$(realpath "$PLANO")"

ONDA="" DRY=0 FORCAR=0 COORD=0 STATUS=0 TERM_KIND=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --forcar) FORCAR=1 ;;
    --coordenador) COORD=1 ;;
    --status) STATUS=1 ;;
    --terminal) TERM_KIND="${2:-}"; shift ;;
    -h|--help) usage 0 ;;
    [0-9]*) ONDA="$1" ;;
    *) die "opção desconhecida: $1" ;;
  esac
  shift
done
[[ $STATUS -eq 1 || -n "$ONDA" ]] || die "informe o número da onda (ou --status)"

# --- Leitura do bloco ```esteira-ondas -------------------------------------------
BLOCO="$(awk '/^```esteira-ondas[[:space:]]*$/{f=1;next} f&&/^```/{exit} f' "$PLANO")"
[[ -n "$BLOCO" ]] || die "bloco \`\`\`esteira-ondas não encontrado em $PLANO"

BASE="$(sed -n 's/^base:[[:space:]]*//p' <<<"$BLOCO" | head -1)"
[[ -n "$BASE" ]] || die "linha 'base: <branch>' ausente no bloco esteira-ondas"
PROJETOS="$(sed -n 's/^projetos:[[:space:]]*//p' <<<"$BLOCO" | head -1)"
if [[ -n "$PROJETOS" ]]; then
  PROJETOS_TXT="Projects $(sed 's/[[:space:]]\+/, /g' <<<"$PROJETOS") (owner#número)"
else
  PROJETOS_TXT="Projects Atribuição (Djalma0multfacil #1) e Educafácil (#22)"
fi

# Emite "onda<TAB>id<TAB>repo<TAB>numero<TAB>requer" por task.
tasks() {
  awk '
    /^[[:space:]]*#/ || NF==0 { next }
    tolower($1)=="onda" { onda=$2; next }
    $1 ~ /^[A-Za-z_]+:/ { next }  # metadados (base:, projetos:, taxonomia:)
    {
      id=$1; split($2, r, "#"); req=""
      for (i=3; i<=NF; i++) { if ($i ~ /^requer:/) continue; req = req (req==""?"":" ") $i }
      printf "%s\t%s\t%s\t%s\t%s\n", onda, id, r[1], r[2], req
    }' <<<"$BLOCO"
}

# --- Checagens -------------------------------------------------------------------
declare -A MERGED_CACHE=()
pr_mergeado() { # repo numero -> 0 se há PR mergeado na BASE que referencia a issue
  local repo="$1" n="$2" key="$1"
  if [[ -z "${MERGED_CACHE[$key]+x}" ]]; then
    MERGED_CACHE[$key]="$(gh pr list -R "$ORG/$repo" --base "$BASE" --state merged --limit 300 \
      --json number,body,title --jq '.[] | "\(.title)\n\(.body)"' 2>/dev/null || true)"
  fi
  grep -Eq "(^|[^0-9A-Za-z/_-]|${repo})#${n}([^0-9]|$)" <<<"${MERGED_CACHE[$key]}"
}

worktree_existente() { # repo numero -> caminho do worktree, se existir
  compgen -G "$ROOT/$1.worktrees/$2-*" | head -1 || true
}

# --- Montagem do prompt ------------------------------------------------------------
prompt_task() { # id repo numero
  printf '/esteira https://github.com/%s/%s/issues/%s base %s. Task %s do plano: %s (seções 3 e 4). Há outras sessões de esteira em paralelo nesta onda: se o push na branch de homologação tomar reject, refaça fetch + worktree detached + cherry-pick e tente de novo, sem force.' \
    "$ORG" "$2" "$3" "$BASE" "$1" "$PLANO"
}

prompt_coordenador() { # onda lista_ids
  printf 'Você é a sessão coordenadora da onda %s do plano %s (tasks: %s). Não desenvolva nenhuma issue. Use ListAgents para acompanhar as sessões de esteira abertas, SendMessage só se eu pedir, confira o Status das issues nos %s, e avise quando uma dependência da próxima onda for mergeada na %s. Marque os checklists da seção 7 do plano conforme os PRs avançarem. Rode `%s \"%s\" --status` para o panorama.' \
    "$1" "$PLANO" "$2" "$PROJETOS_TXT" "$BASE" "$(basename "$0")" "$PLANO"
}

# --- Abertura dos terminais --------------------------------------------------------
if [[ -z "$TERM_KIND" ]]; then
  if [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]] && command -v ptyxis >/dev/null; then TERM_KIND=ptyxis
  elif command -v tmux >/dev/null; then TERM_KIND=tmux
  else die "nem ptyxis (com display) nem tmux disponíveis"; fi
fi

ABERTOS=0
abrir() { # titulo prompt
  local titulo="$1" prompt="$2"
  if [[ $DRY -eq 1 ]]; then
    printf '  [dry-run] %s: %s %q\n' "$titulo" "$CLAUDE_BIN" "$prompt"
    return
  fi
  case "$TERM_KIND" in
    ptyxis)
      local modo=--tab
      [[ $ABERTOS -eq 0 ]] && modo=--new-window
      ptyxis "$modo" -T "$titulo" -d "$ROOT" -- \
        bash -lc '"$0" "$1"; echo; echo "[esteira-ondas] sessão encerrada"; exec bash' "$CLAUDE_BIN" "$prompt" \
        >/dev/null 2>&1 &
      disown
      [[ $ABERTOS -eq 0 ]] && sleep 1.5 || sleep 0.5
      ;;
    tmux)
      if tmux has-session -t esteira 2>/dev/null; then
        tmux new-window -t esteira -n "$titulo" -c "$ROOT" "$CLAUDE_BIN" "$prompt"
      else
        tmux new-session -d -s esteira -n "$titulo" -c "$ROOT" "$CLAUDE_BIN" "$prompt"
      fi
      ;;
    *) die "terminal inválido: $TERM_KIND" ;;
  esac
  ABERTOS=$((ABERTOS + 1))
  echo "  aberto: $titulo"
}

# --- Status ----------------------------------------------------------------------
if [[ $STATUS -eq 1 ]]; then
  echo "Plano: $PLANO  (base $BASE)"
  while IFS=$'\t' read -r onda id repo n req; do
    wt="$(worktree_existente "$repo" "$n")"
    deps=""
    for d in $req; do
      if pr_mergeado "${d%%#*}" "${d##*#}"; then deps+=" $d✓"; else deps+=" $d✗"; fi
    done
    printf 'onda %s  %-7s %s#%-5s worktree:%-4s requer:%s\n' "$onda" "$id" "$repo" "$n" \
      "$([[ -n $wt ]] && echo sim || echo não)" "${deps:- —}"
  done < <(tasks)
  exit 0
fi

# --- Disparo da onda ---------------------------------------------------------------
[[ -n "$CLAUDE_BIN" && -x "$CLAUDE_BIN" ]] || die "claude não encontrado no PATH (defina CLAUDE_BIN)"
[[ $DRY -eq 1 ]] || command -v gh >/dev/null || die "gh não encontrado"

mapfile -t LINHAS < <(tasks | awk -F'\t' -v o="$ONDA" '$1==o')
[[ ${#LINHAS[@]} -gt 0 ]] || die "onda $ONDA não tem tasks no plano"

echo "Onda $ONDA — base $BASE — terminal $TERM_KIND$([[ $DRY -eq 1 ]] && echo ' (dry-run)')"
IDS=()
for linha in "${LINHAS[@]}"; do
  IFS=$'\t' read -r _ id repo n req <<<"$linha"
  wt="$(worktree_existente "$repo" "$n")"
  if [[ -n "$wt" && $FORCAR -eq 0 ]]; then
    echo "  pulado: $id ($repo#$n) já tem worktree em $wt (use --forcar)"; continue
  fi
  pendentes=()
  for d in $req; do pr_mergeado "${d%%#*}" "${d##*#}" || pendentes+=("$d"); done
  if [[ ${#pendentes[@]} -gt 0 && $FORCAR -eq 0 ]]; then
    echo "  pulado: $id ($repo#$n) aguarda merge em $BASE de: ${pendentes[*]} (use --forcar para empilhar)"; continue
  fi
  abrir "$id" "$(prompt_task "$id" "$repo" "$n")"
  IDS+=("$id")
done

if [[ $COORD -eq 1 && ${#IDS[@]} -gt 0 ]]; then
  abrir "coord-onda-$ONDA" "$(prompt_coordenador "$ONDA" "${IDS[*]}")"
fi

[[ ${#IDS[@]} -gt 0 ]] || { echo "Nenhuma task aberta."; exit 0; }
[[ $TERM_KIND == tmux && $DRY -eq 0 ]] && echo "Anexe com: tmux attach -t esteira"
echo "Pronto: ${IDS[*]}. Aprove o plano de cada esteira na aba dela."
