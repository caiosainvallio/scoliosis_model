# Mapa de citações da revisão prognóstica — Tarefa 03

Consulta bibliográfica dirigida em 2026-09-07. As fontes abaixo sustentam o método ou contextualizam uma afirmação; não validam por si a fórmula local, a utilidade clínica, o desempenho ou a transportabilidade do modelo.

| Seção/afirmação a integrar na Task 13 | Chave BibTeX | Fonte primária/oficial | Uso adequado e limite |
|---|---|---|---|
| Relato transparente do estudo de predição, cronologia dos preditores e itens pendentes | `collins2024_tripod_ai` | [BMJ / TRIPOD+AI](https://www.bmj.com/content/385/bmj-2023-078378) | Diretriz de relato; não justifica algoritmo, amostra ou resultado clínico. |
| Estrutura de futura avaliação crítica de qualidade, viés, desempenho e aplicabilidade | `moons2025_probast_ai` | [BMJ / PROBAST+AI](https://www.bmj.com/content/388/bmj-2024-082505) | Ferramenta de avaliação; não atribuir julgamento antes de preencher perguntas e evidências. |
| Tamanho amostral do modelo linear com `delta` contínuo | `riley2019_continuous_sample_size`, `riley2020_sample_size_framework` | [Stat Med DOI](https://doi.org/10.1002/sim.7993); [BMJ](https://www.bmj.com/content/368/bmj.m441) | Depende de parâmetros candidatos e desempenho antecipado; não converte n local em garantia de estabilidade. |
| Tamanho amostral do modelo logístico de melhora radiográfica | `riley2019_binary_sample_size`, `riley2020_sample_size_framework` | [Stat Med DOI](https://doi.org/10.1002/sim.7992); [BMJ](https://www.bmj.com/content/368/bmj.m441) | Requer proporção de evento e desempenho antecipado; não usar apenas eventos por parâmetro. |
| Otimismo, validação interna e shrinkage | `steyerberg2001_bootstrap` | [J Clin Epidemiol DOI](https://doi.org/10.1016/S0895-4356(01)00341-9) | Sustenta reamostragem interna; não equivale a validação externa. |
| Discriminação não substitui calibração; curvas e medidas de calibração | `vancalster2019_calibration` | [BMC Medicine](https://link.springer.com/article/10.1186/s12916-019-1466-7) | Apoia avaliar e mostrar calibração; não cria limiar de decisão clínica. |
| Tuning e desempenho de CART/flexível estimados em camadas separadas | `cawley2010_nested_cv` | [JMLR](https://jmlr.org/papers/v11/cawley10a.html) | Previne viés de seleção na avaliação; não torna análises exploratórias modelos principais. |
| Otimização de GLM penalizado e comparação externa do solver | `friedman2010_glmnet` | [Journal of Statistical Software](https://www.jstatsoft.org/article/view/v033i01) | Fonte algorítmica para lasso/ridge/elastic net; a Task 04 ainda deve testar a função objetivo implementada. |
| Motivação e propriedade de agrupamento do elastic net | `zou2005_elastic_net` | [JRSS B DOI](https://doi.org/10.1111/j.1467-9868.2005.00503.x) | Fundamenta a penalização, não uma inferência causal de bases spline ou termos selecionados. |
| Erros-padrão robustos após heteroscedasticidade | `white1980_robust_covariance` | [Econometrica DOI](https://doi.org/10.2307/1912934) | Fundamenta matriz de covariância robusta; não corrige especificação, viés ou previsão individual. |
| CART e regras de folhas como análise exploratória | `breiman1984_cart` | [Registro editorial](https://www.routledge.com/Classification-and-Regression-Trees/Breiman-Friedman-Olshen-Stone/p/book/9780412048418) | Referência metodológica do algoritmo; estabilidade, tuning e avaliação continuam a exigir a análise local. |
| Flexibilidade/corrigibilidade radiográfica imediata e correção no colete em AIS | `ohrt_nissen2016_brace_flexibility` | [PubMed PMID 26909835](https://pubmed.ncbi.nlm.nih.gov/26909835/) | Estudo transversal de Providence brace; contextualiza o componente flexível/redutível, não a fórmula, colete, horizonte ou manutenção local. |
| Variabilidade de Cobb, tratamento conservador e medidas clínicas em AIS | `negrini2018_sosort` | [Scoliosis and Spinal Disorders](https://link.springer.com/article/10.1186/s13013-017-0145-8) | Diretriz de contexto; não demonstra que redução de 5° seja benefício clínico nem define o protocolo local. |

## Correção bibliográfica e instrução Quarto

- O DOI correto da referência de Riley para desfecho contínuo é `10.1002/sim.7993` (`riley2019_continuous_sample_size`). O valor `10.1002/sim.7991` que permanece na lista manual do QMD é incorreto e deve ser removido pela Task 13.
- O DOI da referência para desfecho binário é `10.1002/sim.7992` (`riley2019_binary_sample_size`) e foi mantido após conferência.
- A Task 13 deve adicionar ao YAML `bibliography: references_prognostico.bib`, substituir a lista manual por citações do tipo `[@riley2019_continuous_sample_size]` e citar a fonte junto da escolha metodológica. Esta task não altera `relatorio_prognostico.qmd`.

## Cobertura e pendências

As decisões metodológicas listadas na Task 03 têm ao menos uma fonte adequada no mapa. Fontes clínicas adicionais da matriz da Task 02 (por exemplo, associação longitudinal de correção inicial e desfecho de colete) podem ser acrescentadas pela Task 13 ao redigir uma afirmação específica. Nenhuma fonte externa autoriza declarar que `correcao_colete` não seja basal: a temporalidade local continua fundada nos documentos do projeto e no esclarecimento já confirmado.
