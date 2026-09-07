# Manifesto final de evidências — Tarefa 12

Data da verificação: 2026-09-07. Ambiente: R 4.6.1 (2026-06-24), Quarto 1.6.40, macOS arm64. Semente global: `20260906`; sementes paralelas documentadas: `20260907`, `20260908`, `20260909`, `20260910`.

## Artefatos e hashes SHA-256

| Artefato | SHA-256 |
|---|---|
| `data/dataset_escoliose_01.xlsx` | `f601adb42c299c2b0572f3e50ff26550b63a2f24dd7173f244a442b498965b71` |
| `relatorio_prognostico.qmd` | `24c9f1e33020fc6fda630156f0933096155b3700b462bc726410f9af89e4d86c` |
| `relatorio_prognostico.html` | `93bc76bfa46c80d00f62532cabcee362e15fc6b6599a9fc62f3eb7d629222f2d` |
| `frozen_bootstrap_optimism_summary.csv` | `ead5ddf9011a6ffab51ede06fd21d111494608688b4476e7ec5e298eff3654e1` |
| `frozen_equations_shrunk.txt` | `66bd0f334ebeb34006d06ad2609409da4b4bced81e6243fb7c0473c47cf89752` |
| `frozen_models_reduced.rds` | `e26abfd849a14daea90d684b25ce5138ace2aa1dbea285c67fe2c0294a680c0c` |
| `frozen_shrinkage_models.rds` | `e89bac61746210c3bc87ab1f803472f31320df51a08907ccc4882a55f0ec9379` |
| `frozen_bootstrap_internal.rds` | `739b4718e9fdfbd2778e2266b4a029a4979678c1ce151f7127f1b2d287999485` |

## Evidências quantitativas

- Coorte final: 615 participantes; 317 eventos e 298 não eventos.
- Modelos congelados: 19 parâmetros preditores, matriz 20 colunas com intercepto, posto 20 e mesmas 615 observações nos dois modelos.
- Bootstrap: 2.000 tentativas por modelo; 2.000 válidas em cada modelo; 0 falhas; critério mínimo de 1.980 atendido.
- Validação aninhada: folds externos e internos auditados; testes externos disjuntos dos treinos; previsões externas somente no fold de teste; sem vazamento.
- Predições: três perfis sintéticos reproduzidos pela equação publicada e pela função de predição, dentro de `1e-12`.
- HTML: 49 etapas concluídas; autocontido; 27 títulos, 19 tabelas e 8 figuras; texto visível sem ocorrência analítica de progressão, `model.frame` ou instalação.

## Escopo e limitações

Os artefatos são para revisão da equipe, sem publicação automática, commit ou push. O estudo é desenvolvimento e avaliação interna em fonte única, por caso completo, com possível erro de mensuração e necessidade de validação externa. Não há indicação terapêutica nem limiar de decisão clínica. O `.RData` preexistente não foi removido, carregado ou salvo; o relatório não depende dele.

## Integridade Git

O estado inicial estava limpo. Ao final, as únicas alterações são o HTML final e saídas/logs regenerados pela verificação e pelo relatório. `analisys.qmd`, `analisys.html` e `data/dataset_escoliose_01.xlsx` permaneceram sem diferenças.
