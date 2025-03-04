require(data.table)
require(lattice)
require(dplyr)
require(scales)
require(lubridate)
require(latticeExtra)
options(scipen = 999)

setwd("C:/Users/marcelo.maceno/Documents/projeto_corona")

#############################################################
#DADOS DE CASOS DE COVID                                    #
#############################################################
dados_covid <- fread("https://www.saude.pr.gov.br/sites/default/arquivos_restritos/files/documento/2021-05/informe_epidemiologico_30_05_2021_geral.csv",
                     encoding = 'UTF-8', select = c("IDADE_ORIGINAL","DATA_DIAGNOSTICO","DATA_OBITO"))

dados_covid2 <- dados_covid
dados_covid2$DATA_DIAGNOSTICO <- as.Date(dados_covid2$DATA_DIAGNOSTICO, format="%d/%m/%Y")
dados_covid2$Ano <- format(dados_covid2$DATA_DIAGNOSTICO,"%Y")
dados_covid3 <- subset(dados_covid2, Ano == 2021 & DATA_DIAGNOSTICO > "2021-01-02")
dados_covid3$semana <- epiweek(dados_covid3$DATA_DIAGNOSTICO)
dados_covid3$faixaidade <- cut(dados_covid3$IDADE_ORIGINAL, c(0,59,69,79,Inf))
levels(dados_covid3$faixaidade) <- c("Menores de 60 anos","Entre 60 e 69 anos","Entre 70 e 79 anos","Acima de 80 anos")
ultima_semana <- max(dados_covid3$semana)
dados_covid4 <- dados_covid3

#N�mero de casos de covid para faixas de idade separados por semana
dados_covid_casos <- dados_covid3 %>%
  group_by(faixaidade, semana) %>%
  summarize(incidencia = n()) %>%
  filter(semana != ultima_semana) %>%
  mutate(acum = cumsum(incidencia)) %>%
  mutate(grupo = "casos")

dados_covid_casos <- subset(dados_covid_casos, semana > max(dados_covid_casos$semana)-15)

#N�mero de �bitos por covid separado por semana
dados_covid2 <- dados_covid
dados_covid2$DATA_OBITO <- as.Date(dados_covid2$DATA_OBITO, format="%d/%m/%Y")
dados_covid2$Ano <- format(dados_covid2$DATA_OBITO,"%Y")
dados_covid3 <- subset(dados_covid2, Ano == 2021 & DATA_OBITO > "2021-01-02")
dados_covid3$semana <- epiweek(dados_covid3$DATA_OBITO)
dados_covid3$faixaidade <- cut(dados_covid3$IDADE_ORIGINAL, c(0,59,69,79,Inf))
levels(dados_covid3$faixaidade) <- c("Menores de 60 anos","Entre 60 e 69 anos","Entre 70 e 79 anos","Acima de 80 anos")
dados_covid5 <- dados_covid3

dados_covid_obitos <- dados_covid3 %>%
  group_by(faixaidade, semana) %>%
  summarize(incidencia = n()) %>%
  filter(semana != ultima_semana) %>%
  mutate(acum = cumsum(incidencia)) %>%
  mutate(grupo = "�bitos")

dados_covid_obitos <- subset(dados_covid_obitos, semana > max(dados_covid_obitos$semana)-15)

##############################################################
#DADOS DA VACINA                                             #
##############################################################
dados_vacina <- fread("https://s3-sa-east-1.amazonaws.com/ckan.saude.gov.br/PNI/vacina/uf/2021-05-30/uf%3DPR/part-00000-c6f35be5-568b-4cdc-8a34-55616fec6ab1.c000.csv",
                      encoding = 'UTF-8', select = c("paciente_idade","vacina_dataaplicacao","vacina_descricao_dose"))
dados_vacina$ind <- 1
dados_vacina$vacina_descricao_dose <- as.factor(dados_vacina$vacina_descricao_dose)
dados_vacina <- subset(dados_vacina, vacina_descricao_dose != levels(dados_vacina$vacina_descricao_dose)[3])
dados_vacina$semana <- epiweek(dados_vacina$vacina_dataaplicacao)
dados_vacina$faixaidade <- cut(dados_vacina$paciente_idade, c(0,59,69,79,Inf))
levels(dados_vacina$faixaidade) <- c("Menores de 60 anos","Entre 60 e 69 anos","Entre 70 e 79 anos","Acima de 80 anos")

#Primeira e segunda dose
prim_dose <- levels(dados_vacina$vacina_descricao_dose)[1]
seg_dose <- levels(dados_vacina$vacina_descricao_dose)[2]

#Total de pessoas por faixa et�ria
total80 <- 250630
total70 <- 537275
total60 <- 993908
totalmenos60 <- 4080010 - total80 - total70 - total60

grupos <- c(totalmenos60,total60,total70,total80)
indice <- c("Menores de 60 anos","Entre 60 e 69 anos","Entre 70 e 79 anos","Acima de 80 anos")
dados_vacina$grupos <- grupos[match(dados_vacina$faixaidade, indice)]

#Dados de vacinados para faixas de idade separados por semana
dados_vacina_agrup <- dados_vacina %>%
  group_by(faixaidade, grupos, vacina_descricao_dose, semana)  %>%
  summarize(incidencia = n()) %>%
  filter(semana != ultima_semana) %>%
  mutate(soma = cumsum(incidencia)) %>%
  mutate(perc = soma/grupos) %>%
  mutate(perc2 = label_percent(accuracy = 1)(perc))

dados_vacina_agrup <- subset(dados_vacina_agrup, semana > max(dados_vacina_agrup$semana)-15)

#############################################################
#Gr�ficos                                                   #
#############################################################
dados_covid_uniao <- rbind(dados_covid_casos,dados_covid_obitos)
dados_covid_uniao <- subset(dados_covid_uniao, semana > max(dados_covid_uniao$semana)-15)

#############################################################
#80 anos ou mais                                            #
#############################################################
dados_covid_casos2 <- subset(dados_covid_casos, faixaidade == "Acima de 80 anos")
dados_covid_obitos2 <- subset(dados_covid_obitos, faixaidade == "Acima de 80 anos")
dados_vacina_agrup2 <- subset(dados_vacina_agrup, faixaidade == "Acima de 80 anos")
dados_covid_uniao2 <- subset(dados_covid_uniao, faixaidade == "Acima de 80 anos")

num_vacin_prim_dose <- max(subset(dados_vacina_agrup2, vacina_descricao_dose == prim_dose)$soma)
num_vacin_seg_dose <- max(subset(dados_vacina_agrup2, vacina_descricao_dose == seg_dose)$soma)

png(file="grafico_80anosoumais.png",
    width=10, height=5, units="in", res=500)
obj1 <- xyplot(incidencia ~ semana,
               group = grupo,
               type = "o",
               col = c(gray(0.6),gray(0.4)),
               lty = 1,
               pch = 19,
               cex = 0.9,
               lwd = 2,
               ylab = NULL,
               xlab = "Semana epidemiol�gica",
               xlim = c(max(dados_covid_uniao$semana)-15.2,max(dados_covid_uniao$semana)+0.4),
               ylim = c(0,max(dados_covid_uniao2$incidencia)+100),
               scales = list(x=list(at=(max(dados_covid_uniao$semana)-14):max(dados_covid_uniao$semana), label = dados_covid_casos2$semana),y=list(col=0)),
               data = dados_covid_uniao2,
               par.settings=list(axis.line=list(col=gray(0.6))),
               panel = function(x, y, ...) {
                 panel.xyplot(x, y, ...)
                 panel.text(x=dados_covid_casos2$semana,y=dados_covid_casos2$incidencia, labels = dados_covid_casos2$incidencia, 
                            col = grey(0.2), cex = 0.7, pos = 3, offset = 1)
                 panel.text(x=dados_covid_obitos2$semana,y=dados_covid_obitos2$incidencia, labels = dados_covid_obitos2$incidencia, 
                            col = grey(0.2), cex = 0.7, pos = 3, offset = 1)
                 panel.text(x=dados_covid_casos2$semana[1],y=dados_covid_casos2$incidencia[1], labels = "Casos", 
                            col = grey(0.2), cex = 0.7, pos = 4, offset = -3.5)
                 panel.text(x=dados_covid_obitos2$semana[1],y=dados_covid_obitos2$incidencia[1], labels = "�bitos", 
                            col = grey(0.2), cex = 0.7, pos = 4, offset = -3.5)
                 
               })


obj2 <- xyplot(perc ~ semana,
               group = vacina_descricao_dose,
               type = "o",
               col = c("steel blue","blue"),
               lty = 3,
               pch = 19,
               cex = 0.9,
               ylab = NULL,
               xlim = c(max(dados_covid_uniao$semana)-15.2,max(dados_covid_uniao$semana)+0.4),
               ylim = c(-0.05,1.05),
               scales = list(x=list(at=(max(subset(dados_vacina_agrup2, vacina_descricao_dose == prim_dose)$semana)-14):max(subset(dados_vacina_agrup2, vacina_descricao_dose == prim_dose)$semana), label = subset(dados_vacina_agrup2, vacina_descricao_dose == prim_dose)$semana),y=list(col=0)),
               data = dados_vacina_agrup2,
               par.settings=list(axis.line=list(col=gray(0.6))),
               panel = function(x, y, ...) {
                 panel.xyplot(x, y, ...)
                 panel.text(x=subset(dados_vacina_agrup2, vacina_descricao_dose == prim_dose)$semana,y=subset(dados_vacina_agrup2, vacina_descricao_dose == prim_dose)$perc, labels = subset(dados_vacina_agrup2, vacina_descricao_dose == prim_dose)$perc2, 
                            col = "steel blue", cex = 0.7, pos = 3, offset = 0.6)
                 panel.text(x=subset(dados_vacina_agrup2, vacina_descricao_dose == seg_dose)$semana,y=subset(dados_vacina_agrup2, vacina_descricao_dose == seg_dose)$perc, labels = subset(dados_vacina_agrup2, vacina_descricao_dose == seg_dose)$perc2, 
                            col = "blue", cex = 0.7, pos = 3, offset = 0.6)
                 panel.text(x=subset(dados_vacina_agrup2, vacina_descricao_dose == prim_dose)$semana[1],y=subset(dados_vacina_agrup2, vacina_descricao_dose == prim_dose)$perc[1], labels = "1� dose", 
                            col = "steel blue", cex = 0.7, pos = 2, offset = 1)
                 panel.text(x=subset(dados_vacina_agrup2, vacina_descricao_dose == seg_dose)$semana[1],y=subset(dados_vacina_agrup2, vacina_descricao_dose == seg_dose)$perc[1], labels = "2� dose", 
                            col = "blue", cex = 0.7, pos = 2, offset = 1)
               })

doubleYScale(obj1,obj2)

update(trellis.last.object(),
       par.settings = simpleTheme(col = c(gray(1), gray(1))))
dev.off()

#############################################################
#70 anos ou mais                                            #
#############################################################
dados_covid_casos3 <- subset(dados_covid_casos, faixaidade == "Entre 70 e 79 anos")
dados_covid_obitos3 <- subset(dados_covid_obitos, faixaidade == "Entre 70 e 79 anos")
dados_vacina_agrup3 <- subset(dados_vacina_agrup, faixaidade == "Entre 70 e 79 anos")
dados_covid_uniao3 <- subset(dados_covid_uniao, faixaidade == "Entre 70 e 79 anos")

dados_vacina_agrup3 <- rbind(subset(dados_vacina_agrup3, vacina_descricao_dose == prim_dose),
                             subset(dados_vacina_agrup3, vacina_descricao_dose == seg_dose)[7:nrow(subset(dados_vacina_agrup3, vacina_descricao_dose == seg_dose)),])


num_vacin_prim_dose <- max(subset(dados_vacina_agrup3, vacina_descricao_dose == prim_dose)$soma)
num_vacin_seg_dose <- max(subset(dados_vacina_agrup3, vacina_descricao_dose == seg_dose)$soma)

# 70 a 79 anos
### Nesta faixa de idade t�m-se `r ponto(total70)` pessoas. At� a semana epidemiol�gica `r max(dados_vacina_agrup2$semana)`, segundo dados obtidos do [Minist�rio da Sa�de](https://opendatasus.saude.gov.br/dataset/covid-19-vacinacao), foram vacinadas `r ponto(num_vacin_prim_dose)` pessoas com a 1� dose e `r ponto(num_vacin_seg_dose)` pessoas com a 2� dose no estado do Paran�.

png(file="grafico_70anos.png",
    width=10, height=5, units="in", res=500)
obj1 <- xyplot(incidencia ~ semana,
               group = grupo,
               type = "o",
               col = c(gray(0.6),gray(0.4)),
               lty = 1,
               pch = 19,
               cex = 0.9,
               lwd = 2,
               ylab = NULL,
               xlab = "Semana epidemiol�gica",
               xlim = c(0.2,max(dados_vacina_agrup3$semana)+0.4),
               ylim = c(0,max(dados_covid_uniao3$incidencia)+200),
               scales = list(y=list(col=0)),
               data = dados_covid_uniao3,
               par.settings=list(axis.line=list(col=gray(0.6))),
               panel = function(x, y, ...) {
                 panel.xyplot(x, y, ...)
                 panel.text(x=dados_covid_casos3$semana,y=dados_covid_casos3$incidencia, labels = dados_covid_casos3$incidencia, 
                            col = grey(0.2), cex = 0.7, pos = 3, offset = 1)
                 panel.text(x=dados_covid_obitos3$semana,y=dados_covid_obitos3$incidencia, labels = dados_covid_obitos3$incidencia, 
                            col = grey(0.2), cex = 0.7, pos = 3, offset = 1)
                 panel.text(x=dados_covid_casos3$semana[1],y=dados_covid_casos3$incidencia[1], labels = "Casos", 
                            col = grey(0.2), cex = 0.7, pos = 4, offset = -3.5)
                 panel.text(x=dados_covid_obitos3$semana[1],y=dados_covid_obitos3$incidencia[1], labels = "�bitos", 
                            col = grey(0.2), cex = 0.7, pos = 4, offset = -3.5)
                 
               })


obj2 <- xyplot(perc ~ semana,
               group = vacina_descricao_dose,
               type = "o",
               col = c("steel blue","blue"),
               lty = 3,
               pch = 19,
               cex = 0.9,
               ylab = NULL,
               ylim = c(-0.05,1.1),
               scales = list(x=list(at=dados_covid_casos3$semana, label = dados_covid_casos3$semana),y=list(col=0)),
               data = dados_vacina_agrup3,
               par.settings=list(axis.line=list(col=gray(0.6))),
               panel = function(x, y, ...) {
                 panel.xyplot(x, y, ...)
                 panel.text(x=subset(dados_vacina_agrup3, vacina_descricao_dose == prim_dose)$semana,y=subset(dados_vacina_agrup3, vacina_descricao_dose == prim_dose)$perc, labels = subset(dados_vacina_agrup3, vacina_descricao_dose == prim_dose)$perc2, 
                            col = "steel blue", cex = 0.7, pos = 3, offset = 0.6)
                 panel.text(x=subset(dados_vacina_agrup3, vacina_descricao_dose == seg_dose)$semana,y=subset(dados_vacina_agrup3, vacina_descricao_dose == seg_dose)$perc, labels = subset(dados_vacina_agrup3, vacina_descricao_dose == seg_dose)$perc2, 
                            col = "blue", cex = 0.7, pos = 3, offset = 0.6)
                 panel.text(x=subset(dados_vacina_agrup3, vacina_descricao_dose == prim_dose)$semana[1],y=subset(dados_vacina_agrup3, vacina_descricao_dose == prim_dose)$perc[1], labels = "1� dose", 
                            col = "steel blue", cex = 0.7, pos = 2, offset = 1)
                 panel.text(x=subset(dados_vacina_agrup3, vacina_descricao_dose == seg_dose)$semana[1],y=subset(dados_vacina_agrup3, vacina_descricao_dose == seg_dose)$perc[1], labels = "2� dose", 
                            col = "blue", cex = 0.7, pos = 2, offset = 1)
               })

doubleYScale(obj1,obj2)

update(trellis.last.object(),
       par.settings = simpleTheme(col = c(gray(1), gray(1))))
dev.off()

#############################################################
#60 a 69 anos                                               #
#############################################################
dados_covid_casos4 <- subset(dados_covid_casos, faixaidade == "Entre 60 e 69 anos")
dados_covid_obitos4 <- subset(dados_covid_obitos, faixaidade == "Entre 60 e 69 anos")
dados_vacina_agrup4 <- subset(dados_vacina_agrup, faixaidade == "Entre 60 e 69 anos")
dados_covid_uniao4 <- subset(dados_covid_uniao, faixaidade == "Entre 60 e 69 anos")

dados_vacina_agrup4 <- rbind(subset(dados_vacina_agrup4, vacina_descricao_dose == prim_dose),
                             subset(dados_vacina_agrup4, vacina_descricao_dose == seg_dose)[7:nrow(subset(dados_vacina_agrup4, vacina_descricao_dose == seg_dose)),])


num_vacin_prim_dose <- max(subset(dados_vacina_agrup4, vacina_descricao_dose == prim_dose)$soma)
num_vacin_seg_dose <- max(subset(dados_vacina_agrup4, vacina_descricao_dose == seg_dose)$soma)

# 60 a 69 anos
### Nesta faixa de idade t�m-se `r ponto(total60)` pessoas. At� a semana epidemiol�gica`r max(dados_vacina_agrup4$semana)`, segundo dados obtidos do [Minist�rio da Sa�de](https://opendatasus.saude.gov.br/dataset/covid-19-vacinacao), foram vacinadas `r ponto(num_vacin_prim_dose)` pessoas com a 1� dose e `r ponto(num_vacin_seg_dose)` pessoas com a 2� dose no estado do Paran�.

png(file="grafico_60anos.png",
    width=10, height=5, units="in", res=500)
obj1 <- xyplot(incidencia ~ semana,
               group = grupo,
               type = "o",
               col = c(gray(0.6),gray(0.4)),
               lty = 1,
               pch = 19,
               cex = 0.9,
               lwd = 2,
               ylab = NULL,
               xlab = "Semana epidemiol�gica",
               xlim = c(0.2,max(dados_vacina_agrup4$semana)+0.4),
               ylim = c(0,max(dados_covid_uniao4$incidencia)+500),
               scales = list(x=list(at=dados_covid_casos4$semana, label = dados_covid_casos4$semana),y=list(col=0)),
               data = dados_covid_uniao4,
               par.settings=list(axis.line=list(col=gray(0.6))),
               panel = function(x, y, ...) {
                 panel.xyplot(x, y, ...)
                 panel.text(x=dados_covid_casos4$semana,y=dados_covid_casos4$incidencia, labels = dados_covid_casos4$incidencia, 
                            col = grey(0.2), cex = 0.7, pos = 3, offset = 1)
                 panel.text(x=dados_covid_obitos4$semana,y=dados_covid_obitos4$incidencia, labels = dados_covid_obitos4$incidencia, 
                            col = grey(0.2), cex = 0.7, pos = 3, offset = 1)
                 panel.text(x=dados_covid_casos4$semana[1],y=dados_covid_casos4$incidencia[1], labels = "Casos", 
                            col = grey(0.2), cex = 0.7, pos = 4, offset = -3.5)
                 panel.text(x=dados_covid_obitos4$semana[1],y=dados_covid_obitos4$incidencia[1], labels = "�bitos", 
                            col = grey(0.2), cex = 0.7, pos = 4, offset = -3.5)
                 
               })


obj2 <- xyplot(perc ~ semana,
               group = vacina_descricao_dose,
               type = "o",
               col = c("steel blue","blue"),
               lty = 3,
               pch = 19,
               cex = 0.9,
               ylab = NULL,
               ylim = c(-0.05,1),
               scales = list(y=list(col=0)),
               data = dados_vacina_agrup4,
               par.settings=list(axis.line=list(col=gray(0.6))),
               panel = function(x, y, ...) {
                 panel.xyplot(x, y, ...)
                 panel.text(x=subset(dados_vacina_agrup4, vacina_descricao_dose == prim_dose)$semana,y=subset(dados_vacina_agrup4, vacina_descricao_dose == prim_dose)$perc, labels = subset(dados_vacina_agrup4, vacina_descricao_dose == prim_dose)$perc2, 
                            col = "steel blue", cex = 0.7, pos = 3, offset = 0.6)
                 panel.text(x=subset(dados_vacina_agrup4, vacina_descricao_dose == seg_dose)$semana,y=subset(dados_vacina_agrup4, vacina_descricao_dose == seg_dose)$perc, labels = subset(dados_vacina_agrup4, vacina_descricao_dose == seg_dose)$perc2, 
                            col = "blue", cex = 0.7, pos = 3, offset = 0.6)
                 panel.text(x=subset(dados_vacina_agrup4, vacina_descricao_dose == prim_dose)$semana[1],y=subset(dados_vacina_agrup4, vacina_descricao_dose == prim_dose)$perc[1], labels = "1� dose", 
                            col = "steel blue", cex = 0.7, pos = 2, offset = 1)
                 panel.text(x=subset(dados_vacina_agrup4, vacina_descricao_dose == seg_dose)$semana[1],y=subset(dados_vacina_agrup4, vacina_descricao_dose == seg_dose)$perc[1], labels = "2� dose", 
                            col = "blue", cex = 0.7, pos = 2, offset = 1)
               })

doubleYScale(obj1,obj2)

update(trellis.last.object(),
       par.settings = simpleTheme(col = c(gray(1), gray(1))))
dev.off()

#############################################################
#Menores de 60 anos                                         #
#############################################################
dados_covid_casos5 <- subset(dados_covid_casos, faixaidade == "Menores de 60 anos")
dados_covid_obitos5 <- subset(dados_covid_obitos, faixaidade == "Menores de 60 anos")
dados_vacina_agrup5 <- subset(dados_vacina_agrup, faixaidade == "Menores de 60 anos")
dados_covid_uniao5 <- subset(dados_covid_uniao, faixaidade == "Menores de 60 anos")

dados_vacina_agrup5 <- rbind(subset(dados_vacina_agrup5, vacina_descricao_dose == prim_dose),
                             subset(dados_vacina_agrup5, vacina_descricao_dose == seg_dose)[4:nrow(subset(dados_vacina_agrup5, vacina_descricao_dose == seg_dose)),])

num_vacin_prim_dose <- max(subset(dados_vacina_agrup5, vacina_descricao_dose == prim_dose)$soma)
num_vacin_seg_dose <- max(subset(dados_vacina_agrup5, vacina_descricao_dose == seg_dose)$soma)

# Abaixo de 60 anos
### Nesta faixa de idade t�m-se `r ponto(totalmenos60)` pessoas (considerados apenas do grupo de risco). At� a semana epidemiol�gica `r max(dados_vacina_agrup5$semana)`, segundo dados obtidos do [Minist�rio da Sa�de](https://opendatasus.saude.gov.br/dataset/covid-19-vacinacao), foram vacinadas `r ponto(num_vacin_prim_dose)` pessoas com a 1� dose e `r ponto(num_vacin_seg_dose)` pessoas com a 2� dose no estado do Paran�.

png(file="grafico_menores60anos.png",
    width=10, height=5, units="in", res=500)
obj1 <- xyplot(incidencia ~ semana,
               group = grupo,
               type = "o",
               col = c(gray(0.6),gray(0.4)),
               lty = 1,
               pch = 19,
               cex = 0.9,
               lwd = 2,
               ylab = NULL,
               xlab = "Semana epidemiol�gica",
               xlim = c(0.2,max(dados_vacina_agrup5$semana)+0.4),
               ylim = c(-1000,max(dados_covid_uniao5$incidencia)+9000),
               scales = list(x=list(at=dados_covid_casos5$semana, label = dados_covid_casos5$semana),y=list(col=0)),
               data = dados_covid_uniao5,
               par.settings=list(axis.line=list(col=gray(0.6))),
               panel = function(x, y, ...) {
                 panel.xyplot(x, y, ...)
                 panel.text(x=dados_covid_casos5$semana,y=dados_covid_casos5$incidencia, labels = dados_covid_casos5$incidencia, 
                            col = grey(0.2), cex = 0.7, pos = 3, offset = 1)
                 panel.text(x=dados_covid_obitos5$semana,y=dados_covid_obitos5$incidencia, labels = dados_covid_obitos5$incidencia, 
                            col = grey(0.2), cex = 0.7, pos = 3, offset = 1)
                 panel.text(x=dados_covid_casos5$semana[1],y=dados_covid_casos5$incidencia[1], labels = "Casos", 
                            col = grey(0.2), cex = 0.7, pos = 4, offset = -3.5)
                 panel.text(x=dados_covid_obitos5$semana[1],y=dados_covid_obitos5$incidencia[1], labels = "�bitos", 
                            col = grey(0.2), cex = 0.7, pos = 4, offset = -3.5)
                 
               })


obj2 <- xyplot(perc ~ semana,
               group = vacina_descricao_dose,
               type = "o",
               col = c("steel blue","blue"),
               lty = 3,
               pch = 19,
               cex = 0.9,
               ylab = NULL,
               ylim = c(-0.05,1),
               scales = list(y=list(col=0)),
               data = dados_vacina_agrup5,
               par.settings=list(axis.line=list(col=gray(0.6))),
               panel = function(x, y, ...) {
                 panel.xyplot(x, y, ...)
                 panel.text(x=subset(dados_vacina_agrup5, vacina_descricao_dose == prim_dose)$semana,y=subset(dados_vacina_agrup5, vacina_descricao_dose == prim_dose)$perc, labels = subset(dados_vacina_agrup5, vacina_descricao_dose == prim_dose)$perc2, 
                            col = "steel blue", cex = 0.7, pos = 3, offset = 0.6)
                 panel.text(x=subset(dados_vacina_agrup5, vacina_descricao_dose == seg_dose)$semana,y=subset(dados_vacina_agrup5, vacina_descricao_dose == seg_dose)$perc, labels = subset(dados_vacina_agrup5, vacina_descricao_dose == seg_dose)$perc2, 
                            col = "blue", cex = 0.7, pos = 3, offset = 0.6)
                 panel.text(x=subset(dados_vacina_agrup5, vacina_descricao_dose == prim_dose)$semana[1],y=subset(dados_vacina_agrup5, vacina_descricao_dose == prim_dose)$perc[1], labels = "1� dose", 
                            col = "steel blue", cex = 0.7, pos = 2, offset = 1)
                 panel.text(x=subset(dados_vacina_agrup5, vacina_descricao_dose == seg_dose)$semana[1],y=subset(dados_vacina_agrup5, vacina_descricao_dose == seg_dose)$perc[1], labels = "2� dose", 
                            col = "blue", cex = 0.7, pos = 2, offset = 1)
               })

doubleYScale(obj1,obj2)

update(trellis.last.object(),
       par.settings = simpleTheme(col = c(gray(1), gray(1))))
dev.off()