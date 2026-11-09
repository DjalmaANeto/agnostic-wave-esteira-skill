---
name: plano-ondas
description: Use quando o usuário enviar um plano de desenvolvimento (arquivo .md do WorkNotes ou texto digitado) pedindo para criar as issues do GitHub a partir dele, com uma taxonomia (prefixo de ID como AJ-, sub-épico, tipo) e um Project, registrar as issues no plano e disparar as ondas de esteira em sessões paralelas com sessão coordenadora. Também quando mencionar "plano em ondas", "criar issues do plano" ou "disparar as ondas".
argument-hint: <plano.md | texto do plano> taxonomia <PREFIXO, sub-épico repo#n, tipo> [projeto <owner#n> …] [base <branch>]
---

# Plano → Issues → Ondas de esteira

Entrada: $ARGUMENTS

Invocar esta skill é o pedido explícito para criar issues no GitHub, colocá-las nos Projects, editar o arquivo do plano e abrir as sessões de esteira da onda 1. Nada além disso: esta sessão **não desenvolve issue nenhuma**, não faz merge nem push. Fonte única: issues do GitHub (sem Trello, sem `fabrica-software`).

Arquivos da skill (em `~/.claude/skills/plano-ondas/`):
- `modelo-plano.md` — layout do plano (bloco `esteira-ondas`, seções 3, 4 e 7) e da issue.
- `~/.claude/skills/plano-ondas/scripts/criar-issue.py` — cria a issue (`@me`, tipo, rótulos existentes) e liga ao pai.
- `~/.claude/skills/plano-ondas/scripts/projeto-status.py` — coloca no Project e grava o Status pelo nome, conferindo depois.
- Disparo: `esteira-ondas` no PATH. Sem ele, use `bash ~/.claude/skills/plano-ondas/scripts/esteira-ondas.sh` (cópia empacotada do script da skill `esteira`).

Rode os `.py` com `python3 -I <caminho>`. Todos aceitam `--dry-run`.

## 1. Parâmetros

| Parâmetro | De onde vem | Sem informar |
|---|---|---|
| Plano | caminho `.md` ou texto no pedido | — (obrigatório) |
| Base | pedido, ou "branch base" no cabeçalho do plano | **pergunte**; não assuma `develop` |
| Taxonomia: prefixo do ID | pedido (`AJ`, `AL`, …) | prefixo já usado no plano; senão pergunte |
| Taxonomia: próximo número | maior ID existente + 1 (`gh search issues --owner x-men-evolution "<PREFIXO>-" --match title --sort created --limit 200 --json title`) | idem |
| Taxonomia: sub-épico (pai) | pedido ou "Sub-Épico" do plano (`repo#n`) | sem pai e sem `[…]` no título |
| Taxonomia: nome do sub-épico | título do pai, entre "Sub-Épico: " e " (" (ex.: `Atribuição - Alocação`) | — |
| Taxonomia: tipo | pedido | `Feature` (`Bug` para hotfix) |
| Taxonomia: rótulos | pedido | nenhum |
| Projetos | pedido, como `owner#numero` (aceite o nome: Atribuição = `Djalma0multfacil#1`, Educafácil = `x-men-evolution#22`) | `Djalma0multfacil#1` (Project "Atribuição", o padrão da `esteira`) |
| Status inicial | pedido | `Desenvolvimento` |

Projeto dado só pelo título: resolva com `gh project list --owner <owner>`.

## 2. Decompor o plano em tasks

1. Leia o plano inteiro. Plano sem diagnóstico do código → despache o `explorador` para localizar arquivos e endpoints de cada pedido (caminho:linha), antes de escrever as issues.
2. Uma task por pedido **por repositório**. Pedido que toca api e portal vira `<ID>a` (api) e `<ID>b` (portal), e `b` requer `a`. Cada pedido tem ID próprio, mesmo quando depende de outro pedido.
3. Dependências: entre tasks do plano e com issues de fora (`repo#n` já existentes).
4. Onda = 1 se não depende de task do plano; senão 1 + maior onda entre as dependências. Dependência de fora entra no `requer:` mas não empurra a onda.
5. **Portão (único):** mostre a tabela abaixo e espere "aprovado". Não crie nada antes.

| ID | Repo | Título (taxonomia) | Onda | Requer |
|---|---|---|---|---|

Junto da tabela: base, pai, tipo, rótulos, Projects, Status inicial, o arquivo do plano que será editado (ou criado) e a lista de **premissas** — toda decisão de divisão ou de dependência que o plano não dizia explicitamente.

## 3. Criar as issues

Na ordem das ondas (dependência antes de quem depende, para o "Requer" citar números reais). Para cada task:

1. Corpo no formato de `modelo-plano.md` § Issue, num arquivo em `$CLAUDE_JOB_DIR/tmp` (ou no scratchpad).
2. `python3 -I ~/.claude/skills/plano-ondas/scripts/criar-issue.py --repo <repo> --titulo "<título>" --corpo <arquivo> --tipo <tipo> [--pai <repo#n>] [--rotulo <r>]` → URL na última linha.
3. Para cada Project: `python3 -I ~/.claude/skills/plano-ondas/scripts/projeto-status.py <owner#n> <url> "<status>"`. Falha de conferência → rode de novo uma vez; persistindo, registre e siga.

Erro no meio do lote: pare, liste o que já foi criado (URLs) e pergunte. Não recrie issues já criadas.

## 4. Registrar no plano

- **Arquivo enviado:** edite-o no lugar, seguindo `modelo-plano.md`: seção "▶ Disparo orquestrado das ondas" no topo com o bloco `esteira-ondas` (`base:`, `projetos:`, `taxonomia:`, ondas com `requer:`), tabela da §3 com links, §4 com o diagrama das ondas e o caminho crítico, §7 com 7.1 regras, uma subseção por onda (7.2, 7.3, …) com checklist, e a coordenadora na última. Conteúdo existente (pedidos, diagnóstico, decisões) fica.
- **Texto digitado:** grave como `~/src/github.com/djalmaaneto/WorkNotes/PlanoDesenvoivimento/<Título> - SubPlano.md` no mesmo layout, com o texto original na §1. "Vinculado a" só com o que o usuário citou.
- Confira: `esteira-ondas "<plano>" --status` lista exatamente as tasks criadas, nas ondas certas.

## 5. Disparar a onda 1

```bash
esteira-ondas "<plano>" 1 --dry-run --coordenador   # confira as sessões
esteira-ondas "<plano>" 1 --coordenador             # uma sessão por issue + sessão coordenadora
```

- Abre uma aba do Ptyxis por issue, cada uma com `claude "/esteira <url> base <base> …"`, e a sessão coordenadora (`coord-onda-1`), que acompanha as outras, confere o Status nos Projects e marca os checklists da §7. Sem display, o script usa tmux: avise `tmux attach -t esteira`.
- Ondas seguintes ficam travadas até o PR da dependência ser mergeado na base. Quando a coordenadora avisar: `esteira-ondas "<plano>" <n> --coordenador` (ou `--forcar` para empilhar).
- Subagente não roda a esteira: as sessões saem só do `esteira-ondas`.

## 6. Fechar

- Memória de projeto `issues-<prefixo>-<primeiro>-<último>-<slug>.md`: plano, tabela ID/issue/onda/requer, Projects, base, decisões.
- Relatório: issues criadas (links), plano editado, sessões abertas (terminal e títulos), próximo comando (`esteira-ondas "<plano>" 2 --coordenador` quando liberar).

## Erros comuns

| Erro | Correção |
|---|---|
| Linha `chave: valor` no bloco virando task | Só `base:`, `projetos:`, `taxonomia:`; o script ignora `chave:` e lê `projetos:` para a coordenadora |
| Renumerar/mover as seções 3, 4 e 7 | O prompt das sessões cita esses números; mantenha |
| Status em um Project mudou o outro | Atribuição e Educafácil sincronizam por option id; o `projeto-status.py` confere cada Project separadamente |
| Rótulo `atribuicao` na api | Só existe no portal-professor; o script ignora com aviso |
| Disparar onda 2 junto com a 1 | As travas do script existem por isso; empilhar só com `--forcar` e pedido do usuário |
