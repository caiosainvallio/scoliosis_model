# Execução da Tarefa 11 — coorte e tamanho amostral

Data: 2026-09-08. Diretório: `/Users/caiosainvallio/consultoria/scoliosis_model`.

## Execução e verificações

| Comando/ação | Resultado |
|---|---|
| Leitura do índice, Task 11 e entregas 01–03 | Dependências concluídas; definição transversal basal de `correcao_colete`, coorte e fontes metodológicas preservadas. |
| `rtk Rscript --vanilla scripts/run_review_cohort_description.R` | Releu a planilha somente para leitura, recalculou as derivações e produziu três CSVs públicos agregados e dois registros internos agregados. |
| Verificação R independente dos CSVs | Aprovou 29 linhas descritivas, presença de preditores/desfechos, 10 cenários principais, três cenários insuficientes, fluxo 621→618→615, três incompletos e ausência de coluna de IDs. |
| SHA-256 da fonte | Confere o hash do inventário: `f601adb42c299c2b0572f3e50ff26550b63a2f24dd7173f244a442b498965b71`. |
| Inspeção de conteúdo | Eventos/não eventos 317/298, dez empates basais, 19 parâmetros preditores, intercepto e shrinkage 0,90 conciliados com as saídas congeladas. |

## Arquivos produzidos

- `scripts/run_review_cohort_description.R`;
- `results/prognostico/revisao/aggregated/cohort_descriptive.csv`;
- `results/prognostico/revisao/aggregated/missing_before_after.csv`;
- `results/prognostico/revisao/aggregated/sample_size_display.csv`;
- `results/prognostico/revisao/logs/cohort_task11.log`;
- `results/prognostico/revisao/logs/cohort_included_excluded_aggregate.csv` (agregado interno);
- `11_coorte_amostra.md` e este arquivo.

## Critérios de conclusão

| Critério | Evidência |
|---|---|
| Tabelas e denominadores | `cohort_descriptive.csv` cobre dez preditores, `delta`, `delta_cat` e magnitudes; os denominadores conciliam n=615. |
| Exclusões visíveis | `missing_before_after.csv` conserva 618 pré-caso-completo, três ausentes de Lenke e o fluxo completo. |
| Amostra condicional | `sample_size_display.csv` separa cenários, identifica três insuficientes e registra fontes aparentes/otimistas. |
| Privacidade | Saídas públicas são agregadas; a verificação independente confirmou ausência de coluna ID. |
| Resumo e manifesto | Esta execução, a síntese e as entradas de manifesto desta task registram comandos, hashes, consumo e limitações. |

## Limitações e passagem

Não foram usados testes de hipótese para o grupo excluído de três participantes; não foi feita imputação. R² e Cox–Snell aparentes são retrospectivos/otimistas, e tamanho amostral não substitui validação, calibração ou validação externa. A modelagem flexível continua fora do escopo do cálculo. As Tasks 12, 13 e 15 devem usar as saídas da revisão; nenhuma dependência foi alterada e nenhuma task seguinte foi executada.
