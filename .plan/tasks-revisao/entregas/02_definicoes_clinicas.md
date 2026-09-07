# Entrega da Tarefa 02 — definições clínicas e racional

Data: 2026-09-07  
Escopo: fundamentação clínica e operacional para integração futura no relatório, sem alterar a coorte ou os modelos congelados.

## Síntese clínica confirmada

A população documentada é formada por adolescentes com escoliose idiopática submetidos a manejo conservador com colete e exercícios específicos para escoliose pelo método S4D. O momento da previsão é a avaliação basal/anamnese, antes do acompanhamento longitudinal, e o horizonte prognóstico nominal é de seis meses. O plano registra que as medidas radiográficas basal e final foram obtidas sob a mesma condição radiográfica definida no protocolo clínico, mas essa condição não está descrita nos arquivos disponíveis.

`correcao_colete` é uma avaliação **transversal** realizada na anamnese inicial. Ela compara a curvatura em radiografia sem colete com a curvatura durante o uso de colete rígido e está disponível no momento da previsão basal. Deve ser descrita como possível marcador quantitativo de maleabilidade/corrigibilidade imediata ou de maior componente flexível/redutível da deformidade. Não se deve inferir, a partir dessa resposta momentânea, ausência de alterações estruturais, efeito causal do tratamento, garantia de resposta ou manutenção longitudinal da correção. A manutenção é a hipótese prognóstica avaliada no seguimento.

Os três valores acima de 100% foram confirmados pela equipe como hipercorreções verdadeiras e permanecem inalterados na coorte principal. Sua influência é objeto de sensibilidade já prevista, não motivo para truncamento, winsorização ou exclusão.

## Linha temporal operacional

1. **Avaliação basal/anamnese:** idade e demais características clínicas; medidas radiográficas basais; medidas de escoliômetro; classificação de Lenke, Risser e flexibilidade; comparação radiográfica momentânea sem/com colete rígido que produz `correcao_colete`.
2. **Momento da previsão:** todos os dez preditores estão tratados como disponíveis nesse ponto. Não há uso do desfecho futuro para construir `correcao_colete` nos documentos vigentes.
3. **Tratamento longitudinal:** manejo conservador com colete e exercícios S4D.
4. **Horizonte nominal de seis meses:** registro de `maior_curva_6_meses`, usado na construção dos desfechos.

O marco exato de contagem dos seis meses e a distribuição do intervalo real não estão documentados.

## Desfechos e interpretação

O desfecho contínuo principal é:

`delta = maior_curva_6_meses − cobb_inicial_maior`

`cobb_inicial_maior` é o máximo, no basal, entre Cobb torácico proximal, torácico e lombar. Valores negativos de `delta` indicam redução radiográfica da maior magnitude; valores positivos indicam aumento. O código preserva todos os empates, concatena as regiões empatadas e usa somente o valor máximo. Há dez empates na coorte analítica de 615 participantes.

A planilha final contém apenas a **maior magnitude** aos seis meses, não as três regiões finais. Assim, a curva que fornece o máximo no basal pode não ser a mesma curva anatômica que fornece o máximo no seguimento. O `delta` mede mudança entre máximos, não necessariamente mudança da mesma curva identificada longitudinalmente. Essa escolha foi aprovada pela equipe e deve ser explicitada.

O desfecho binário secundário é `delta_cat = 1` quando `delta ≤ −5°` e `0` nos demais casos. A expressão correta é **melhora radiográfica de pelo menos 5°**. O limiar é compatível com a ordem de grandeza do erro de mensuração manual do Cobb discutida pelas diretrizes SOSORT, mas isso não o transforma automaticamente em diferença clínica importante para sintomas, função ou qualidade de vida. O protocolo radiográfico e a confiabilidade dos avaliadores desta coorte são necessários para interpretar o limiar.

Os modelos são prognósticos. Associações ou previsões não estimam o efeito causal do colete, dos exercícios ou de qualquer preditor; não definem indicação terapêutica e não possuem limiar de decisão clínica.

## Preditores, parâmetros e fórmulas congeladas

Os dois modelos principais usam as mesmas fórmulas reais:

- linear: `delta ~ idade + imc + cifose_toracica + lordose_lombar + correcao_colete + sexo + lenke + risser + flexibilidade + escoliometro_maior_10_graus`;
- logístico: `delta_cat ~ idade + imc + cifose_toracica + lordose_lombar + correcao_colete + sexo + lenke + risser + flexibilidade + escoliometro_maior_10_graus`.

São cinco preditores numéricos com um grau de liberdade cada e cinco categóricos: sexo (1), Lenke (5), Risser (4), flexibilidade (1) e classe do escoliômetro (3). Total: 19 parâmetros preditores e um intercepto. As referências reais são feminino, Lenke 1, Risser 0, flexível e escoliômetro normal. O dicionário completo e legível por máquina está em `results/prognostico/revisao/aggregated/dicionario_preditores.csv`.

`correcao_colete` e `flexibilidade` não são sinônimos operacionais nos dados: a primeira é quantitativa e percentual, vinculada à comparação sem/com colete; a segunda é uma categoria flexível/rígido cujo teste e limiar não foram documentados. Elas podem representar aspectos relacionados da redutibilidade, mas o protocolo ausente impede afirmar independência conceitual, ausência de redundância ou valor incremental.

## Cobb basal e especificação congelada

O Cobb basal participa da definição de `delta`, mas não é um dos dez preditores principais. A cronologia verificável é:

- a análise exploratória com esses dez preditores já estava no repositório em abril de 2026 e examinava também progressão;
- em 6 de setembro de 2026, o plano prognóstico registrou a decisão de preservar a especificação existente, retirar progressão e separar o modelo linear principal do logístico secundário;
- a coorte auditada e os modelos congelados foram implementados depois desse registro, também em 6 de setembro de 2026;
- a revisão de 7 de setembro de 2026 identificou que chamar toda a especificação de “a priori” excede a documentação.

Portanto, a justificativa verificável para o modelo principal sem Cobb basal é **procedimental**: preservar a especificação histórica de dez preditores após seu congelamento, evitando promover uma mudança pós-exploratória a modelo principal. Não há documentação de uma justificativa clínica prévia para excluir Cobb basal, nem evidência de que ele seja irrelevante. A literatura prognóstica em população não tratada inclui magnitude basal, maturidade e padrão de curva, mas não valida diretamente o modelo desta coorte tratada e com horizonte de seis meses.

A Tarefa 10 deve avaliar, sob a mesma estrutura de avaliação interna, `delta ~ X`, `delta ~ Cobb basal + X` e `Cobb final ~ Cobb basal + X`, comparando erro em graus e calibração. Isso é uma sensibilidade decorrente da revisão, não uma alteração retrospectiva do modelo principal. Como `delta` já contém Cobb basal, a discussão deve incluir acoplamento matemático, regressão à média e erro de mensuração.

## Escopo sem progressão

A análise histórica de progressão (`delta ≥ +5°`) existia na fase exploratória. O plano aprovado a retirou integralmente do relatório prognóstico e definiu a hierarquia atual: modelo linear de `delta` como principal, modelo logístico de melhora radiográfica como secundário, CART e modelagem flexível como exploratórias. A razão documentada é concentrar esta etapa na magnitude da mudança e na melhora radiográfica, preservando um desfecho contínuo principal e evitando multiplicação de modelos. Não reintroduzir progressão nem descrever sua exclusão como decisão ainda pendente.

## Texto proposto para integração futura

> Foram avaliados adolescentes com escoliose idiopática em manejo conservador com colete e exercícios específicos para escoliose pelo método S4D. A previsão foi definida na avaliação basal, antes do seguimento longitudinal, e o desfecho foi avaliado no horizonte nominal de seis meses. A correção pelo colete foi obtida transversalmente na anamnese inicial pela comparação momentânea da curvatura sem e com colete rígido. Essa medida percentual foi tratada como possível marcador de maleabilidade e corrigibilidade imediata, e não como evidência de ausência de componente estrutural, efeito causal ou manutenção garantida da correção.

> O desfecho principal foi a mudança, em graus, entre a maior magnitude de Cobb aos seis meses e o maior Cobb basal entre as regiões torácica proximal, torácica e lombar. Valores negativos indicaram redução radiográfica. Como a fonte contém apenas a maior magnitude final, os máximos basal e final podem corresponder a regiões diferentes. O desfecho secundário foi melhora radiográfica de pelo menos 5°, definida por `delta ≤ −5°`; esse limiar não foi interpretado automaticamente como melhora clínica em sintomas ou função.

> A especificação de dez preditores foi preservada após o congelamento documentado do plano prognóstico. Como a mesma especificação já havia sido explorada nos dados, não foi denominada “a priori”. O Cobb basal, embora componha o desfecho, não integra o modelo principal; sua inclusão será examinada em análise de sensibilidade predefinida para esta revisão, sem alterar retrospectivamente o modelo principal.

## Informações ainda ausentes

- origem, cenário assistencial, período de recrutamento, delineamento e critérios de elegibilidade;
- marco temporal exato, janela permitida e distribuição real até a radiografia de seis meses;
- fórmula percentual exata de `correcao_colete`, identificação das curvas pareadas e relação de `dif_colete` com as imagens sem/com colete;
- tipo/modelo, confecção, ajuste e tempo de uso do colete antes da radiografia transversal;
- protocolo S4D, dose/frequência, tratamentos concomitantes e adesão ao colete/exercícios;
- condição radiográfica detalhada, posicionamento, equipamento, avaliadores, cegamento, repetição e confiabilidade;
- regra de aquisição de idade e sexo; protocolo de altura/peso;
- operacionalização da categoria `flexibilidade` e sua relação com `correcao_colete`;
- detalhes da classificação Lenke e Risser e justificativa do limiar de escoliômetro estritamente maior que 10°;
- perdas de seguimento e cobertura da população elegível do serviço.

Essas ausências são pendências de documentação. Nenhuma delas reabre a temporalidade basal já confirmada da correção pelo colete.

