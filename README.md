# plano-ondas — skill do Claude Code

Transforma um plano de desenvolvimento em issues do GitHub e dispara o desenvolvimento em **ondas paralelas**: uma sessão do Claude Code por issue (skill `/esteira`) e uma **sessão coordenadora** que acompanha as outras.

```
plano (.md ou texto) ──► portão: tabela ID/Repo/Título/Onda/Requer + premissas
                     ──► issues (taxonomia, sub-issue do épico, tipo, @me)
                     ──► Projects (Status pelo nome, conferido)
                     ──► plano atualizado (bloco esteira-ondas, §3, §4, §7)
                     ──► esteira-ondas <plano> 1 --coordenador
```

## Estrutura

```
SKILL.md                 instruções da skill (lidas pelo Claude)
modelo-plano.md          layout do plano e do corpo da issue
scripts/criar-issue.py   cria a issue (@me, tipo, rótulos existentes) e liga ao pai
scripts/projeto-status.py  coloca a issue no Project v2 e grava o Status pelo nome
scripts/esteira-ondas.sh abre uma aba (Ptyxis) ou janela (tmux) por task da onda
```

## Instalação

```bash
git clone https://github.com/DjalmaANeto/plano-ondas-skill.git ~/.claude/skills/plano-ondas
# esteira-ondas no PATH, se ainda não houver (a skill esteira traz a mesma versão)
command -v esteira-ondas || ln -s ~/.claude/skills/plano-ondas/scripts/esteira-ondas.sh ~/.local/bin/esteira-ondas
```

Requisitos:
- `gh` autenticado com os escopos `repo` e `project` (`gh auth refresh -s project`).
- Python 3, `bash`, e `ptyxis` (com display) ou `tmux`.
- A skill `/esteira` instalada: é ela que desenvolve cada issue nas sessões abertas.

## Uso

```
/plano-ondas "<caminho/plano.md>" taxonomia AJ, sub-épico api#2428 [projeto Djalma0multfacil#1 x-men-evolution#22] [base feature/atribuicao]
```

| Parâmetro | Padrão |
|---|---|
| Plano | obrigatório (arquivo `.md` ou texto digitado; texto vira `<Título> - SubPlano.md`) |
| Base | do plano; se não houver, a skill pergunta |
| Taxonomia | prefixo do ID (`AJ`), próximo número pelo maior ID existente, sub-épico, tipo (`Feature`), rótulos |
| Projetos | `Djalma0multfacil#1` (Project "Atribuição") |
| Status inicial | `Desenvolvimento` |

Nada é criado antes do **portão**: a skill mostra a divisão em tasks e espera "aprovado".

## Bloco `esteira-ondas` no plano

````markdown
```esteira-ondas
base: feature/atribuicao
projetos: Djalma0multfacil#1 x-men-evolution#22
taxonomia: AJ

onda 1
AJ-18a api#2560
AJ-19  portal-professor#2015

onda 2
AJ-18b portal-professor#2016  requer: api#2560
```
````

Linhas `chave: valor` são metadados. `projetos:` vai para o prompt da sessão coordenadora.

```bash
esteira-ondas "<plano>" --status               # tasks, worktrees e dependências
esteira-ondas "<plano>" 1 --dry-run --coordenador
esteira-ondas "<plano>" 1 --coordenador        # onda 1 + coordenadora
esteira-ondas "<plano>" 2 --coordenador        # só abre o que tem dependência mergeada na base
```

O script pula a task que já tem worktree (`<sub>.worktrees/<n>-*`) e a task com dependência sem PR mergeado na base. `--forcar` ignora as duas travas. `--terminal tmux` força o tmux (`tmux attach -t esteira`).

## Variáveis

| Variável | Uso |
|---|---|
| `DEV_LOCALHOST` | raiz do workspace onde as sessões abrem (padrão `~/src/github.com/x-men-evolution/dev.localhost`) |
| `CLAUDE_BIN` | binário do Claude Code (padrão: `claude` no PATH) |
