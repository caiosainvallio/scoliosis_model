# Explicação conformal e esclarecimento da cronologia

Data: 09/09/2026. Complemento solicitado pelo usuário; nenhum status de task alterado.

## Informação nova fornecida pela equipe

À pergunta “A definição dos desfechos e dos dez preditores foi discutida e fixada com pesquisadores e clínicos antes de examinar os resultados desta coorte?”, o usuário respondeu: **“Sim, antes de examinar os resultados”**.

Essa confirmação substitui a interpretação anterior de que a especificação principal teria sido escolhida após exploração dos resultados. O relatório passou a declarar definição a priori com pesquisadores e clínicos, sem referências ao documento de análise passado. A mudança é de informação sobre o desenho, não uma alteração dos modelos ou uma reconstrução estatística da análise.

Foram conciliados TRIPOD 9a, 12c, 18c e 26, o domínio de análise PROBAST e a sinalização de repetição das decisões. O julgamento alto atribuído exclusivamente à seleção posterior foi retirado; o julgamento atual permanece incerto pelas demais limitações. O item C01 do registro de pendências foi encerrado por esclarecimento da cronologia. A disponibilização de um documento de protocolo continua pendente: discussão a priori confirmada não equivale a protocolo público ou registro prospectivo fornecido.

O parecer e os registros anteriores permanecem como evidência da informação disponível na época. Quanto à cronologia da especificação e ao fundamento de C01, **este esclarecimento e os checklists atuais supersedem as conclusões anteriores**. Nada neste esclarecimento demonstra baixo risco global, validade externa ou prontidão para uso clínico.

## Explicação da cobertura conformal

A seção agora apresenta a pergunta, a definição de cobertura nominal/observada, os três conjuntos de ajuste/calibração/teste, a normalização dos erros, a largura variável, a leitura dos resultados e um exemplo inteiramente didático. A tabela exibe percentuais e contagens inteiras. Incluído parágrafo reaproveitável no manuscrito.

O texto foi confrontado com `R/13_review_validation.R`, funções `fit_heteroscedastic_scale`, `conformal_quantile` e `evaluate_conformal_prediction_intervals`, e com os agregados por repetição. A referência já presente de Lei et al. foi novamente consultada em fonte primária: https://www.stat.cmu.edu/~ryantibs/papers/conformal-jasa.pdf . A explicação geral do método não transfere a garantia habitual de cobertura ao desenho estratificado local.

Mantêm-se cobertura interna média de 94,86% e largura total média de 17,44°, sem afirmar faixa fixa de ±8,7°, IC de beta ou intervalo validado da equação final. As cinco repetições reutilizam 615 pessoas; não são 3.075 participantes independentes. Nenhuma reamostragem foi repetida.

## Verificação

Renderização oficial: `rtk quarto render relatorio_prognostico.qmd --to html`, com sucesso, registrada em `results/prognostico/revisao/logs/conformal_cronologia_render.log`. Quarto usou escalonamento já necessário para consultar a arquitetura do sistema, sem instalação de dependências.

Verificados os resultados numéricos agregados, as âncoras internas, as dez imagens incorporadas e a ausência das referências textuais removidas no QMD/HTML e checklists. Evidência em `conformal_cronologia_verificacao.json`; hashes atualizados no manifesto final. `git diff --check` passou. A alteração de texto/tabela não exigiu reexecução do solver ou testes de modelagem. Não houve publicação, commit, push ou mudança de status das tasks.
