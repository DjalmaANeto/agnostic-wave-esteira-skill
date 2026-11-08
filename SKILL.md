---
name: agnostic-wave-esteira
description: Use esta skill quando precisar analisar um plano de desenvolvimento em Markdown, estruturar tarefas paralelas em ondas, validar a branch base obrigatória, aplicar taxonomia e projetos, e orquestrar execuções via worktrees isolados (compatível com Claude Code, Gemini CLI e outros agentes LLM).
---

# Skill Agnóstica: Gestão e Orquestração de Ondas e Esteiras

## Visão Geral
Esta skill capacita agentes LLM a gerenciar o ciclo de vida de desenvolvimento ágil baseando-se em planos estruturados, garantindo isolamento em worktrees e execução orquestrada por ondas.

## Regras Obrigatórias de Execução
1. **Branch Base Obrigatória:** A execução deve parar imediatamente e solicitar a branch base caso não seja informada. Nenhum avanço ou criação de worktree é permitido sem a branch base definida (ex: `--base feature/atribuicao`).
2. **Projeto e Taxonomia com Fallback:** Se `--projeto` ou `--taxonomia` não forem fornecidos, a skill adota automaticamente os padrões configurados no repositório local.
3. **Eficiência de Contexto:** Lógicas pesadas e parsing de tarefas são delegados ao script utilitário `scripts/esteira-ondas.sh`, mantendo a janela de contexto limpa.

## Instruções de Uso
Invoque a skill passando o plano de desenvolvimento e a onda desejada:
```bash
/esteira-ondas caminho/para/plano.md 1 --base feature/minha-branch
```
