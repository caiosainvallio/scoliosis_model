# Explicação do tamanho amostral

Em 11/09/2026, foi criada a seção específica “Avaliação do tamanho amostral”, dentro de Métodos e acessível pelo sumário. A seção distingue avaliação da amostra disponível de dimensionamento prospectivo do recrutamento, sem modificar a definição a priori dos desfechos/preditores confirmada pelo usuário.

Foram explicitados objetivo, 19 parâmetros, entradas contínuas/binárias, pmsampsize 1.1.3, shrinkage desejado versus estimado, critérios, significado de R² e Cox–Snell, cenários e conclusão condicional. A tabela exibe contagens inteiras e “Atende ao cenário?”, em lugar de uma indicação genérica de suficiência. Incluído texto para o manuscrito; TRIPOD item 10 conciliado.

Fontes: scripts `run_sample_size_assessment.R` e `run_review_cohort_description.R`, agregados auditados, saídas detalhadas do pmsampsize, artigo de Riley 2020 no BMJ e código-fonte do pacote. A avaliação usa características e desempenho da própria coorte; não se descreve como cálculo prospectivo de recrutamento. O R² ajustado usado como referência não é desempenho externo.

Os dez cenários foram recalculados com a instalação local em `r_libs`, sem instalar pacotes, e reproduziram todos os n mínimos e margens: evidência em `results/prognostico/revisao/logs/tamanho_amostral_explicacao_verificacao.log`. Não foram reexecutados modelos pesados ou reamostragens. O cálculo contínuo usa média negativa de delta; por isso o texto não atribui à rotina uma garantia universal de margem relativa de 10% para a média. A precisão do nível médio é descrita como IC apresentado pelo programa; o critério de dispersão residual é separado.

Renderização: `rtk quarto render relatorio_prognostico.qmd --to html`, registrada em `tamanho_amostral_explicacao_render.log`. Escalonamento para a detecção de arquitetura do Quarto, sem instalação. HTML, âncoras, imagens incorporadas e valores da seção verificados; manifesto final atualizado. Nenhum dado, modelo, resultado amostral original ou status de task alterado. Sem commit, push ou publicação.
