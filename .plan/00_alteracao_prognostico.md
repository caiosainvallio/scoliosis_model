# Plano completo — desenvolvimento e avaliação interna dos modelos prognósticos

## 1. Finalidade e estado do plano

Este documento especifica a nova etapa do projeto de escoliose: transformar a análise exploratória atual em um **estudo de desenvolvimento e avaliação interna de modelos prognósticos**, com um relatório estatístico próprio e reprodutível.

O relatório será destinado a subsidiar a redação do manuscrito pela pesquisadora principal. Ele deverá conter métodos, resultados, interpretação clínica, limitações, equações completas e blocos explicitamente identificados como **“Sugestão para o manuscrito”**.

O uso pretendido das previsões nesta etapa é **prognóstico e de aconselhamento clínico**. Os modelos não serão apresentados como instrumentos capazes de indicar, interromper ou alterar tratamento. Qualquer uso decisório dependerá de validação externa, definição de limiares clínicos e avaliação de utilidade clínica em estudos futuros.

## 2. Decisões aprovadas pela equipe

1. O trabalho seguirá a linha de **desenvolvimento e avaliação interna de modelos prognósticos**.
2. O modelo principal será uma regressão linear para estimar a magnitude da mudança da maior curva de Cobb em seis meses.
3. O modelo secundário será uma regressão logística para estimar a probabilidade de melhora radiográfica de pelo menos 5°.
4. A CART de melhora será mantida somente como análise exploratória e geradora de hipóteses.
5. As análises de progressão serão removidas integralmente do novo relatório.
6. O modelo principal e o secundário manterão a especificação atual congelada, com dez preditores e 19 parâmetros preditores.
7. Uma estratégia mais flexível será avaliada separadamente em apêndice exploratório, sem substituir os modelos congelados.
8. Não haverá divisão treino-teste. Toda a amostra analítica será usada no desenvolvimento dos modelos principais, com avaliação interna por bootstrap.
9. A base final desta versão é `data/dataset_escoliose_01.xlsx`, aba `dados`.
10. A planilha original não será modificada. Exclusões, derivações e verificações serão executadas e documentadas no código.
11. O relatório exploratório atual, `analisys.qmd` e `analisys.html`, será preservado como registro histórico. A nova análise será produzida em relatório separado.

## 3. Definição clínica da previsão

### 3.1 População e horizonte

- População: adolescentes com escoliose idiopática incluídos na base final, sem análise de subgrupos como parte do objetivo principal.
- Tratamento: manejo conservador com colete e exercícios específicos para escoliose pelo método S4D.
- Momento da previsão: avaliação transversal realizada antes do início do tratamento longitudinal.
- Horizonte prognóstico: seis meses.
- Condição radiográfica: medidas basais e de seis meses obtidas sob a mesma condição radiográfica definida no protocolo clínico.

### 3.2 Correção com o colete

`correcao_colete` é obtida antes do tratamento longitudinal, comparando a radiografia sem colete com a radiografia usando o colete. A variável representa a maleabilidade/corretibilidade imediata da curvatura e estará disponível no momento de aplicação do modelo.

Os valores superiores a 100% foram confirmados pela equipe como hipercorreções verdadeiras e clinicamente possíveis. Os IDs 81, 174 e 401 serão mantidos com seus valores originais, sem truncamento, winsorização ou recodificação. A distribuição e a influência desses casos serão descritas e avaliadas em análise de sensibilidade, mas eles não serão excluídos automaticamente.

### 3.3 Desfechos

- **Desfecho contínuo principal:** `delta = maior_curva_6_meses - cobb_inicial_maior`.
- `cobb_inicial_maior` será o máximo entre Cobb torácico proximal, Cobb torácico e Cobb lombar no basal.
- Valores negativos de `delta` indicam redução da curvatura; valores positivos indicam aumento.
- O desfecho será mantido mesmo quando a curva máxima pertencer a regiões anatômicas diferentes nos dois momentos, conforme decisão clínica da equipe.
- **Desfecho binário secundário:** `delta_cat = 1` quando `delta <= -5°` e `0` nos demais casos.
- A análise de progressão (`delta >= +5°`) não fará parte do novo relatório.

## 4. Construção e auditoria da coorte

### 4.1 Deduplicação confirmada

A base bruta possui 621 linhas e IDs distintos, mas contém três pares de registros clinicamente idênticos. A equipe confirmou que são duplicações.

Manter a primeira ocorrência e excluir a segunda de cada par:

| Par duplicado | ID mantido | ID excluído |
|---|---:|---:|
| 17 / 46 | 17 | 46 |
| 21 / 162 | 21 | 162 |
| 16 / 248 | 16 | 248 |

A exclusão deverá ser feita por lista explícita de IDs (`46`, `162`, `248`) e precedida por uma asserção que confirme que cada par continua idêntico nas variáveis clínicas e no desfecho. Não usar `distinct()` de forma genérica, pois isso poderia excluir futuramente participantes diferentes com valores coincidentes.

### 4.2 Casos incompletos

Após deduplicação haverá 618 participantes. Os IDs 390, 535 e 628 apresentam `Lenke` ausente e serão excluídos da análise por casos completos.

Coorte analítica esperada:

- 621 registros brutos;
- 3 duplicatas excluídas;
- 618 participantes após deduplicação;
- 3 participantes excluídos por `Lenke` ausente;
- **615 participantes nos modelos principal e secundário**;
- **317 eventos de melhora e 298 não eventos** no desfecho logístico.

### 4.3 Trilha de auditoria obrigatória

O relatório deverá gerar programaticamente:

- tabela com cada etapa, número excluído, motivo e número restante;
- lista dos IDs excluídos e respectivo motivo;
- confirmação de unicidade dos IDs após deduplicação;
- comparação das observações incluídas nos modelos linear e logístico;
- contagem de eventos e não eventos;
- relatório de dados ausentes antes e depois das exclusões;
- confirmação de que os três valores de hipercorreção foram preservados;
- hash ou data de modificação da planilha utilizada, para identificar a versão da base.

Nenhum dado bruto será sobrescrito. Artefatos compartilháveis não deverão conter dados individuais ou objetos de modelo com `model.frame` incorporado.

## 5. Evidências produzidas pelo diagnóstico anterior

Os arquivos em `diagnostico_modelos/`, `parecer-estatistico.md` e `avaliacao_tamanho_amostral.txt` documentam a avaliação executada em 21/07/2026. Eles sustentam a viabilidade preliminar da proposta, mas foram gerados antes da deduplicação e **não poderão fornecer os números finais do novo relatório**.

Resultados preliminares a confirmar após a limpeza:

- matrizes linear e logística com posto completo;
- 19 parâmetros preditores em cada modelo;
- ausência de separação logística e de coeficientes não estimáveis;
- nenhuma combinação categórica problemática entre os casos analisados;
- colinearidade baixa a moderada;
- modelo linear aparente: R² 0,400, R² ajustado 0,381, RMSE 4,15° e MAE 3,30°;
- modelo logístico aparente: AUC 0,867, Brier 0,148 e log loss 0,457;
- 41 observações sinalizadas pelo critério sensível de Cook no linear, embora o máximo tenha sido 0,020;
- 50 observações sinalizadas no logístico, com Cook máximo de 0,015;
- dois resíduos padronizados extremos no modelo linear, máximo absoluto de 4,44;
- sinais de possível não linearidade, principalmente em idade, IMC e correção com colete;
- correlação praticamente nula entre Cobb basal e `delta`, mas forte correlação entre Cobb basal e Cobb aos seis meses;
- a calibração aparente 0/1 é esperada por construção e não constitui avaliação interna válida;
- a CART atual reutiliza os mesmos folds para tuning e avaliação, produzindo estimativa otimista.

Todos esses diagnósticos serão refeitos com os 615 participantes finais. O relatório deverá distinguir claramente “resultado preliminar anterior” de “resultado final recalculado”; preferencialmente, somente os valores recalculados aparecerão no HTML final.

## 6. Objetivos do relatório

### 6.1 Objetivo principal

Desenvolver e avaliar internamente, por reamostragem bootstrap, um modelo prognóstico multivariável para estimar a magnitude da mudança da maior curva de Cobb após seis meses de tratamento conservador com colete e exercícios específicos para escoliose pelo método S4D, em adolescentes com escoliose idiopática.

### 6.2 Objetivos secundários

1. Desenvolver e avaliar internamente um modelo de regressão logística para estimar a probabilidade individual de melhora radiográfica clinicamente relevante, definida como redução de pelo menos 5° na maior curva de Cobb após seis meses.
2. Explorar, por CART, combinações de características clínicas e radiográficas associadas a diferentes perfis de melhora.
3. Explorar se não linearidades, interações clínicas pré-especificadas, penalização e inclusão do Cobb basal melhoram o desempenho preditivo, sem alterar a hierarquia confirmatória do estudo.

## 7. Preparação reprodutível dos dados

1. Ler sempre `data/dataset_escoliose_01.xlsx`, aba `dados`.
2. Limpar nomes com `janitor::clean_names()`.
3. Validar tipos, unidades, faixas e níveis categóricos antes de derivar variáveis.
4. Confirmar os três pares duplicados e excluir somente os IDs previamente definidos.
5. Calcular o IMC por `peso / altura^2`, com peso em kg e altura em metros.
6. Calcular `cobb_inicial_maior` com o máximo das três regiões disponíveis.
7. Registrar empates entre regiões basais; o empate não modifica o valor máximo usado no desfecho.
8. Calcular `delta` e `delta_cat` a partir das medidas brutas, sem confiar em objetos existentes em `.RData`.
9. Recriar `escoliometro_maior_10_graus` com a regra vigente e verificar seus níveis observados.
10. Converter fatores e definir referências antes da modelagem.
11. Criar uma única base de casos completos contendo desfechos e todos os preditores dos modelos congelados.
12. Confirmar programaticamente que os modelos linear e logístico usam as mesmas 615 linhas.

Referências categóricas planejadas:

- sexo: feminino;
- Lenke: 1;
- Risser: 0;
- flexibilidade: flexível;
- escoliômetro >10°: normal.

## 8. Avaliação atualizada do tamanho amostral

Refazer a análise com `pmsampsize` após deduplicação e ajuste dos modelos. Não reutilizar mecanicamente o total de 618 ou as métricas aparentes anteriores.

### 8.1 Modelo contínuo

- usar 19 parâmetros preditores;
- usar média e desvio-padrão de `delta` recalculados;
- apresentar o cenário baseado no R² ajustado atualizado somente como referência;
- repetir os cenários conservadores de R² esperado 0,35, 0,30, 0,25 e 0,20;
- comparar cada necessidade estimada com os 615 participantes disponíveis;
- não selecionar retrospectivamente o cenário que torne a amostra suficiente.

### 8.2 Modelo binário

- usar 19 parâmetros, 317 eventos, 298 não eventos e prevalência recalculada;
- recalcular Cox–Snell R² e seu máximo;
- apresentar cenários com 100%, 80%, 70%, 60% e 50% do Cox–Snell aparente;
- manter cenários baseados em AUC somente como sensibilidade;
- interpretar eventos por parâmetro apenas como descrição, não como justificativa única.

A conclusão de suficiência ficará restrita à especificação congelada. A estratégia exploratória flexível não será justificada pelo mesmo cálculo como se tivesse somente 19 parâmetros.

## 9. Modelos prognósticos congelados

### 9.1 Preditores comuns

Os modelos linear e logístico usarão exatamente:

1. idade;
2. IMC;
3. cifose torácica;
4. lordose lombar;
5. correção com o colete;
6. sexo;
7. Lenke;
8. Risser;
9. flexibilidade;
10. região do escoliômetro acima de 10°.

Com as codificações atuais, a matriz terá 19 colunas preditoras, sem contar o intercepto. Não haverá stepwise, triagem univariada, remoção por p-valor, alteração de referência após observar resultados, splines ou interações nos modelos principais.

As variáveis contínuas permanecerão lineares na especificação congelada. Para interpretação, os coeficientes poderão ser reexpressos em unidades clínicas úteis — por exemplo, correção com colete por 10 pontos percentuais — sem modificar a parametrização ou o ajuste.

### 9.2 Modelo linear principal

Fórmula:

```r
delta ~ idade + imc + cifose_toracica + lordose_lombar +
  correcao_colete + sexo + lenke + risser + flexibilidade +
  escoliometro_maior_10_graus
```

Apresentar:

- intercepto e todos os coeficientes, com IC95%;
- unidades e níveis de referência;
- equação completa e instruções para calcular uma previsão individual;
- R², R² ajustado, RMSE, MAE e erro médio;
- gráfico observado versus previsto com linha identidade e curva suave;
- intercepto e inclinação de calibração;
- distribuição dos resíduos e diagnóstico de heteroscedasticidade;
- resíduos padronizados, leverage e distância de Cook;
- intervalos de predição de 95%, diferenciados de intervalos de confiança da média;
- interpretação do RMSE, MAE e intervalo de predição em relação ao limiar clínico de 5°.

Normalidade dos resíduos, heteroscedasticidade e influência serão tratadas como diagnósticos da incerteza e adequação, não como testes automáticos para remover participantes. O teste de Durbin–Watson não será apresentado como diagnóstico central em uma coorte transversal sem ordenação temporal das observações.

### 9.3 Modelo logístico secundário

Fórmula:

```r
delta_cat ~ idade + imc + cifose_toracica + lordose_lombar +
  correcao_colete + sexo + lenke + risser + flexibilidade +
  escoliometro_maior_10_graus
```

Apresentar:

- intercepto e coeficientes na escala logit;
- odds ratios com IC95% somente como complemento interpretativo;
- equação completa da probabilidade individual;
- AUC com IC95%, Brier score e log loss;
- calibration-in-the-large, inclinação e curva suave de calibração;
- distribuição das probabilidades previstas;
- curva ROC como descrição da discriminação;
- influência, leverage, resíduos e diagnóstico de separação.

Não usar o teste de Hosmer–Lemeshow como evidência principal. Não enfatizar acurácia, sensibilidade, especificidade, matriz de confusão ou um ponto de corte de probabilidade, pois não existe limiar decisório clínico pré-especificado.

## 10. Avaliação interna por bootstrap

### 10.1 Configuração comum

- usar 2.000 amostras bootstrap de participantes, com reposição e tamanho igual a 615;
- usar semente fixa registrada no relatório;
- reajustar o modelo completo em cada amostra;
- medir o desempenho na própria amostra bootstrap e na base original;
- calcular o otimismo por métrica respeitando sua direção;
- métricas em que valores maiores são melhores: corrigir subtraindo o otimismo médio;
- métricas de erro em que valores menores são melhores: corrigir adicionando a diferença média entre teste e treinamento;
- registrar convergência, estimativas não finitas, separação, níveis ausentes e falhas das métricas;
- exigir no mínimo 99% das 2.000 reamostragens válidas;
- se o limite não for atingido, investigar a causa e revisar a estratégia inteira; não aplicar um estimador alternativo somente às réplicas que falharam.

### 10.2 Métricas corrigidas

Modelo linear:

- R²;
- RMSE;
- MAE;
- erro médio;
- intercepto de calibração;
- inclinação de calibração.

Modelo logístico:

- AUC;
- Brier score;
- log loss;
- calibration-in-the-large;
- inclinação de calibração.

Apresentar para cada métrica o valor aparente, o otimismo médio e o valor corrigido. Intervalos empíricos ou distribuições do bootstrap deverão ser rotulados corretamente como medidas de estabilidade quando não constituírem intervalos de confiança formais para a estimativa corrigida.

### 10.3 Estabilidade das previsões

Além das médias de desempenho:

- guardar, para cada participante, a distribuição das previsões produzidas pelos modelos bootstrap quando aplicados à base original;
- apresentar gráfico de previsão do modelo original versus distribuição das previsões bootstrap;
- calcular índice de instabilidade como diferença absoluta média entre previsão original e previsões bootstrap;
- identificar regiões do espaço de previsão com maior instabilidade;
- evitar divulgar IDs ou dados individuais no HTML público.

### 10.4 Shrinkage e equações finais

Usar a inclinação de calibração corrigida por otimismo como fator de shrinkage uniforme, limitado ao intervalo de 0 a 1. Não expandir coeficientes se a inclinação estimada for superior a 1.

- multiplicar os coeficientes não intercepto pelo fator de shrinkage;
- no linear, recalcular o intercepto para preservar a média observada do desfecho;
- no logístico, recalcular o intercepto para preservar a prevalência observada;
- apresentar os coeficientes originais e os coeficientes após shrinkage;
- designar a equação com shrinkage como a versão prognóstica final quando o fator for inferior a 1;
- relatar explicitamente que o shrinkage não substitui validação externa.

## 11. Análises de sensibilidade dos modelos congelados

1. Reajustar os modelos após retirar, apenas temporariamente, os casos de maior influência identificados por critérios previamente definidos; comparar coeficientes e previsões, sem usar essa análise para excluir casos do modelo final.
2. Comparar resultados com e sem os três casos de hipercorreção, mantendo-os obrigatoriamente na análise principal.
3. Comparar erro e calibração entre faixas da previsão, sexo e principais categorias somente de forma descritiva, sem reivindicar validação de subgrupos.
4. Manter o modelo de Cobb aos seis meses ajustado pelo Cobb basal apenas como análise de sensibilidade do alvo, sem promovê-lo a modelo principal com base em R² aparente.
5. Discutir regressão à média, erro de mensuração e o fato de a região da curva máxima poder mudar entre os momentos.

## 12. CART exploratória com avaliação corrigida

### 12.1 Escopo

- usar somente o desfecho de melhora;
- usar os mesmos dez preditores dos modelos congelados;
- não apresentar a CART como concorrente clínica das regressões;
- não usar o resultado para alterar os modelos principal e secundário.

### 12.2 Reamostragem aninhada

Substituir a reutilização atual dos folds por validação cruzada aninhada:

- camada externa: validação cruzada estratificada de 10 folds, repetida 5 vezes;
- camada interna: validação cruzada estratificada de 5 folds em cada conjunto de treinamento externo;
- executar dentro da camada interna todo o pré-processamento e tuning;
- avaliar somente nas partições externas nunca usadas na seleção;
- selecionar a configuração pela AUC interna usando a regra de um erro-padrão para favorecer a árvore mais simples;
- manter grade pré-especificada de `cost_complexity`, `tree_depth` e `min_n`, revisando os limites apenas antes da primeira execução final;
- produzir previsões fora da amostra para AUC, Brier e log loss;
- gerar calibração exploratória a partir das previsões externas agregadas.

### 12.3 Estabilidade e apresentação

Relatar:

- distribuição do desempenho externo;
- frequência das variáveis na raiz e nos primeiros níveis;
- distribuição dos pontos de corte;
- frequência de árvores sem divisão;
- tamanho dos nós terminais;
- estabilidade das previsões individuais;
- árvore ajustada em toda a base apenas para visualização das regras, deixando claro que seu desempenho vem da camada externa.

## 13. Apêndice exploratório de modelagem flexível

### 13.1 Finalidade

Avaliar se uma estratégia mais flexível sugere ganho preditivo ou padrões clínicos relevantes para futuras discussões com revisores. Esta análise será rotulada como exploratória, não mudará o objetivo principal e não fornecerá a equação clínica preferencial nesta versão.

### 13.2 Conjunto candidato

Incluir:

- os dez preditores dos modelos congelados;
- `cobb_inicial_maior` como preditor adicional pré-tratamento;
- termos não lineares para idade, IMC, cifose torácica, lordose lombar, correção com colete e Cobb basal;
- três interações clínicas pré-especificadas:
  - correção com colete × flexibilidade;
  - correção com colete × Lenke;
  - idade × Risser.

Usar splines cúbicos restritos/naturais com baixa complexidade. Os nós e parâmetros de centralização deverão ser aprendidos somente no conjunto de treinamento de cada reamostragem. As interações usarão os componentes lineares para evitar expansão excessiva do espaço candidato.

### 13.3 Penalização e hierarquia

- usar elastic net para as versões contínua e logística;
- avaliar uma grade fixa de `alpha` entre ridge e lasso e uma sequência logarítmica de `lambda`;
- manter os efeitos principais necessários à hierarquia quando uma interação estiver presente;
- permitir que a penalização reduza ou elimine componentes adicionais não lineares e interações;
- padronizar preditores dentro de cada conjunto de treinamento;
- tratar dummies de uma mesma variável categórica de maneira coerente na interpretação, evitando declarar que uma categoria isolada equivale à seleção clínica de toda a variável;
- escolher a penalização pela regra de um erro-padrão, favorecendo maior regularização quando o desempenho for equivalente.

### 13.4 Avaliação aninhada

Usar os mesmos folds externos da CART para comparabilidade:

- camada externa estratificada de 10 folds × 5 repetições;
- tuning interno de 5 folds;
- RMSE como métrica primária de tuning do modelo contínuo;
- log loss como métrica primária de tuning do modelo logístico;
- calcular externamente R², RMSE e MAE no contínuo;
- calcular externamente AUC, Brier e log loss no logístico;
- avaliar calibração usando exclusivamente previsões externas;
- registrar frequência de seleção, magnitude dos coeficientes e variabilidade das previsões entre folds;
- ajustar uma versão final exploratória em toda a amostra somente depois de obter a avaliação aninhada.

### 13.5 Comparação com os modelos congelados

Comparar modelos usando as mesmas observações e, quando aplicável, as mesmas partições externas. Apresentar diferenças absolutas de desempenho e estabilidade, não apenas ranqueamento.

O relatório deverá afirmar que eventual ganho exploratório precisa ser confirmado em nova amostra e não autoriza substituir retrospectivamente o modelo principal.

## 14. Estrutura do novo relatório

Criar `relatorio_prognostico.qmd` e renderizar `relatorio_prognostico.html`, mantendo o documento atual inalterado.

Estrutura mínima:

1. título, resumo executivo e como reproduzir;
2. contexto clínico e finalidade de uso;
3. objetivos;
4. população, fonte de dados e momento da previsão;
5. definições de preditores e desfechos;
6. auditoria, duplicatas, dados ausentes e fluxograma;
7. descrição da amostra analítica;
8. tamanho amostral;
9. métodos de desenvolvimento e avaliação interna;
10. resultados do modelo linear principal;
11. resultados do modelo logístico secundário;
12. tabela consolidada de desempenho aparente e corrigido;
13. CART exploratória;
14. análises de sensibilidade;
15. limitações e implicações clínicas;
16. conclusão estatística;
17. sugestões para o manuscrito;
18. apêndice de modelagem flexível;
19. equações completas, referências e informações da sessão.

## 15. Subsídios para o manuscrito

Incluir caixas ou subseções chamadas **“Sugestão para o manuscrito”**, com valores inseridos dinamicamente pelo R e nunca digitados manualmente.

Preparar textos para:

- objetivo principal e objetivos secundários;
- desenho do estudo e população-alvo;
- definição do momento zero e horizonte prognóstico;
- definição dos desfechos;
- tratamento de duplicatas e dados ausentes;
- justificativa do tamanho amostral;
- especificação prévia dos 19 parâmetros;
- descrição do bootstrap e correção de otimismo;
- desempenho e calibração do modelo linear;
- desempenho e calibração do modelo logístico;
- apresentação do shrinkage;
- interpretação da CART como exploratória;
- análise flexível como apêndice gerador de hipóteses;
- limitações, necessidade de validação externa e ausência de indicação terapêutica;
- conclusão sem usar “modelo validado” como propriedade definitiva.

Formulação editorial preferencial:

> Desenvolvimento e avaliação interna por bootstrap de modelos prognósticos para resposta radiográfica em seis meses.

Evitar:

- “modelo validado” sem qualificação;
- conclusões causais sobre os coeficientes;
- seleção de “fatores importantes” baseada somente em p-valores;
- alegação de generalização para outras populações;
- recomendação de decisão terapêutica individual.

## 16. Organização técnica e artefatos

O relatório deverá ser executável em sessão R limpa. Funções de métricas, bootstrap, calibração e estabilidade deverão ficar em arquivo auxiliar testável, evitando um único QMD monolítico.

Artefatos planejados:

- `relatorio_prognostico.qmd`;
- `relatorio_prognostico.html` autocontido;
- funções R auxiliares para preparação, métricas e reamostragem;
- pasta de resultados agregados com tabelas e figuras finais;
- registro das versões de R, Quarto e pacotes;
- objeto agregado de resultados sem `model.frame` ou dados individuais.

O relatório não deverá instalar pacotes durante a renderização. Dependências deverão ser verificadas no início e a execução deverá parar com mensagem clara se alguma estiver ausente. Incluir, no mínimo, os pacotes já usados no projeto e os necessários para bootstrap, penalização, splines e avaliação aninhada.

## 17. Testes e verificações

### 17.1 Testes da preparação dos dados

- a aba `dados` existe e contém as colunas esperadas;
- a base bruta possui 621 linhas;
- os seis IDs dos três pares estão presentes antes da limpeza;
- cada par é idêntico nas variáveis clínicas e no desfecho;
- somente 46, 162 e 248 são excluídos como duplicatas;
- após deduplicação existem 618 IDs únicos;
- somente 390, 535 e 628 são excluídos por Lenke ausente;
- a base analítica contém 615 linhas;
- o desfecho logístico contém 317 eventos e 298 não eventos;
- os IDs 81, 174 e 401 permanecem e mantêm correção acima de 100%;
- IMC, Cobb máximo, `delta` e `delta_cat` coincidem com cálculos independentes.

### 17.2 Testes das funções estatísticas

- testar R², RMSE, MAE, AUC, Brier e log loss em exemplos pequenos com resultado conhecido;
- testar limite numérico de probabilidades no cálculo de log loss;
- testar calibração com previsões perfeitas, constantes e invertidas;
- testar correção de otimismo respeitando a direção de cada métrica;
- testar reajuste do intercepto após shrinkage;
- testar comportamento diante de não convergência, coeficientes infinitos, nível categórico ausente e evento único;
- confirmar que funções não dependem de objetos globais ou `.RData`.

### 17.3 Testes dos modelos e da reamostragem

- 19 parâmetros preditores nos dois modelos congelados;
- matrizes com posto completo;
- mesmas 615 observações e mesma matriz de preditores;
- convergência logística e ausência de estimativas não finitas no modelo final;
- pelo menos 1.980 das 2.000 réplicas bootstrap válidas;
- nenhuma observação da camada externa usada no tuning interno;
- pré-processamento, splines e padronização estimados somente nos dados de treinamento;
- hiperparâmetros finais selecionados pela regra especificada;
- repetição com a mesma semente produz resultados idênticos dentro de tolerância numérica;
- previsões calculadas manualmente para casos de teste coincidem com `predict()`.

### 17.4 Testes do relatório

- renderização integral sem erros ou warnings críticos;
- execução bem-sucedida após iniciar R sem restaurar `.RData`;
- nenhum texto, objeto, tabela ou gráfico de progressão no HTML;
- nenhum número de resultado clínico digitado manualmente;
- tabelas e narrativa usam a mesma fonte de objetos;
- equações e níveis de referência estão completos;
- gráficos têm eixos, unidades e legendas legíveis;
- o HTML não expõe IDs nem linhas individuais;
- links e referências metodológicas funcionam;
- informações de sessão e semente estão registradas.

## 18. Critérios de aceitação

O trabalho estará concluído quando:

1. a coorte final de 615 participantes estiver reproduzida e auditada;
2. os diagnósticos e o tamanho amostral tiverem sido recalculados;
3. os modelos congelados estiverem ajustados em toda a amostra;
4. as métricas aparentes, otimismo e métricas corrigidas estiverem disponíveis;
5. calibração, shrinkage, estabilidade e equações finais estiverem apresentados;
6. a CART estiver avaliada por procedimento aninhado;
7. a análise penalizada flexível estiver no apêndice e claramente identificada como exploratória;
8. as análises de progressão tiverem sido removidas;
9. o relatório contiver textos de apoio suficientes para métodos, resultados e discussão do manuscrito;
10. todos os testes e a renderização limpa tiverem sido aprovados.

## 19. Sequência de implementação

O trabalho foi decomposto em tarefas numeradas. Cada arquivo define objetivo, atividades, entregáveis, evidências e critérios de conclusão.

| Ordem | Tarefa | Dependências |
|---:|---|---|
| 01 | [Preparar a estrutura reprodutível](01_preparacao_reprodutivel.md) | nenhuma |
| 02 | [Construir e auditar a coorte](02_coorte_analitica.md) | 01 |
| 03 | [Reajustar os modelos congelados e diagnósticos](03_modelos_congelados.md) | 02 |
| 04 | [Atualizar a avaliação do tamanho amostral](04_tamanho_amostral.md) | 03 |
| 05 | [Implementar e testar métricas e bootstrap](05_metricas_bootstrap.md) | 02–03 |
| 06 | [Executar a avaliação interna](06_avaliacao_interna.md) | 05 |
| 07 | [Produzir shrinkage, equações e estabilidade](07_shrinkage_equacoes.md) | 06 |
| 08 | [Corrigir a avaliação da CART](08_cart_aninhada.md) | 02, 05 |
| 09 | [Executar a modelagem flexível exploratória](09_modelagem_flexivel.md) | 02, 05 |
| 10 | [Executar análises de sensibilidade](10_analises_sensibilidade.md) | 03, 06–09 |
| 11 | [Montar o relatório e textos para o manuscrito](11_relatorio_manuscrito.md) | 02–10 |
| 12 | [Executar verificação final e empacotar evidências](12_verificacao_final.md) | 11 |

As tarefas devem ser executadas na ordem acima. Uma tarefa só pode ser encerrada quando suas evidências estiverem registradas e seus critérios de conclusão tiverem sido satisfeitos.

## 20. Premissas e limitações já reconhecidas

- a coorte é tratada como uma única população, sem estrutura por centros disponível para validação interna-externa;
- análise por casos completos é aceitável nesta versão devido a apenas três ausências em Lenke, mas o mecanismo de ausência deverá ser discutido;
- o ponto de corte de 5° precisa de justificativa clínica e deve ser interpretado à luz da variabilidade de mensuração do Cobb;
- a amostra é predominantemente feminina, limitando a precisão para participantes masculinos;
- o modelo é desenvolvido em uma única base e requer validação externa antes de generalização;
- a CART e a análise flexível são exploratórias;
- desempenho aparente não será interpretado como desempenho esperado em novos pacientes;
- associações dos coeficientes não serão interpretadas como efeitos causais do tratamento.

## 21. Referências metodológicas centrais

- Collins GS et al. TRIPOD+AI statement: updated guidance for reporting clinical prediction models that use regression or machine learning methods. *BMJ*. 2024;385:e078378. <https://www.bmj.com/content/385/bmj-2023-078378>
- Riley RD et al. Calculating the sample size required for developing a clinical prediction model. *BMJ*. 2020;368:m441. <https://www.bmj.com/content/368/bmj.m441>
- Efthimiou O et al. Developing clinical prediction models: a step-by-step guide. *BMJ*. 2024;386:e078276. <https://www.bmj.com/content/386/bmj-2023-078276>
- Riley RD et al. Evaluation of clinical prediction models (part 1): from development to external validation. *BMJ*. 2024;384:e074819. <https://www.bmj.com/content/384/bmj-2023-074819>
- Moons KGM et al. PROBAST: a tool to assess risk of bias and applicability of prediction model studies. *Ann Intern Med*. 2019;170:51–58. <https://www.probast.org/>
- Varma S, Simon R. Bias in error estimation when using cross-validation for model selection. *BMC Bioinformatics*. 2006;7:91. <https://pubmed.ncbi.nlm.nih.gov/16504092/>
