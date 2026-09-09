# Parecer científico final — Task 15

Auditoria local concluída em 08/09/2026, America/Sao_Paulo (09/09/2026 UTC). Não é avaliação externa independente.

## Recomendação

O relatório está tecnicamente conciliado e sustenta uma apresentação de **desenvolvimento e avaliação interna condicional à especificação congelada**, com limitações explícitas. **Ainda não está pronto para submissão**: faltam informações dos investigadores sobre origem da coorte, protocolos, ética e declarações do manuscrito. O modelo não está validado externamente nem autorizado para uso clínico individual.

Não foi encontrada falha numérica crítica pendente nos componentes auditados. A exploração histórica não repetida na reamostragem continua sendo fonte concreta de otimismo não quantificado. A resolução desta auditoria foi restringir as alegações ao procedimento atual e registrar alto risco para a avaliação de toda a estratégia histórica; não foi eliminar esse viés nem demonstrar baixo risco global. Se a submissão pretender alegar validação de toda a estratégia histórica, deverá retornar à Task 09, reconstruir as decisões e repetir a seleção dentro da reamostragem, ou obter avaliação independente da equação congelada.

## População, cronologia e decisões preservadas

Foram conciliados 621 registros, 618 após deduplicação e 615 casos completos, com 317 eventos e 298 não eventos. Permanecem dez preditores, 19 parâmetros preditores mais intercepto; delta contínuo principal e melhora radiográfica de pelo menos 5° secundária. CART e flexível são exploratórios.

A correção pelo colete é transversal, basal e disponível na anamnese. Não se reabre suspeita de vazamento temporal. Mantêm-se as três hipercorreções verdadeiras, os dez empates basais e a comparação aprovada entre máximos regionais. A mesma condição radiográfica basal/final está confirmada no plano; faltam os detalhes do protocolo, não a confirmação dessa decisão. O máximo final não identifica necessariamente a mesma curva. Não houve alteração da fonte, coorte, fórmulas principais ou objetos analíticos congelados.

## Evidência numérica e alcance

O script `scripts/audit_scientific_final.R` aprovou 33/33 verificações, registradas em `results/prognostico/revisao/logs/auditoria_numerica_task15.csv`. Recompõe quantis/estimativas e covariância HC3; não apenas compara o texto consigo mesmo. A suíte completa aprovou 11 grupos, incluindo testes do solver contra referências numéricas.

| Componente | Evidência conferida | Interpretação permitida |
|---|---|---|
| Linear fixo | R² corrigido 0,363663; IC95% 0,321830–0,440978; RMSE 4,276347°; IC 3,926723–4,472979° | Desempenho interno condicional, sem erro individual garantido |
| Logístico fixo | AUC 0,848315; IC 0,829075–0,883905; Brier 0,160049; log loss 0,489222 | Discriminação e erro; AUC não é acurácia |
| Bootstrap | 2.000 válidos por modelo; seis IC recompostos com quantil tipo 6 e deslocamento médio | IC aproximados; cobertura local não simulada; sem cobertura da seleção histórica |
| HC3 | Diferença máxima de EP 4,54 × 10⁻¹³; t com 595 gl | Inferência dos coeficientes aparentes; não dos coeficientes pós-shrinkage |
| Pós-shrinkage | Coeficientes e previsões sintéticas recompostos; 50 folds; 20.000 ajustes internos válidos | Procedimento com 200 bootstraps por treino, não teste independente da equação final com 615 pessoas e 2.000 réplicas |
| Conformal | Cobertura interna média 94,8618%; largura 17,4369° | Cobertura empírica das partições estratificadas; sem garantia exata de 95% neste desenho ou em grupos externos |
| CART | 313 cortes primários = 221 contínuos + 92 categóricos; raiz colete 50/50; mediana 49,4186%, amplitude 45,3463–54,8589% | Estabilidade da variável não valida um limiar clínico; intercepto de calibração válido em 49/50 folds |
| Flexível | 100 ajustes externos ridge válidos; 160/5.000 falhas KKT internas contínuas inelegíveis | Hierarquia forte observada nas soluções, não imposta pelo algoritmo |
| Comparações | Diferenças pareadas recompostas; mesmos testes completos; exclusões somente no treino; equivalência delta/Cobb final verificada | Ganhos modestos sem teste formal de superioridade; repetições não independentes |

Os contrastes do colete foram conciliados com a equação pós-shrinkage: +10 pontos percentuais correspondem a −1,19° e OR 2,33, sem IC pós-shrinkage. OR não é risco relativo. Os IC HC3 da figura são explicitamente aparentes. IC de calibração, da média e de previsão individual da equação final continuam indisponíveis; não se inventaram bandas.

## Literatura e afirmações clínicas

As 20 referências existem e são citadas. Os 17 DOI foram resolvidos em metadados Crossref; livro, JMLR e manual rpart foram verificados em fontes editoriais/oficiais. A matriz `bibliografia_verificacao_task15.csv` registra existência, pertinência, fonte e limite de cada referência; o JSON Crossref preserva a consulta. Corrigidos autoria de Riley 2020, nome de Sabrina Donzelli e endereço do livro CART. Acrescentada Xu 2017 e incorporada a referência estrutural do rpart ao texto.

O estudo transversal de Ohrt-Nissen sustenta o racional de corrigibilidade imediata. Xu estudou 488 pacientes, seguimento de pelo menos dois anos e sucesso definido por progressão de até 5°, distinto da redução local de pelo menos 5° em seis meses. Esses estudos não validam o coeficiente, o corte CART ou a manutenção local. A SOSORT contextualiza variabilidade da mensuração manual; 5° não é prova de benefício funcional. Não há recomendação de conduta nem extrapolação além de seis meses.

Fontes metodológicas oficiais: [TRIPOD+AI expandido, 7-Feb-2024](https://www.tripod-statement.org/wp-content/uploads/2024/04/TRIPODAI-Supplement.pdf), [PROBAST+AI, suplemento, tabela 5, páginas 4–6](https://www.probast.org/wp-content/uploads/2025/03/PROBASTAI-Supplementals.pdf). A estrutura foi confrontada com o artigo e a página oficial de downloads. O formulário completo hospedado no BMJ retornou bloqueio HTTP; não se afirma preenchimento certificado desse formulário nem revisão externa.

## Checklists e cobertura do parecer anterior

TRIPOD+AI foi revisto em 52 itens/subitens dos 27 itens, com evidência, localização no QMD, fonte e pendências. “Reportado” significa presença de informação, não aprovação científica. PROBAST+AI discrimina quatro domínios de desenvolvimento, quatro de avaliação e seis avaliações de aplicabilidade; o arquivo adicional traz 16 + 18 perguntas de sinalização com rótulos abreviados locais. Predominam julgamentos incertos por documentação insuficiente. A ausência de validação externa não foi usada automaticamente como alto risco interno.

| Núcleo do parecer atualizado | Cobertura e verificação final |
|---|---|
| Estimando, colete, máximos, hipercorreções | Decisões Tasks 02/13 preservadas; §§2–4 do relatório conciliados |
| Solver, hierarquia e reexecução | Tasks 04/05, testes e resíduos KKT dos ajustes selecionados; §11.2 |
| CART e folhas | Tasks 06/07, extração primária e denominadores; §8 e figura/tabela |
| Pressupostos, HC3, GVIF, separação | Task 08, cálculo HC3 independente e limites; §5.2 |
| Otimismo, IC, shrinkage e incerteza | Task 09, seis IC e procedimento conferidos; §§5.3, 6, 7, 11.1 e 11.3 |
| Influência, Cobb basal e comparadores | Task 10, pareamento, exclusões no treino e identidade algébrica; §9 |
| Coorte e amostra | Task 11, contagens e cenários condicionais; §§3 e 5.1 |
| Figuras, linguagem e apresentação | Tasks 12–14; HTML renderizado, 12 figuras incorporadas, inspeção móvel e desktop |
| Referências e autoavaliação | Task 03 e auditoria atual; bibliografia, §§11.4–11.5 e CSVs |

## Impedimentos concretos e limites remanescentes

O registro completo e classificado está em `results/prognostico/revisao/logs/pendencias_finais.csv`, com trecho, impacto, task de origem e ação verificável. Antes do envio, os investigadores devem completar origem, elegibilidade, centros, período, perdas anteriores à planilha, janela real, protocolos de mensuração/tratamento e documentação ética. Devem declarar financiamento, conflitos, registro/protocolo, acesso a dados/código e participação de pacientes; ausência de informação não prova ausência de aprovação ou procedimento.

O manuscrito também requer resumo conforme a revista, confronto com modelos prognósticos existentes e discussão de desigualdades. A falta de avaliação externa e de utilidade impede uso clínico, mas não impede por si a submissão honesta de um estudo de desenvolvimento. Não há solicitação de nova análise para favorecer resultados. Novas informações que revelem seleção, agrupamento ou mensuração diferentes devem motivar revisão das Tasks 02/08/09/11 antes de afirmar baixo risco.

As correções locais encerraram os problemas críticos de interpretação identificados no relatório, sem resolver artificialmente limitações da coorte. A recomendação é completar documentação e preparar o manuscrito para revisão científica humana, mantendo todas essas restrições. Não houve publicação, commit ou push.
