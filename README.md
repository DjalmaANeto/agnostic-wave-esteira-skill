# Agnostic Wave & Esteira Skill for LLM Agents

## Sobre a Skill
Esta skill foi construída seguindo as **melhores práticas oficiais da Anthropic para Agent Skills** (Progressive Disclosure, eficiência de contexto, modularidade) e incorpora o mecanismo avançado de divisão de tarefas em **Ondas e Esteiras**, garantindo validação estrita de branch base, projetos e taxonomia.

---

## 🏗️ Estrutura da Skill
```text
agnostic-wave-esteira-skill/
├── SKILL.md              # Metadados e instruções para o LLM (Divulgação Progressiva Níveis 1 e 2)
├── scripts/              # Scripts determinísticos para lógica complexa (Nível 3)
│   └── esteira-ondas.sh
└── README.md             # Documentação, instalação e uso
```

---

## 🚀 Como Instalar

1. Clone o repositório no seu diretório de extensões/skills ou no workspace do seu agente LLM:
   ```bash
   git clone https://github.com/DjalmaANeto/agnostic-wave-esteira-skill.git
   ```
2. Certifique-se de que o script auxiliar possui permissão de execução:
   ```bash
   chmod +x agnostic-wave-esteira-skill/scripts/esteira-ondas.sh
   ```

---

## 💻 Como Usar

No prompt do seu agente LLM (compatível com Claude Code, Gemini CLI, etc.):

1. Informe o plano de desenvolvimento em Markdown contendo o bloco `esteira-ondas`.
2. Especifique a onda e a branch base obrigatória:
   ```text
   /agnostic-wave-esteira plano.md 1 --base feature/minha-branch
   ```

### Exemplo de Bloco no Plano (`plano.md`):
```markdown
```esteira-ondas
base: feature/atribuicao
projeto: Atribuição
taxonomia: AJ-XX

onda 1
AJ-07  portal-professor#1982
AJ-08  portal-professor#1983
```
```
