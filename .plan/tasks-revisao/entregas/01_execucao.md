# Execução da Tarefa 01 — inventário e rastreabilidade

Data: 2026-09-07  
Diretório de trabalho: `/Users/caiosainvallio/consultoria/scoliosis_model`

## Comandos executados

Todos os comandos shell foram prefixados com `rtk`, conforme `RTK.md`.

| Comando/ação | Finalidade | Resultado |
|---|---|---|
| `rtk git status --short --branch` | Registrar o estado de entrada | `main...origin/main`, sem alterações. |
| `rtk git log -1 --format=...` | Fixar commit e data de referência | Commit `40cf190...`, 2026-09-07. |
| `rtk sed -n ...` nos arquivos da task, índice, parecer, plano original e Tarefa 12 | Ler escopo, dependências, decisões e evidências | Leitura concluída; nenhuma dependência analítica pendente para a Tarefa 01. |
| `rtk rg --files ...` | Inventariar QMD, HTML, R, scripts, testes, tabelas, figuras, objetos e logs | Inventário concluído: 82 tabelas, 16 figuras, 49 logs e 10 objetos reduzidos no baseline prognóstico. |
| `rtk rg -n ...` | Identificar seções do parecer, pontos de configuração e comandos existentes | Mapa do parecer e pontos em `R/00_config.R` registrados em `01_inventario.md`. |
| `rtk shasum -a 256 ...` | Registrar hashes da fonte, relatórios, modelos e saídas principais | Hashes registrados em `manifesto_inicial.csv` e `01_inventario.md`. |
| `rtk stat -f ...` | Registrar tamanho e modificação de artefatos-chave | Fonte, relatórios e objetos congelados preservados; metadados consolidados no ambiente inicial. |
| `rtk Rscript --vanilla -e ...` | Consultar R, pacotes instalados e `sessionInfo()` | R 4.6.1 e pacotes disponíveis registrados; nenhuma instalação ou ajuste executado. |
| `rtk quarto --version` e `rtk rtk --version` | Registrar ferramentas de execução | Quarto 1.6.40 e RTK 0.44.1. |
| `rtk mkdir -p results/prognostico/revisao/... .plan/tasks-revisao/entregas` | Criar a estrutura exclusiva da revisão | Diretórios `aggregated`, `figures`, `logs`, `reduced_objects` e `entregas` criados. |

## Arquivos produzidos ou alterados

Produzidos nesta task:

- `.plan/tasks-revisao/entregas/01_inventario.md`;
- `.plan/tasks-revisao/entregas/01_execucao.md`;
- `results/prognostico/revisao/logs/manifesto_inicial.csv`;
- `results/prognostico/revisao/logs/ambiente_inicial.txt`.

Diretórios vazios criados para as próximas tasks:

- `results/prognostico/revisao/aggregated/`;
- `results/prognostico/revisao/figures/`;
- `results/prognostico/revisao/logs/`;
- `results/prognostico/revisao/reduced_objects/`;
- `.plan/tasks-revisao/entregas/`.

Não foram alterados `data/`, `analisys.*`, `relatorio_prognostico.*`, `R/`, scripts, testes ou qualquer artefato existente em `results/prognostico/` fora da árvore `revisao/`.

## Verificações

- Git inicial limpo, preservado no registro do ambiente.
- Hash da planilha vigente confere com o manifesto da Tarefa 12: `f601adb42c299c2b0572f3e50ff26550b63a2f24dd7173f244a442b498965b71`.
- Coorte, eventos, parâmetros, réplicas e ausência de falhas foram consumidos do manifesto já verificado da Tarefa 12, sem recalcular nesta task.
- Os quatro subdiretórios de revisão existem e não receberam resultados analíticos nesta task.
- O manifesto liga saídas atuais e planejadas a fonte, script/processo, versão/commit e task responsável.
- O documento de entrega mapeia todas as recomendações do parecer às tasks 02–15.
- `R/00_config.R` foi lido e seus caminhos de entrada, saída e sementes foram registrados.

## Limitações e pendências

- `pROC`, `rsample`, `yardstick` e `furrr` não estão instalados no ambiente atual; isso foi registrado como disponibilidade de ambiente, sem instalação. A ausência não foi tratada como aprovação ou falha analítica nesta task.
- O código existente escreve no baseline `results/prognostico/`; as tasks que gerarem resultados corrigidos deverão introduzir destino explícito em `results/prognostico/revisao/` antes da execução.
- Diretórios vazios não são materializados no Git até receberem arquivos; sua criação foi verificada no sistema de arquivos.
- Não foram reexecutados bootstraps, CV, ajustes de modelos ou Quarto, conforme escopo explícito da task.

## Passagem

Saídas para consumo: `01_inventario.md`, `manifesto_inicial.csv` e `ambiente_inicial.txt`. Dependências afetadas: nenhuma. Próxima task: 02, a ser executada separadamente.

