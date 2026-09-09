# Relatório autônomo para apoiar a escrita do artigo

Revisão solicitada após a auditoria final. Registro adicional; não modifica o status nem reescreve as evidências históricas da Task 15.

## O que foi necessário e implementado

A autonomia de leitura exigiu reunir, no próprio relatório, a população, os desfechos, a lista completa de preditores, a codificação das 19 colunas, o método de estimação e a finalidade de cada modelo. A procedência histórica da especificação continua explícita como limitação; não é necessário consultar `analisys.qmd` para compreender o estudo. O relatório não pode suprir documentos clínicos ausentes inventando recrutamento, protocolos ou justificativa prospectiva.

Foram incluídas tabelas para artigo com 20 termos por regressão: beta e IC95% HC3-t595 no linear; beta, OR e IC95% Wald normal no logístico. Os contrastes são +1 ano, +1 kg/m², +10° para cifose/lordose, +10 pontos percentuais para colete e categorias versus referências explícitas. Incluem intercepto, sem interpretá-lo como paciente típico. Um apêndice interpreta todos os termos e outro confronta os pesos pós-shrinkage, sem atribuir a estes os IC do ajuste sem shrinkage. Os CSVs mantêm números sem arredondamento para reaproveitamento editorial.

O produtor `scripts/prepare_standalone_report.R` reajusta a regressão logística especificada na fonte, verifica igualdade de beta, erro-padrão e IC com o agregado auditado (<1e-10) e produz as tabelas. Os IC lineares consomem o cálculo HC3 auditado. Não há novos bootstraps, tuning ou seleção. As duas tabelas históricas ainda consumidas pelo QMD (desempenho CART e estabilidade bootstrap) foram copiadas explicitamente para o pacote da revisão com igualdade SHA-256. Assim o QMD lê somente agregados da revisão. A reprodução continua necessitando dados e código, como qualquer relatório computacional; autonomia de leitura não significa dispensar insumos para recalcular modelos.

Foi acrescentado vocabulário e explicação de shrinkage: sobreajuste, fator uniforme, redução da magnitude, recalibração do intercepto e diferença para penalização durante o ajuste flexível. Foram explicados os limites de beta, OR, IC, AUC, RMSE, Brier, log loss, calibração e conformal. A referência já existente de Riley 2020 foi novamente conferida no BMJ para fundamentar shrinkage; as referências existentes de elastic net/coordinate descent fundamentam a descrição da penalização. Não houve nova decisão estatística.

Cada uma das dez figuras remanescentes recebe uma pergunta, instruções de leitura e interpretação/limites. Removidas do corpo a figura redundante de OR pós-shrinkage (inclusive seu contraste de +10 anos) e a frequência de componentes flexíveis, pouco informativa sob ridge. Os arquivos originais dessas figuras foram preservados. O gráfico de estabilidade das cinco previsões flexíveis foi transferido da seção logística principal para a seção flexível, evitando confusão entre modelos e entre bootstrap e CV.

As sensibilidades passaram a explicar a pergunta, mudança, população de teste e resultado de cada cenário. A equivalência entre delta ajustado por Cobb basal e Cobb final foi explicada algebricamente, com acoplamento matemático/regressão à média. O flexível saiu dos apêndices para uma seção própria: exemplo de reta versus curva, splines/nós, três famílias de interação, 48 colunas, grade de 20 configurações, lambda/alpha, regra one-SE e CV aninhada. O ganho é modesto e não isola a contribuição de splines, Cobb basal, interações ou penalização.

## Verificações e evidências

- `rtk Rscript --vanilla scripts/prepare_standalone_report.R`: duas tabelas e duas cópias auditadas; `standalone_tables.log` e `standalone_inputs_manifest.csv`.
- Execução limpa dos chunks via `knitr::purl`/`source`: `standalone_chunks.log`, sem falha. Alterações seguintes foram editoriais/CSS/checklist.
- `rtk quarto render relatorio_prognostico.qmd --to html`: `standalone_render.log`, renderização concluída. Escalonamento para detecção de arquitetura do Quarto, sem instalar dependências.
- Conferência numérica dos 40 termos contra HC3/logístico auditados: beta, EP, IC, multiplicadores e exponenciação da OR conciliados; `standalone_verification.json`.
- HTML: 67 links internos com destinos válidos, dez figuras incorporadas com texto alternativo e explicação, 20 referências citadas, zero citações não resolvidas.
- Inspeção no navegador de tabela logística e seção flexível, em desktop 1280 e celular 390: corrigidas rolagem local de tabelas e quebra de caminhos longos. Resultado final em `standalone_verification.json`; capturas inspecionadas na ferramenta, não arquivadas.
- Servidor temporário somente em 127.0.0.1, contendo cópia do HTML agregado; encerrado após verificação. Sem dados individuais disponibilizados.
- `git diff --check` e manifesto SHA-256 final atualizados. Modelos, dados, resultados analíticos auditados e status de tasks preservados. Nenhum commit, push ou publicação.

Os arquivos `standalone_*` ficam em `results/prognostico/revisao/logs/`. As tabelas ficam em `results/prognostico/revisao/aggregated/article_coefficients_linear.csv` e `article_coefficients_logistic.csv`. O checklist TRIPOD foi conciliado quanto à nova localização/detalhamento, mantendo pendências reais. O parecer da Task 15 corresponde à versão auditada naquele momento; esta extensão editorial tem as verificações específicas acima e não é uma nova auditoria científica externa.

## Limites preservados

Não há IC pós-shrinkage, demonstração de superioridade do flexível, correção de toda a exploração histórica ou validação externa. Documentação clínica/ética e adaptação à revista ainda dependem dos pesquisadores. Tabelas e interpretações apoiam a redação; não convertem associações em efeitos de tratamento nem demonstram importância por significância isolada.
