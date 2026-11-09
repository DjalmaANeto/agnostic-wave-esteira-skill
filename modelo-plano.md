# Modelo do plano e da issue

O `esteira-ondas.sh` cita "seções 3 e 4" no prompt de cada esteira e "seção 7" no do coordenador. Mantenha estes números. Seções que o plano já tem (pedidos, diagnóstico, decisões) ficam como estão; renumere só se colidirem.

## Plano (`<Título> - SubPlano.md`)

````markdown
# Sub-Plano — <Título>

> **Vinculado a:** [[<plano mestre>]] · Daily [[AAAA-MM-DD]]
> **Data:** DD/MM/AAAA
> **Status:** #em-desenvolvimento
> **Sub-Épico:** `<nome>` ([<repo>#<n>](https://github.com/<org>/<repo>/issues/<n>))
> **Escopo:** `<submódulos>`, branch base `<base>`

---

## ▶ Disparo orquestrado das ondas

```bash
P="<caminho absoluto do plano>"

esteira-ondas "$P" --status                 # panorama: worktree e dependências por task
esteira-ondas "$P" 1 --dry-run              # confere o que vai abrir
esteira-ondas "$P" 1 --coordenador          # onda 1: <k> esteiras + sessão coordenadora
esteira-ondas "$P" 2 --coordenador          # onda 2: só abre a task com dependências mergeadas na base
```

- Uma aba do Ptyxis (ou janela do tmux, sessão `esteira`) por task, rodando `claude "/esteira <issue> base <base> …"`. O script lê o bloco abaixo.
- Pula task com worktree e task com dependência sem PR mergeado na base; `--forcar` ignora as duas travas.

```esteira-ondas
base: <base>
projetos: <owner#numero> [<owner#numero> …]
taxonomia: <PREFIXO>

onda 1
<ID>  <repo>#<n>
<ID>  <repo>#<n>

onda 2
<ID>  <repo>#<n>  requer: <repo>#<n> [<repo>#<n> …]
```

---

## 1. Pedidos de origem
## 2. Diagnóstico

## 3. Issues

Todas são sub-issues de <repo>#<n>, do tipo <Tipo>, com Status **<status>** nos Projects <lista>.

| ID | Repo | Tarefa | Issue | Depende de |
| --- | --- | --- | --- | --- |
| **<ID>** | api | <tarefa> | [api#<n>](https://github.com/<org>/api/issues/<n>) | — |

## 4. Paralelismo e ordem de dependência

```
Onda 1 (paralelo)            Onda 2
<ID>a api ──────────────────► <ID>b portal
```

- **Onda 1:** … **Onda 2:** … **Caminho crítico:** …

## 5. Decisões e premissas
## 6. Como desenvolver

Skill `esteira` em cada issue, base `<base>`, na ordem das ondas. PR draft → homologação → smoke.

## 7. Execução paralela

### 7.1 Regras comuns
- **Base:** `<base>`. **Portão de plano:** cada esteira para no plano; aprove uma por vez.
- **Push na homologação:** reject → fetch + worktree detached + cherry-pick, sem force.
- **Merge:** fica com humanos.

### 7.2 Onda 1: <k> sessões em paralelo

Checklist da onda 1:
- [ ] <ID> ([<repo>#<n>](<url>)): PR draft, homolog, smoke, merge

### 7.3 Onda 2 (uma subseção por onda: 7.4, 7.5, …)

Checklist da onda 2:
- [ ] <ID> ([<repo>#<n>](<url>)): PR draft, homolog, smoke, merge

### 7.<última> Sessão coordenadora

Aberta com `--coordenador`, não executa issues: acompanha as sessões (`ListAgents`), confere o Status nos Projects, avisa quando a dependência da próxima onda é mergeada e marca os checklists acima.
````

## Issue

Título: `[<Sub-épico>] <ID> · [<CAMADA>] <TAREFA EM CAIXA ALTA>` — CAMADA `API` para `api`, `PORTAL` para `portal-*`, nome do repo em caixa alta nos demais.

```markdown
**Sub-Épico GitHub Projects:** `<nome>` (<org>/<repo>#<n>)
**Plano:** WorkNotes › `PlanoDesenvoivimento/<arquivo>.md`
**Base:** `<base>`
**Tela:** `<rota>`            ← só se houver

---

### Contexto
<o que existe hoje, com caminho:linha do diagnóstico>

### Objetivo
<comportamento esperado, em uma ou duas frases>

### Resolução técnica
- <passos/arquivos, sem decidir o que o plano não decidiu>

### Checklist
- [ ] Teste red (<Pest Feature | spec Karma>): <comportamento>
- [ ] <demais itens>
- [ ] Lint e suíte do módulo verdes.

### Pronto quando
<critério observável>, em homologação.

**Paralelismo:** onda <k>. Requer <org>/<repo>#<n>. ← omita "Requer" se não houver
```
