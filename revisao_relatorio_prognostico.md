# Parecer de revisão do relatório prognóstico

Revisão em 07/09/2026, atualizada com o esclarecimento do investigador sobre a avaliação transversal da correção pelo colete na anamnese. Escopo: comparação de `relatorio_prognostico.qmd` com `analisys.qmd`, inspeção dos scripts e resultados consolidados, exame das figuras e consulta dirigida à literatura metodológica e clínica. Esta é uma revisão crítica, não uma avaliação formal independente pelo PROBAST+AI nem uma revisão sistemática da literatura. Os relatórios e os resultados dos modelos foram preservados.

**O relatório atual melhorou a avaliação interna, mas comprimiu demais a explicação científica.** Há resultados relevantes já disponíveis que não aparecem no texto, pressupostos sem interpretação e algumas afirmações que excedem a evidência apresentada. Recomendo ampliar métodos e discussão, recuperar a apresentação da CART e corrigir os pontos técnicos abaixo antes de consolidar a redação para submissão.

Os avanços que devem permanecer são: coorte auditada, distinção entre desempenho aparente e corrigido, 2.000 réplicas bootstrap por modelo principal, calibração, shrinkage, separação das análises exploratórias e tuning aninhado. O relatório anterior é uma referência útil de apresentação, mas seus procedimentos não devem ser reaproveitados automaticamente.

## 1. Prioridades antes da submissão

| Prioridade | Achado verificável | Melhoria proposta | Natureza |
|---|---|---|---|
| Alta | Correção pelo colete esclarecida como avaliação transversal na anamnese, mas insuficientemente descrita no relatório | Explicitar protocolo, cálculo e racional como indicador de maleabilidade/corrigibilidade imediata da curva | Documentação e redação; temporalidade esclarecida |
| Essencial | Algoritmo logístico flexível não minimiza o objetivo penalizado declarado em teste sintético | Corrigir ou substituir a implementação, verificar numericamente e repetir as análises afetadas | Correção analítica |
| Essencial | Tabelas e legendas chamam folds externos da CV de avaliação “externa” | Usar “validação interna por CV aninhada, avaliada nos folds externos” | Redação |
| Essencial | Diagnóstico de heteroscedasticidade sem consequência para a interpretação | Explicar o resultado, revisar inferência dos coeficientes e avaliar cobertura dos intervalos | Redação e análise complementar |
| Essencial | Resumo dos cortes CART inclui concorrentes e substitutos | Extrair cortes primários por nó antes de discutir estabilidade dos limiares | Correção analítica |
| Essencial | “A priori”, hierarquia das interações e checklists têm sustentação documental insuficiente no relatório | Distinguir fatos comprovados, decisões após exploração e pendências | Auditoria e redação |
| Alta | Sensibilidades, estabilidade estrutural e detalhes do tuning já existem, mas quase não aparecem | Incorporar tabelas e sínteses interpretativas | Principalmente relato |
| Alta | CART ilustrativa existente não é incorporada e tem rótulos pouco legíveis | Redesenhar com `rpart.plot`, incluir probabilidades, contagens e regras das folhas | Visualização |
| Alta | Incerteza do desempenho e significado do shrinkage ficam ambíguos | Identificar exatamente o estimador, o modelo e o tipo de intervalo | Redação e análises selecionadas |
| Alta | Referências restritas a cinco itens, sem ligação às escolhas; DOI incorreto | Corrigir bibliografia e citar cada decisão relevante no método | Bibliografia |
| Editorial | Sumário executivo e conclusão quase não apresentam números ou achados | Abrir com magnitude, precisão e implicação dos principais resultados | Redação |

## 2. Pergunta clínica, população e temporalidade

O relatório precisa explicar **para quem, em que situação e em qual momento** as previsões são produzidas. Hoje, “coorte com medidas disponíveis” descreve uma condição analítica, mas não define suficientemente a população clínica de interesse.

Acrescentar origem e período de inclusão, delineamento, critérios de elegibilidade, cenário assistencial, tipo de colete e protocolo, adesão disponível, tratamentos concomitantes, perdas de acompanhamento e intervalo real até a radiografia final. Se essas informações não estiverem disponíveis, registrar a ausência. A planilha com 621 registros não demonstra, por si só, que todos os pacientes elegíveis do serviço foram incluídos.

**A correção pelo colete é uma medida transversal disponível na avaliação inicial.** Conforme esclarecimento do investigador, ela é obtida rotineiramente na anamnese deste estudo e quantifica a diferença momentânea da curvatura ao aplicar um colete rígido. Representa a resposta mecânica imediata da curva e pode funcionar como indicador de maleabilidade e potencial de correção. Sua temporalidade está, portanto, esclarecida como preditor basal; a hipótese anteriormente levantada de utilização da medida do desfecho deve ser retirada da revisão. A variável entra nos dois modelos principais e aparece na raiz de todas as 50 árvores reamostradas.

O racional clínico é que uma curva com maior correção imediata apresenta maior componente flexível ou redutível, potencialmente associado a maior capacidade de correção e manutenção do alinhamento durante o tratamento. Para a redação científica, preferir **“maior componente redutível da deformidade”** a “deformidade não estrutural”: a resposta momentânea, isoladamente, não estabelece ausência de alterações estruturais nem comprova manutenção futura da correção. Essa manutenção é a hipótese prognóstica longitudinal a investigar. Estudos de flexibilidade e correção inicial oferecem suporte ao racional, com protocolos e seguimentos que precisam ser distinguidos dos utilizados nesta coorte. [Estudo sobre flexibilidade e correção inicial](https://pubmed.ncbi.nlm.nih.gov/26909835/), [estudo sobre flexibilidade e evolução após uso de colete](https://pubmed.ncbi.nlm.nih.gov/32009436/).

**Sugestão de texto para o método:** “A correção pelo colete foi avaliada transversalmente na anamnese inicial, pela diferença momentânea da curvatura mediante aplicação de colete rígido. Essa medida foi considerada um possível marcador de maleabilidade e corrigibilidade imediata da curva, com potencial valor prognóstico para a evolução radiográfica durante o tratamento.” Completar com fórmula, unidade, medidas utilizadas e padronização do procedimento, sem presumir detalhes ainda não documentados.

Recomendo um esquema temporal agrupando anamnese, avaliação transversal da correção pelo colete e demais preditores na avaliação inicial, seguido do momento de previsão e da avaliação do desfecho. Registrar o marco a partir do qual são contados os seis meses. A declaração de disponibilidade dos preditores deve seguir o relato recomendado pelo [TRIPOD+AI](https://www.bmj.com/content/385/bmj-2023-078378).

A literatura clínica ajuda a contextualizar, mas precisa ser compatibilizada com o estudo: há uma coorte de 488 pacientes sobre correção inicial e resultado do uso de colete, com seguimento distinto deste horizonte de seis meses. Ela sustenta discutir a variável, sem validar os coeficientes ou limiares aqui obtidos. [Estudo sobre correção inicial](https://pubmed.ncbi.nlm.nih.gov/28437355/).

## 3. Desfecho e justificativa dos preditores

Explicitar a equação `delta = maior Cobb aos seis meses − maior Cobb basal`, o sinal e a definição binária `delta ≤ −5°`. O máximo basal é obtido entre três regiões; o dado final registra apenas a maior magnitude. Portanto, não está garantido que a diferença acompanhe a mesma curva anatômica. Há dez empates no máximo basal, cuja regra de tratamento já está auditada e pode ser resumida.

Manter “melhora radiográfica”. O relatório anterior usava “melhora clínica”; esse termo exige evidência adicional de relevância para sintomas, função ou qualidade de vida. O limiar de 5° precisa ser contextualizado em relação à variabilidade da medida, ao método radiográfico utilizado, aos avaliadores e ao protocolo com/sem colete. As diretrizes SOSORT discutem erro de mensuração dessa ordem, sem converter automaticamente 5° em diferença clinicamente importante. [SOSORT 2016, publicado em 2018](https://pmc.ncbi.nlm.nih.gov/articles/PMC5795289/).

Criar uma tabela de preditores com definição, unidade, momento de obtenção, forma funcional, graus de liberdade, referência categórica e justificativa. São **dez variáveis e 19 parâmetros de preditores**, além do intercepto. Explicar por que Lenke e Risser entram como fatores, o critério de flexibilidade e a classificação do escoliômetro. Descrever a correção pelo colete como medida quantitativa transversal de corrigibilidade imediata e distingui-la da variável categórica “flexibilidade” já incluída no modelo: esclarecer como cada uma é obtida e o que pode acrescentar à outra. A força da fundamentação pode variar: distinguir evidência clínica prévia de escolha pragmática pela disponibilidade da base.

**Justificar a ausência do Cobb basal na especificação principal.** Ele aparece na definição de delta e nas análises alternativas, mas não na lista de preditores dos modelos congelados. Estudos prognósticos em escoliose investigam magnitude basal, maturidade e padrão da curva. Isso torna necessária uma justificativa explícita, sem impor alteração retrospectiva do modelo. O BrAIST prognóstico de pacientes não tratados é uma referência de racional, mas tem população e desfecho diferentes. [Dolan e colaboradores, 2019](https://pubmed.ncbi.nlm.nih.gov/31731999/).

Uma sensibilidade útil é comparar, com a mesma avaliação interna, `delta ~ X`, `delta ~ Cobb basal + X` e a formulação equivalente `Cobb final ~ Cobb basal + X`. As duas últimas, quando lineares e com o mesmo desenho, diferem pela reparametrização do coeficiente basal. Comparar seus R² isoladamente confunde mudanças no alvo com ganho prognóstico; comparar erro em graus e calibração.

Explicar ainda a mudança de escopo em relação ao relatório anterior, que analisava progressão. Não é necessário restaurar esse modelo: é necessário dizer por que foi retirado e como a hierarquia de desfechos foi decidida.

## 4. Pressupostos: tornar explícita a consequência de cada diagnóstico

A figura atual de resíduos já contém resíduos versus previsão, histograma, Q–Q e influência. A lacuna não é ausência completa de diagnóstico visual: faltam interpretação, investigação de forma funcional e ligação com as decisões analíticas.

| Componente | O que esclarecer | Evidência atual e ação recomendada |
|---|---|---|
| Independência | Uma observação por participante; possíveis centros, avaliadores ou outras estruturas de agrupamento | Deduplicação é uma parte da verificação. Documentar o desenho; Durbin–Watson em ordem arbitrária de pacientes não resolve a questão |
| Média condicional linear | Relação dos contínuos com delta e forma do modelo | Acrescentar suavização dos resíduos e gráficos ajustados; avaliar sensibilidades de não linearidade previamente definidas |
| Variância dos erros | Impacto sobre erros padrão e intervalos de predição | Breusch–Pagan: p = 0,0105. Discutir heteroscedasticidade e apresentar inferência robusta como sensibilidade |
| Distribuição dos resíduos | Caudas e adequação dos intervalos clássicos | Interpretar Q–Q; não exigir normalidade das covariáveis nem transformar Shapiro–Wilk em aprovação/reprovação automática |
| Colinearidade | Redundância e precisão, considerando fatores com vários graus de liberdade | Mostrar GVIF e sua transformação ajustada; os valores ajustados disponíveis vão aproximadamente de 1,05 a 1,38 |
| Influência | Quanto casos particulares alteram coeficientes e previsões | Integrar as sensibilidades já calculadas; os critérios são sinais para investigação, não regras de exclusão |
| Modelo logístico | Forma funcional no logit, separação, calibração e probabilidade do evento correto | Convergência, coeficientes finitos e ausência de células vazias não constituem prova formal de ausência de separação multivariável |

Como proposta de análise, usar IC dos coeficientes lineares com covariância robusta, por exemplo HC3, acompanhados de avaliação gráfica. Essa correção trata inferência sobre coeficientes; não corrige automaticamente forma funcional, calibração ou cobertura de previsões individuais. A literatura sobre inferência robusta discute alternativas HC e bootstrap. [Rajh-Weber, Huber e Arendasy, 2026](https://journals.sagepub.com/doi/10.1177/25152459251408046).

Há também uma inconsistência pequena, mas verificável: `wald_coefficient_table()` combina p-valores t de `summary(lm)` com IC normais de `confint.default()`. Para cifose, o p-valor é 0,0503, mas o limite superior do IC é ligeiramente negativo. Uniformizar a convenção inferencial e evitar conclusões baseadas apenas na travessia de 0,05. Fonte: [R/07_frozen_models.R](/Users/caiosainvallio/consultoria/scoliosis_model/R/07_frozen_models.R:54).

Não recuperar automaticamente do relatório anterior: teste de autocorrelação sem estrutura temporal; Hosmer–Lemeshow como evidência principal de calibração; “verificações posteriores” sem esclarecer o caráter frequentista das simulações; seleção pela significância isolada; classificação por limiar de probabilidade sem uso clínico definido.

## 5. Validação, tamanho amostral e incerteza

**Explicar o bootstrap de forma reproduzível.** Descrever unidade de reamostragem, amostra de tamanho 615 com reposição, 2.000 tentativas por modelo, ajuste na réplica e avaliação na própria réplica e na coorte original. Explicar o sinal do otimismo para métricas em que maior ou menor é melhor. Informar tentativas, réplicas válidas e falhas por modelo. `sum(n_failed)` sobre métricas não é uma contagem geral de réplicas falhas quando a mesma réplica falha em mais de uma métrica. [Steyerberg e colaboradores, 2001](https://pubmed.ncbi.nlm.nih.gov/11470385/).

O bootstrap atual valida a especificação fixa. Se houve escolha de desfecho, preditores ou forma funcional orientada pelos mesmos dados antes do congelamento, essa seleção não é automaticamente incluída na correção do otimismo. “Congelado” não demonstra “especificado antes de examinar os dados”. Usar uma cronologia documentada de decisões.

**Separar três coisas:** desempenho aparente; desempenho corrigido por otimismo da estratégia avaliada; equação final após shrinkage. Os fatores 0,9581 e 0,8835 foram obtidos das inclinações corrigidas e usados posteriormente para reduzir os coeficientes. A tabela de desempenho não deve ser apresentada como validação independente das equações pós-shrinkage. Se o objeto final for o alvo da avaliação, o procedimento completo precisa ser representado na reamostragem adequada.

O relatório fornece pontos corrigidos, mas quase não informa sua incerteza. Definir o método antes de acrescentar IC. Os percentis das métricas nos folds, dos otimismos ou das previsões bootstrap não são intercambiáveis com IC do desempenho corrigido. A AUC com IC aparente deve permanecer claramente identificada como aparente.

Na CART e na análise flexível, os **50 folds externos pertencem à validação interna aninhada**: dez folds, cinco repetições, tuning em cinco folds internos. Explicar a estrutura e a dependência entre estimativas. A reutilização dos folds para selecionar e avaliar no relatório anterior não deve ser retomada. [Varma e Simon, 2006](https://link.springer.com/article/10.1186/1471-2105-7-91).

Na calibração agrupada da CART, cada pessoa contribui com previsões em cinco repetições. Esclarecer que o denominador agregado conta previsões repetidas, não novos participantes. Quantis e desvios padrão entre folds descrevem variabilidade de reamostragem; não são IC baseados em 50 amostras independentes.

**Tamanho amostral:** promover a síntese já disponível em `sample_size_assessment.md` para o corpo do relatório: 615 participantes, 317 eventos, 298 não eventos, 19 parâmetros e shrinkage desejado de 0,90. A suficiência depende do desempenho antecipado: o cenário contínuo com R² de 0,20 exige 676; o binário com 60% do Cox–Snell aparente exige 654. Os cenários baseados no desempenho observado são retrospectivos e potencialmente otimistas. Eles não comprovam adequação universal e não justificam a complexidade flexível. [Riley, desfechos contínuos](https://pubmed.ncbi.nlm.nih.gov/30347470/), [Riley, desfechos binários](https://doi.org/10.1002/sim.7992).

**Estabilidade individual:** a amplitude mediana entre percentis 2,5 e 97,5 das previsões bootstrap é 2,86° no modelo linear e 27,8 pontos percentuais no logístico. Traduzir essas unidades e explicar que são amplitudes de previsões entre modelos reamostrados. Não são erro residual nem intervalo de predição de um futuro Cobb. O “índice” do projeto é essa amplitude; não o identificar automaticamente com o índice de diferença absoluta média proposto por Riley e Collins. [Estabilidade de modelos prognósticos](https://onlinelibrary.wiley.com/doi/full/10.1002/bimj.202200302).

Os intervalos pós-shrinkage de `predict.shrunk_linear_model()` usam sigma e a matriz de informação do ajuste original, com a fórmula clássica homoscedástica, centrada na previsão reduzida. Não incorporam explicitamente a estimação do fator de shrinkage. Antes de apresentá-los como intervalos finais de 95%, avaliar cobertura e justificar aproximações. Fonte: [R/09_shrinkage_equations.R](/Users/caiosainvallio/consultoria/scoliosis_model/R/09_shrinkage_equations.R:128).

## 6. CART: recuperar a figura e enriquecer a interpretação

A árvore **já foi gerada**, em `results/prognostico/figures/cart_illustrative_tree.png`, mas o QMD inclui apenas a calibração. A figura existente usa `plot()` e `text()` e apresenta rótulos como `risser=acde` e sobreposição de texto. O relatório anterior usava `rpart.plot`, com caixas coloridas e folhas alinhadas; essa qualidade visual pode ser recuperada usando o objeto atual.

Proposta para a figura: `rpart.plot`, layout semelhante ao anterior, rótulos em português, níveis categóricos por extenso, ramos “sim/não”, cor representando probabilidade de melhora e nós com número de participantes, número de eventos e probabilidade. Explicar a ordem das classes. Usar cortes arredondados para leitura sem alterar a regra computacional. Fornecer SVG/PDF vetorial e PNG de alta resolução; conferir legibilidade na largura real da página.

A legenda deve dizer que a árvore foi ajustada em toda a coorte para ilustrar regras, depois do tuning; suas proporções por folha são aparentes. A avaliação interna apresentada pertence ao procedimento de construção de árvores, não a uma validação externa daquela figura específica.

Acrescentar:

- Método: partição recursiva, critério de divisão, complexidade, profundidade, tamanho mínimo para dividir e regra one-SE.
- Grade efetiva: `cp` em 0,001/0,005/0,01/0,02; profundidade de 1 a 5; `min_n` em 10/20/40, total de 60 combinações. No código, `min_n` controla `minsplit`, não o tamanho mínimo de cada folha.
- Critério: maior AUC média interna, elegibilidade dentro de um erro padrão e preferência por menor profundidade, maior `minsplit` e maior `cp`. Não descrever uma poda posterior que não tenha sido executada.
- Configuração ilustrativa: `cp=0,01`, profundidade máxima 5, `minsplit=40`; distinguir limites configurados da estrutura efetivamente obtida.
- Tabela de folhas: regras completas, n, eventos e proporção aparente, com identificação de grupos pequenos.
- Estabilidade: frequência da raiz, variáveis por profundidade, número de folhas e distribuição dos cortes realmente usados.

**Correção necessária antes de publicar estabilidade de cortes:** `cart_structure_tables()` percorre todas as linhas de `model$splits`. O objeto `rpart` armazena também cortes concorrentes e substitutos nessa matriz. Reextrair apenas os primários, respeitando `frame$ncompete` e `frame$nsurrogate`; manter análises de substitutos separadas, se desejadas. A frequência da raiz obtida de `frame$var` é outra medida e não sofre desse problema. [Documentação oficial de rpart](https://stat.ethz.ch/R-manual/R-devel/library/rpart/html/rpart.object.html). Fonte: [R/10_cart_nested.R](/Users/caiosainvallio/consultoria/scoliosis_model/R/10_cart_nested.R:415).

Há ainda um rótulo a corrigir: `scope="all_levels"` é atribuído apenas a nós com profundidade maior que dois, pois raiz e primeiros níveis recebem outros rótulos. Renomear como níveis profundos ou recomputar a frequência em todos os níveis, contando cada árvore uma vez por variável.

Mensagem já defensável: a correção pelo colete, medida transversal de corrigibilidade na anamnese, foi a raiz em 50/50 árvores. Esse achado é compatível com seu possível papel como marcador prognóstico de maleabilidade, mas não demonstra estabilidade de um limiar exato ou um mecanismo causal. A AUC média nos folds externos foi 0,792 e a inclinação de calibração média, 0,761. Os resultados indicam necessidade de examinar calibração e estabilidade antes de tratar as regras como grupos prognósticos consolidados.

## 7. Modelagem flexível: revisão técnica antes de ampliar as conclusões

O apêndice omite detalhes importantes: inclui Cobb basal, splines naturais com três graus de liberdade para seis variáveis numéricas, três famílias de interação e penalização elastic net. Assim, eventual diferença de desempenho reúne **novos preditores, novas formas funcionais, interações e penalização**. Não atribuir um ganho exclusivamente às splines.

**Achado confirmado por teste sintético:** o código declara o objetivo habitual `média da perda logística + penalização`, mas a etapa de mínimos quadrados ponderados divide os termos por `sum(weights)`, mantendo lambda. Para essa convenção de perda média, o denominador deve ser coerente com n; o esquema atual modifica a força efetiva da penalização durante o IRLS. No caso ridge, pertencente à grade utilizada, o ajuste próprio declarou convergência, mas não estacionou no objetivo declarado.

| Verificação sintética, semente 71, n=200, dois preditores, alpha=0 e lambda=0,08 | Resultado |
|---|---:|
| Função objetivo no ajuste próprio | 0,552148 |
| Função objetivo na otimização direta independente | 0,519362 |
| Maior componente absoluta do gradiente no ajuste próprio | 0,105205 |
| Maior diferença entre coeficientes | aproximadamente 0,561 |

O experimento é reproduzível em [scripts/review_check_flexible_objective.R](/Users/caiosainvallio/consultoria/scoliosis_model/scripts/review_check_flexible_objective.R). Ele comprova uma discrepância da implementação frente ao objetivo declarado; não quantifica seu impacto nos resultados clínicos. Recomendo corrigir e comparar com uma implementação estabelecida, harmonizando padronização, intercepto e lambda; verificar convergência e condições de otimalidade; depois repetir a parte logística afetada. Isso não atinge os ajustes principais feitos por `lm` e `glm`. Referência algorítmica: [Friedman, Hastie e Tibshirani, 2010](https://www.jstatsoft.org/article/view/v033i01).

**Hierarquia:** `flexible_hierarchy_audit()` verifica se os nomes dos efeitos principais estão na matriz candidata. Isso não demonstra que seus coeficientes permaneçam ativos quando uma interação é selecionada. Escrever “efeitos principais incluídos na matriz candidata”, ou implementar e testar a restrição hierárquica pretendida. Os testes atuais verificam presença de colunas; não há comparação com solução externa do objetivo penalizado. Fonte: [R/11_flexible_modeling.R](/Users/caiosainvallio/consultoria/scoliosis_model/R/11_flexible_modeling.R:696).

Usar a comparação com os modelos congelados nos mesmos folds já calculada. Como descrição provisória, o RMSE médio contínuo foi 4,187° contra 4,275° do modelo congelado nos mesmos folds: diferença de cerca de 0,089°. Essa diferença isolada não estabelece benefício prático. As comparações logísticas precisam ser revistas após a correção. Não usar uma comparação entre AUC bootstrap do principal e AUC de CV da CART como teste formal de superioridade.

Apresentar curvas ajustadas na escala clínica, com distribuição dos dados e incerteza, em vez de apenas coeficientes individuais de bases spline. Explicar que coeficientes de bases, especialmente penalizadas, não equivalem a efeitos clínicos isolados. [Zou e Hastie, 2005](https://doi.org/10.1111/j.1467-9868.2005.00503.x).

## 8. Sensibilidades e dados faltantes: aproveitar o que está pronto

Acrescentar uma seção própria de robustez utilizando as tabelas `sensitivity_*`, com cenário, motivação, n, mudança das previsões e impacto na conclusão. Os três casos com correção acima de 100% permanecem na análise principal; a exclusão temporária é uma sensibilidade, cuja interpretação também depende de verificar a definição dessa medida.

Há 55 observações sinalizadas pelos critérios combinados do modelo linear e 99 no logístico. Uma mensagem informativa é que a AUC aparente logística sobe de 0,867 para 0,971 quando o modelo é reajustado e avaliado na subamostra que exclui os casos sinalizados pelo diagnóstico logístico. Avaliado na coorte completa, esse reajuste tem AUC 0,864 e log loss 0,642, contra 0,455 no ajuste principal aparente. Isso mostra como melhorar a métrica numa população selecionada não demonstra melhora prognóstica geral. Essas avaliações continuam sendo sensibilidades nos dados de desenvolvimento, não validações independentes.

Na sensibilidade das hipercorreções, o RMSE avaliado na coorte completa muda de 4,1325° para 4,1335°; a AUC permanece aproximadamente 0,8674. É uma evidência descritiva de pequeno impacto nas métricas globais, sem garantir ausência de alterações em previsões específicas.

Para dados faltantes, mostrar o padrão **antes** da exclusão: três de 618 participantes após deduplicação, cerca de 0,49%, foram excluídos por Lenke ausente. Mostrar apenas “não há ausentes após caso completo” oculta a decisão. Apresentar justificativa da análise por caso completo e características agregadas dos excluídos, respeitando o n muito pequeno. A baixa proporção, isoladamente, não prova ausência de viés; tampouco exige imputação múltipla sem avaliar seu propósito e viabilidade.

A tabela descritiva deve cobrir todos os preditores e os desfechos, com médias/DP, medianas/IIQ quando úteis, amplitude e n por categoria. Restaurar a distribuição de delta com marcações em −5°, 0° e +5°. As faixas são descritivas; não representam limiares de probabilidade para decisão.

## 9. Mensagens diretas que o relatório já pode apresentar

Os valores abaixo foram conferidos nas saídas consolidadas. As sugestões são exemplos de redação, não novas conclusões clínicas.

| Resultado | Mensagem sugerida |
|---|---|
| 615 participantes; 317 com melhora | “A melhora radiográfica de pelo menos 5° ocorreu em 51,5% da coorte aos seis meses.” |
| R² corrigido 0,364; RMSE 4,28°; MAE 3,39° | “O modelo contínuo reteve capacidade prognóstica após correção interna, mas o erro de previsão permanece relevante em relação à escala de 5° usada para descrever melhora.” |
| AUC corrigida 0,848; Brier 0,160; inclinação 0,884 | “O modelo logístico ordenou participantes com e sem melhora com AUC de 0,848; a inclinação corrigida abaixo de um sinaliza previsões excessivamente extremas antes do shrinkage.” |
| Amplitude bootstrap mediana de 27,8 pontos percentuais | “A estabilidade das probabilidades individuais merece atenção, mesmo com discriminação global favorável.” |
| Raiz CART em 50/50 ajustes | “A corrigibilidade imediata medida com colete rígido na anamnese foi consistentemente escolhida na primeira divisão, em consonância com seu possível valor como marcador de maleabilidade; o limiar exato e os ramos seguintes requerem análise própria de estabilidade.” |
| Coeficiente linear pós-shrinkage para correção | “Mantidos os demais preditores, dez pontos percentuais a mais de correção pelo colete correspondem a delta previsto aproximadamente 1,19° menor.” |

Na última frase, acrescentar que a medida descreve a resposta momentânea ao colete na avaliação inicial e que a associação com delta futuro é uma relação do modelo, condicionada às outras variáveis. Ela é compatível com a hipótese de maior maleabilidade e potencial de resposta ao tratamento, sem estimar o efeito de aumentar a correção em uma pessoa nem demonstrar, por si só, manutenção após o horizonte estudado. No logístico, a OR pós-shrinkage para dez pontos percentuais é aproximadamente 2,33: odds não são probabilidade nem risco relativo, particularmente com evento frequente.

O RMSE de 4,28° não é margem de erro individual de ±4,28°, nem demonstra que o modelo detecta de forma confiável uma melhora individual de 5°. A AUC de 0,848 também não significa “84,8% dos pacientes classificados corretamente”.

Adicionar gráficos de coeficientes em escalas compreensíveis: por dez pontos percentuais de correção e contrastes categóricos explícitos. Exibir IC do estimador correspondente; não colocar os IC aparentes ao redor de coeficientes reduzidos como se incorporassem a incerteza do shrinkage. Reservar a precisão numérica completa das equações à reprodução, usando duas ou três casas nas tabelas de leitura.

A calibração merece curva suavizada, identidade e distribuição das probabilidades, distinguindo ajuste aparente de avaliação por reamostragem. Uma calibração aparente com intercepto zero e inclinação um não prova generalização. [Van Calster e colaboradores, 2019](https://doi.org/10.1186/s12916-019-1466-7).

Para aplicabilidade, conectar cada resultado a uma finalidade plausível de pesquisa: comunicar incerteza, avaliar capacidade de estratificação e desenhar validação externa. Curvas de decisão podem integrar uma etapa futura quando houver uma ação clínica, evento e faixa de limiares justificáveis. Não adicionar benefício líquido apenas como mais um gráfico; sem decisão definida, sua interpretação fica sem fundamento. [Vickers, Van Calster e Steyerberg, 2016](https://www.bmj.com/content/352/bmj.i6).

## 10. Bibliografia, transparência e organização

**Erro bibliográfico confirmado:** a referência de Riley para desfechos contínuos termina em `10.1002/sim.7991` no relatório; o DOI correto é **10.1002/sim.7993**. A referência binária `10.1002/sim.7992` está correta. [Registro do artigo contínuo](https://pubmed.ncbi.nlm.nih.gov/30347470/).

Substituir a lista manual por um arquivo BibTeX e citações ligadas às escolhas. Os links deste parecer indicam fontes iniciais para: relato, avaliação crítica, tamanho amostral, validação interna, calibração, estabilidade, algoritmo penalizado, contexto clínico e utilidade. Não usar uma diretriz de relato como única justificativa para todas as escolhas estatísticas.

Atualizar a autoavaliação para **PROBAST+AI, publicado em 2025**, distinguindo qualidade do desenvolvimento, risco de viés da avaliação e aplicabilidade. “Algumas preocupações” não é uma categoria formal do PROBAST de 2019; se o texto permanecer descritivo, não o apresentar como classificação formal. Ausência de validação externa é uma limitação de transportabilidade, não uma determinação automática de alto risco de viés da avaliação interna. [PROBAST+AI](https://www.bmj.com/content/388/bmj-2024-082505).

No TRIPOD+AI, substituir “atendido” genérico por item oficial, localização e evidência ou pendência. Completar fonte, elegibilidade, mensuração, tratamentos, acesso ao protocolo, ética, financiamento e disponibilidade de dados/código conforme aplicável. Explicitar o que ainda depende dos investigadores. A sessão da renderização não comprova, sozinha, as versões utilizadas para gerar objetos congelados: incorporar também os registros das execuções originais e o vínculo entre código, dados e resultados.

Estrutura sugerida para a próxima versão:

1. Sumário executivo com cinco achados quantitativos e suas implicações.
2. Pergunta prognóstica, cenário e cronologia das medidas.
3. Coorte, perdas, dados faltantes e descrição completa.
4. Desfechos e justificativa dos preditores.
5. Métodos: especificação, pressupostos, amostra, avaliação interna e shrinkage.
6. Modelo contínuo: desempenho, calibração, coeficientes e interpretação do erro.
7. Modelo logístico: discriminação, calibração, probabilidades e estabilidade.
8. CART: método, árvore ilustrativa, folhas e estabilidade das regras.
9. Sensibilidades e síntese de robustez.
10. Discussão clínica, comparação com a literatura e limites de aplicabilidade.
11. Apêndices de equações, modelagem flexível revisada, checklists e reprodutibilidade.

Para cada análise, usar uma sequência constante: **pergunta → método e pressupostos → resultado → interpretação e limite**. Isso permite aprofundar o rigor sem transformar o relatório em uma coleção de saídas de software.

## 11. Sequência de implementação e critério de conclusão

**Primeiro, resolver validade e exatidão:** objetivo do algoritmo logístico flexível; cortes primários e rótulos CART; convenções de IC; termos “externo”, “a priori” e “hierarquia”; DOI incorreto. A temporalidade da correção pelo colete foi esclarecida pelo investigador: incorporar sua definição transversal na anamnese e seu racional de maleabilidade à documentação metodológica. O impacto do algoritmo flexível na coorte deve ser medido após correção, não presumido a partir do teste sintético.

**Depois, incorporar evidências já calculadas:** sensitividades, dados faltantes antes da exclusão, GVIF, estabilidade, tamanho amostral com premissas e árvore ilustrativa. Essa etapa pode enriquecer grande parte do relatório sem refazer o ajuste principal.

**Em seguida, executar complementos com pergunta definida:** inferência robusta, cobertura de intervalos, gráficos de relações ajustadas, comparadores simples e sensibilidade ao Cobb basal; avaliar a necessidade de IC do desempenho com método apropriado. Novas análises devem ser identificadas como decorrentes desta revisão.

**Por fim, conferir o documento:** correspondência entre cada número e sua fonte, ausência de IDs, legendas autossuficientes, terminologia consistente, citação junto ao método, distinção entre análise original e complemento, e inspeção visual do HTML e das figuras em dimensão de publicação. A revisão estará pronta quando um leitor puder reconstruir o processo e entender a implicação de cada resultado sem consultar os scripts.

Evidências locais principais: `relatorio_prognostico.qmd`, `analisys.qmd`, módulos `R/02`, `R/04`, `R/07` a `R/12`, testes da análise flexível e saídas agregadas em `results/prognostico/aggregated`. Não foram reexecutados os 2.000 bootstraps nem os ajustes aninhados nesta revisão. O único experimento novo foi a verificação sintética do objetivo logístico, além de cálculos resumidos sobre saídas existentes.
