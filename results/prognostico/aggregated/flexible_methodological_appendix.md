# Apêndice metodológico — modelagem flexível exploratória

Esta análise foi pré-especificada como exploratória e não altera os modelos congelados nem sustenta conclusões clínicas isoladas.
Foram avaliadas versões contínua e logística por elastic net, com alpha em {0, 0,25, 0,50, 0,75, 1} e 4 valores de lambda em sequência logarítmica.
A avaliação externa usou 10 folds estratificados em 5 repetições e tuning interno em 5 folds.
Medianas, dummies, centros, escalas e nós das splines foram aprendidos somente no treino de cada split.
As interações usaram apenas componentes lineares e foram construídas junto com seus efeitos principais, preservando a hierarquia interpretativa.
A seleção one-SE minimizou RMSE contínuo ou log loss logístico e, em equivalência, favoreceu maior lambda.
O ajuste em toda a coorte foi realizado somente após a avaliação externa e serve apenas para gráficos e hipóteses.
A multiplicidade de componentes, a instabilidade de seleção, a variabilidade das previsões e o caráter pós-dados exigem cautela; nenhum resultado desta análise substitui validação externa ou conclusão clínica.
