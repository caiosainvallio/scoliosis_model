# Entrega da Tarefa 01 — inventário e rastreabilidade

Data: 2026-09-07  
Commit de referência: `40cf1900322321bbc6e9c9bce3759089a641d4a6`  
Task: `.plan/tasks-revisao/01_inventario_e_rastreabilidade.md`

## Resultado

O inventário inicial foi concluído sem alterar a base, os relatórios históricos, os modelos congelados ou os resultados existentes. A árvore de revisão foi criada em `results/prognostico/revisao/`, com os quatro subdiretórios previstos, e as evidências desta task estão em `.plan/tasks-revisao/entregas/`.

O estado de entrada do Git estava limpo (`main...origin/main`, sem arquivos modificados, não rastreados ou staged). As únicas alterações desta task são os dois registros de execução, este inventário e a nova árvore de revisão com seu manifesto e ambiente inicial.

## Classificação dos artefatos existentes

| Classe | Conteúdo | Tratamento nesta revisão |
|---|---|---|
| Fonte congelada | `data/dataset_escoliose_01.xlsx`, aba `dados` | Somente leitura; hash registrado. É a fonte vigente da coorte. |
| Histórico | `analisys.qmd`, `analisys.html`, `diagnostico_modelos/`, `parecer-estatistico.md`, `avaliacao_tamanho_amostral.txt` e planilhas anteriores em `data/` | Preservado para comparação e contexto; não fornece números finais sem recálculo. |
| Baseline prognóstico congelado | `relatorio_prognostico.qmd`, `relatorio_prognostico.html`, `R/`, `scripts/`, `tests/` e `results/prognostico/{aggregated,figures,logs,reduced_objects}` | Saídas e código existentes são a referência auditável da etapa anterior. Não foram sobrescritos. |
| Revisão | `results/prognostico/revisao/` e `.plan/tasks-revisao/entregas/` | Destino exclusivo das correções, complementos e evidências das tasks 01–15. Nesta task só há manifesto, ambiente e documentação. |

O baseline contém 82 tabelas agregadas, 16 figuras, 49 logs e 10 objetos reduzidos. A revisão começa sem tabelas, figuras ou objetos analíticos próprios; portanto, nenhum resultado novo deve ser consumido como resultado corrigido nesta passagem.

## Hashes de preservação e rastreabilidade

Os hashes SHA-256 abaixo foram calculados no estado de entrada e também estão registrados no manifesto CSV. Eles permitem conferir a identidade da fonte, dos relatórios de referência, dos modelos congelados e das principais saídas.

| Artefato | SHA-256 |
|---|---|
| `data/dataset_escoliose_01.xlsx` | `f601adb42c299c2b0572f3e50ff26550b63a2f24dd7173f244a442b498965b71` |
| `analisys.qmd` | `3c94a887beb80ef9ee77b150ce36260da689a4a3e14b094120752597002ffed6` |
| `analisys.html` | `8a07621a60a5314c9b5f2a11b418c859bc4451cfe8157703f47164eb055336bc` |
| `relatorio_prognostico.qmd` | `24c9f1e33020fc6fda630156f0933096155b3700b462bc726410f9af89e4d86c` |
| `relatorio_prognostico.html` | `93bc76bfa46c80d00f62532cabcee362e15fc6b6599a9fc62f3eb7d629222f2d` |
| `.plan/00_alteracao_prognostico.md` | `f3f7c950b24e6aeec564059899a45f1aa99f1a31a067f26bc0a09f36d2911d64` |
| `revisao_relatorio_prognostico.md` | `26cdae76a3fd6ac703747c74552c2106ff62ec599bcca7c190230835cc48ac46` |
| `results/prognostico/reduced_objects/frozen_models_reduced.rds` | `e26abfd849a14daea90d684b25ce5138ace2aa1dbea285c67fe2c0294a680c0c` |
| `results/prognostico/reduced_objects/frozen_bootstrap_internal.rds` | `739b4718e9fdfbd2778e2266b4a029a4979678c1ce151f7127f1b2d287999485` |
| `results/prognostico/reduced_objects/frozen_shrinkage_models.rds` | `e89bac61746210c3bc87ab1f803472f31320df51a08907ccc4882a55f0ec9379` |
| `results/prognostico/reduced_objects/cart_nested_internal.rds` | `498ca47391ca4c5530bbf0c618577458d940c42c0ccffa6dcb7602c4fab0029d` |
| `results/prognostico/reduced_objects/flexible_nested_internal.rds` | `2758040208a178b246d184b54a679b1729b8f0a023d3799d4d88b145d3957a7e` |
| `results/prognostico/aggregated/frozen_bootstrap_optimism_summary.csv` | `ead5ddf9011a6ffab51ede06fd21d111494608688b4476e7ec5e298eff3654e1` |
| `results/prognostico/aggregated/frozen_equations_shrunk.txt` | `66bd0f334ebeb34006d06ad2609409da4b4bced81e6243fb7c0473c47cf89752` |
| `results/prognostico/aggregated/cohort_summary.csv` | `821e226b84bbf7db1b5e48d3b63904721e0bb7ae01e487314553d0008e0a0606` |
| `results/prognostico/aggregated/cart_external_metrics.csv` | `1df8e229d1fb8a1b9028635e2d75ffa092139ba9ace4c8fb4d592fa374c2a8e5` |
| `results/prognostico/aggregated/flexible_external_metrics.csv` | `dfa4cc264395ed23fcd44e8eb7489db081881d9b9f7fb9d7036e4ba344e40eb3` |

As verificações da Tarefa 12 informam 615 participantes, 317 eventos, 298 não eventos, 19 parâmetros preditores, 2.000 réplicas válidas por modelo e ausência de falhas. Esses números são evidência do baseline já verificado; não foram recalculados nesta task.

## Decisões clínicas e especificação preservadas

Foram recuperadas do plano original e mantidas sem reabertura:

- `correcao_colete` é uma avaliação transversal na anamnese inicial, antes do tratamento longitudinal, e pode representar maleabilidade/corrigibilidade imediata; não foi tratada como suspeita de vazamento temporal;
- as três hipercorreções verdadeiras permanecem na coorte principal, sem truncamento, winsorização ou recodificação;
- a coorte vigente é 621 registros brutos, 618 após deduplicação, 615 casos completos, com 317 eventos e 298 não eventos;
- o modelo linear para `delta` é principal; a regressão logística para `delta <= -5°` é secundária; CART e modelagem flexível são exploratórias;
- os modelos principais mantêm dez preditores, 19 parâmetros preditores e intercepto, sem stepwise, seleção por p-valor, treino–teste simples ou reintrodução de progressão;
- Cobb basal e exclusões por influência permanecem sensibilidades identificadas, não alterações da especificação principal.

## Mapa do parecer para as tasks responsáveis

| Recomendação do parecer | Task(s) responsável(is) |
|---|---|
| Temporalidade do colete, maleabilidade, cenário e dicionário | 02, 13, 15 |
| Desfecho, preditores, Cobb basal e escopo sem progressão | 02, 10, 13 |
| Bibliografia, DOI e fontes de checklists | 03, 13, 15 |
| Objetivo incorreto do solver e testes tautológicos | 04 |
| Reexecução flexível, hierarquia e mesmos folds | 05 |
| Cortes primários, escopos, denominadores e calibração CART | 06 |
| Árvore, regras de folhas e estabilidade | 07, 12, 13 |
| Heteroscedasticidade, IC/testes, GVIF e separação | 08, 12, 13 |
| Bootstrap, falhas, IC de desempenho, shrinkage e cobertura | 09 |
| Influência, hipercorreções, Cobb basal e comparadores | 10 |
| Dados faltantes, descrição da coorte e cenários amostrais | 11 |
| Calibração, estabilidade, coeficientes e formas funcionais | 12 |
| Metodologia, mensagens quantitativas e discussão | 13 |
| Renderização, privacidade, evidências, testes e fontes | 14 |
| TRIPOD+AI, PROBAST+AI e prontidão final | 15 |

Assim, todas as recomendações do parecer têm responsável explícito. Nenhuma recomendação foi executada antecipadamente nesta task.

## Comandos, configuração e limites de execução

Os pontos de configuração foram localizados em `R/00_config.R`: a raiz é descoberta pela presença de `data/dataset_escoliose_01.xlsx`; `DATA_FILE` e `DATA_SHEET` definem a fonte; `RESULTS_ROOT` aponta para `results/prognostico`; `RESULTS_DIRS` aponta para `aggregated`, `figures`, `logs` e `reduced_objects`; a semente global é `20260906`, com sementes paralelas `20260907`–`20260910`. O caminho da revisão é adicional e exclusivo, `results/prognostico/revisao/`, não é um substituto silencioso dos diretórios congelados.

Os comandos existentes e seus papéis estão registrados em `01_execucao.md`: setup, importação/auditoria, modelos congelados, bootstrap, CART aninhada, modelagem flexível, sensibilidades, testes e renderização. Os scripts escrevem por caminho explícito em `results/prognostico/`; a integração da revisão deverá apontar explicitamente para `results/prognostico/revisao/` antes de produzir qualquer saída nova.

Não foram executados bootstraps, CV aninhada, renderização Quarto, ajustes de modelos ou instalações. A checagem de ambiente foi somente descritiva e a criação de diretórios não alterou dados ou resultados.

## Critérios de conclusão verificados

| Critério | Evidência |
|---|---|
| Diferenciar histórico, congelado e revisão | Classificação acima e manifesto inicial. |
| Atribuir task a cada recomendação | Mapa do parecer acima, alinhado ao índice. |
| Permitir conferir base e modelos | Hashes SHA-256, commit, datas/tamanhos e manifesto. |
| Não executar alteração analítica ou renderização pesada | Log de execução; somente leitura de arquivos, hash, ambiente e criação de diretórios. |
| Atualizar resumo e manifesto | `01_execucao.md`, `manifesto_inicial.csv` e `ambiente_inicial.txt`. |

## Saídas para consumo das próximas tasks

As próximas tasks devem consumir primeiro este inventário, o manifesto e o ambiente. Devem tratar `results/prognostico/` como baseline congelado e escrever novos artefatos somente em `results/prognostico/revisao/`. As tarefas 02 e 03 podem usar esta rastreabilidade; nenhuma dependência foi afetada e a próxima task não foi disparada automaticamente.

