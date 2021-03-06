# Esli russkie bukvi prevratilitis v krakozyabry,
# to File - Reopen with encoding... - UTF-8 - Set as default - OK


#install.packages("foreign")
library("foreign") # ����������� ������ Stata
#install.packages("dplyr")
library("dplyr") # ����������� � �������
#install.packages("erer")
library("erer") # ������ ���������� ��������
#install.packages("vcd")
library("vcd") # ������� ��� ������������ ������
#install.packages("ggplot2")
library("ggplot2") # �������
#install.packages("reshape2")
library("reshape2") # ����������� � �������
#install.packages("AUC")
library("AUC") # ��� ROC ������


# ������ ������
women <- read.dta("womenwk_data.dta")

# ��� �������� ������ R ��������� ������������ ��� ��������� ���������� � ���������
# ��� ��������� ������� ������ R ��� �� ������ :)
options(stringsAsFactors=FALSE)

# ������� �� ����� ������
glimpse(women)

#������� ���������� work
for (i in 1:nrow(women)) women[i,7]  = ifelse(women[i,5]==women[i,6], 1, 0)
for (i in 1:nrow(women)) women[i,7]  = ifelse(is.na(women[i,7]), 0, 1)
names(women) <- c("age","education","married", "children","wagefull","wage", "work")


# ��������� R, ����� ���������� ������� ����������
women <- mutate(women,married=as.factor(married),work=as.factor(work))
summary(women)


# ��������� ������
mosaic(data=women,~married+children+work,shade=TRUE)

# ������-����������
qplot(data=women,x=work,y=age,geom="violin")

# � "���� � �����"
qplot(data=women,x=work,y=age,geom="boxplot")

# ��� �������� ���������� ������� ���������
qplot(data=women,x=age,y=..count..,fill=work,geom="density",position="stack")
qplot(data=women,x=age,y=..count..,fill=work,geom="density",position="fill")



# ���������� ����� � ������ �������
m_logit <- glm(data=women, work~age + education + married + children,
               family=binomial(link="logit"),x=TRUE)
m_probit <- glm(data=women, work~age + education + married + children,
                family=binomial(link="probit"),x=TRUE)

# ������ �� ������ �������
summary(m_logit)
#��� ���������� � �����-������ �������
summary(m_probit)




# ������ �������������� ������� ������ �������������
vcov(m_logit)

# ������ ����� ������ ������ ��� ���������������
newdata_women <- data.frame(women$age, women$education,	women$married,	women$children)
names(newdata_women) <- c("age","education","married", "children")


# ������������ �� ����� ������ 
pr_logit <- predict(m_logit,newdata_women,se=TRUE)
# �������� �������� � ����� ������ ������ � ������ ��������:
newdata_pr <- cbind(newdata_women,pr_logit)
head(newdata_pr) # ������ �� ������ ��������

# �������� ������������� ������� ������������� ������� ������� �������������� ���������
newdata_pr <- mutate(newdata_pr,prob=plogis(fit),
                     left_ci=plogis(fit-1.95*se.fit),
                     right_ci=plogis(fit+1.95*se.fit))
head(newdata_pr) # ������ �� ���������

# ��������� �� ������� ��� �������� ������������� �������� ��� �����������
qplot(data=newdata_pr,x=age,y=prob,geom="line") +
  geom_ribbon(aes(ymin=left_ci,ymax=right_ci),alpha=0.2)


# �������� LR ����
# R ��� ���������� ������ ������� ��������� ���������� ������������ ���������� ������ ����������
# ������� ����� �������, ��� ������������ � �������������� ������
# ����������� �� ������ ������ ������
# �� � ����� ������ �� ������ ���������� � ������� LR �����
# ������� �� ������� �������� ����� ������ t2 ��� ����������� ��������
# � �� ��� ������ �������� � ������� ������
# H0: beta(pclass)=0, beta(fare)=0

# women2 <- data.frame(women$age,women$education,women$married, as.numeric(women$children)==0, women$work)
# names(women2) <- c("age","education","married", "children", "work")
# women2$children <- 0
# 
# 
# 
# # ��������� ������������ ������
# m_logit2 <- glm(data=women2, work ~  age + education + married + children, family=binomial(link="logit"),x=TRUE)
# # �������� LR ����
# lrtest(m_logit,m_logit2)


maBina(m_logit) # ���������� ������� 

# ����������� ���������� ������� �� ���� �������
maBina(m_logit,x.mean = FALSE)

# ������� ���
m_ols <- lm(data=women, as.numeric(work)~age + education + married + children)
summary(m_ols)

# �������� �� �������� ���
pr_ols <- predict(m_ols,newdata_women)
head(pr_ols)

# ROC ������
# ������������� ������� ���������� ��� ��������� ������ ������
pr_t <- predict(m_logit,women,se=TRUE)
# �������� �������� � �������� ������� ������
women <- cbind(women,pr_t)
# �������� ������������� ������� �������������, ����� �������� �����������
women <- mutate(women,prob=plogis(fit))


# ������� ��� ������ ��� ROC ������:
roc.data <- roc(women$prob,women$work)
str(roc.data)

# ��� ������� ��� ������ ������ ���������
# �� ����������� --- ������, �� ��������� --- ���������������� 
# ���������������� = ����� ����� ������������� �������� / ����� ���������� ������
qplot(x=roc.data$cutoffs,y=roc.data$tpr,geom="line", xlab = "����� ���������", ylab = '���� ����� ������������������ ���������� ������')

# �� ����������� --- ������, �� ��������� --- ������� ������������������ ���������
# ������� ����� ������������� ��������� =
# ����� �� ���������� �������� ������������� ����������/����� ����� ������
qplot(x=roc.data$cutoffs,y=roc.data$fpr,geom="line", xlab = "����� ���������", ylab = '���� �� ����� ������������������ �� ���������� ������')

# �� ����������� --- ������� ������������������ ���������
# �� ��������� --- ����������������
qplot(x=roc.data$fpr,y=roc.data$tpr,geom="line", xlab = "���� ����� ������������������ ���������� ������", ylab = '���� �� ����� ������������������ �� ���������� ������', main='ROC ������')


rmarkdown::render("C:/Users/���������/Documents/GitHub/R/logit_probit/logit_probit.Rmd")
