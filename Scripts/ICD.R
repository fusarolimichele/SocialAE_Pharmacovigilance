# Introduction ----------------------------------------------------------------
# This code explores the putative mechanisms by which
# anti-Parkinson drugs can cause gambling, compulsive shopping,
# impulse-control disorder and hypersexuality
# Fusaroli Michele, 2019, SDR of Social ADR.

#libraries --------------------------------------------------------------------
library(tidyverse)
library(ggplot2)


#ICD_Char_df ------------------------------------------------------------------
# Describe the subpopulation that takes DAA, considering ICD
ICD_Code_list <- c("G04BE07, N04BC07", "N04BC01, G02CB01","N04BC06, G02CB03",
            "G02CB02, N02CA07","N04BC02", "N04BC08", "N04BC05",
            "N04BC04", "N04BC09")
ICD_df <- ICSR_df
ICD_df <- ICD_df %>%
  filter(str_detect(ICD_df$`Suspect Product Active Ingredients Code`, ICD_Code_list) == TRUE)

ICD_Char_df <- as.data.frame(matrix(ncol = 14, nrow = 1), stringsAsFactors = FALSE)
colnames(ICD_Char_df) <- c("Evento Avverso","Set","Num","Num(%)","F(%)","M(%)","HCP(%)","C(%)",
                           "età media","età mediana", "età DS", "peso media","peso mediana", "peso DS")

Descr <- function(ae, set, df){
  Num <- nrow(df)
  Np <- round(Num/nrow(ICD_df)*100,2)
  F_num <-sum(df$Sex == "Female")
  Fem <- paste(round((F_num/Num)*100,2))
  M_num <- sum(df$Sex == "Male")
  Mal <- paste(round((M_num/Num)*100,2))
  HCP_num <- sum(df$`Reporter Type` == "Healthcare Professional")
  HCP <- paste(round((HCP_num/Num)*100,2))
  PZ_num <- sum(df$`Reporter Type` == "Consumer")
  PZ <- paste(round((PZ_num/Num)*100,2))
  Age <- round(mean(df$`Age (YR)`, na.rm = TRUE),0)
  Med_A <- round(median(df$`Age (YR)`, na.rm = TRUE),0)
  Age_sd <- round(sd(df$`Age (YR)`, na.rm = TRUE),0)
  Weight <- round(mean(df$`Weight (KG)`, na.rm = TRUE),1)
  Med_W <- round(median(df$`Weight (KG)`, na.rm = TRUE),1)
  Weight_sd <- round(sd(df$`Weight (KG)`, na.rm = TRUE),1)
  dataf <- deparse(substitute(df))
  new_row <- c(ae,set,Num,Np,Fem,Mal,HCP,PZ,Age, Med_A, Age_sd,Weight,Med_W, Weight_sd)
  return(new_row)
}

Describe <- function(AE){
  ae <- AE
  set <- "Case"
  x <-subset(ICD_df, str_detect(ICD_df$Reactions, AE) == TRUE)
  row_Case <- Descr(ae,set,x)
  y <-subset(ICD_df, str_detect(ICD_df$Reactions, AE) == FALSE)
  set <- "Non_Case"
  row_NonCase <- Descr(ae,set,y)
  ICD_Char_df <- rbind(ICD_Char_df, row_NonCase)
  ICD_Char_df <- rbind(ICD_Char_df, row_Case)
}

ICD_Char_df <- Describe("")
ICD_Char_df <- Describe("gambling")
ICD_Char_df <- ICD_Char_df[-1,]
ICD_Char_df <- Describe("compulsive shopping")
ICD_Char_df <- Describe("hypersexuality")
ICD_Char_df <- Describe("impulse-control disorder")
write.csv(ICD_Char_df, file = "Population characteristics/ICD_Char_df.csv")

# Boxplots---------------------------------------------------------------------
AE_list <- c("gambling", "compulsive shopping", "hypersexuality","impulse-control disorder")
pdf("Visualization/Boxplots_ICD.pdf")
for (i in AE_list){
  x <- ROR_df %>%
    filter(AE == i) %>%
    filter(ROR_m > 1) %>%
    filter(Drug_Name %in% c("apomorphine", "bromocriptine","cabergoline",
                            "lisuride","pergolide","piribedil","pramipexole",
                            "ropinirole","rotigotine"))
  print(ggplot(data=x) +
          geom_boxplot(mapping=aes(x=reorder(Drug_Name, -ROR), middle = ROR, lower = ROR_m, ymin=ROR_m, upper = ROR_M, ymax=ROR_M), stat = "identity") +
          labs(title    = i) +
          xlab("Drug") +
          geom_label(aes(x = reorder(`Drug_Name`, -ROR), ROR, label = ROR), size = 1, colour = "red", fill="white") +
          coord_flip())
}
dev.off()

# Occupancy matrix-------------------------------------------------------------
ICD_PhD <- read_delim("Databases Used/ICD_PhD.csv", 
                      ";", escape_double = FALSE, trim_ws = TRUE)
h <- matrix(nrow = 9, ncol = 17)
rownames(h) <- c("apomorphine", "bromocriptine","cabergoline",
                 "lisuride","pergolide","piribedil","pramipexole",
                 "ropinirole","rotigotine")
colnames(h) <- c("ADRA1a","ADRA1b","ADRA1d","ADRA2a","ADRA2b","ADRA2c",
                 "D1","D2","D3","D4","D5","5HT1a","5HT1b","5HT1d",
                 "5HT2a","5HT2b","5HT2c")
for (x in rownames(h)){
  for (y in colnames(h)){
    print(paste(x,y))
    h[[x,y]] <- ICD_PhD$Occupancy[ICD_PhD$Substance==x & ICD_PhD$Target==y]
    if(is.na(h[x,y])){h[[x,y]] <- 0}
  }
}
png("Visualization/Occupancy.png")
superheat(h,
          title = "Occupancy",
          heat.pal = c("white","yellow", "green", "blue"),
          heat.pal.values = c(0, 0.25, 0.5, 1),
          heat.col.scheme = "red",
          heat.lim = c(0,100),
          bottom.label.text.angle = 90,
          bottom.label.text.size = 2,
          bottom.label.size = 0.1,
          force.left.label = TRUE,
          left.label.text.size = 4,
          left.label.size = 0.4,
          force.grid.hline = TRUE,
          grid.hline.col = "gray",
          grid.vline.col = "gray",
          heat.na.col= "white",
          X.text = h,
          X.text.size = 2,
          left.label.text.alignment = "right",
          pretty.order.rows = TRUE,
          left.label = "variable",
          row.title = "Substance",
          row.title.size = 6,
          column.title = "Target",
          column.title.size = 6)
dev.off()

# Linear Regression Model for ICD ---------------------------------------------

LRM <- function(df, PhD_df){
  Targets_list <- as.list(unique(PhD_df$Target))
  Action_list <- as.list(unique(PhD_df$Action))
  LRM_df <- as.data.frame(matrix(nrow=0, ncol=8))
  colnames(LRM_df) <- c("AE", "Target","Action", "Intercept", "Slope", "SE", "p_value", "Pearson")
  pdf("Visualization/ICD_LRM.pdf")
  for (e in AE_list){
    x <- subset(df, df$AE == e)
    x <- subset(x, is.na(x$ROR) == FALSE)
    x <- subset(x, is.infinite(x$ROR) == FALSE)
    for (t in Targets_list) {
      y <- subset(PhD_df, `Target` == t) %>%
        rename(Drug_Name = Substance)
      z1 <- left_join(x,y, by ="Drug_Name")
      z1 <- subset(z1, is.na(z1$Occupancy) == FALSE)
      for (m in Action_list){
        z <- subset(z1, z1$Action == m)
        if (dim(z)[1] >= 4){
          Intercept <- round(coefficients(summary(lm(z$ROR~z$Occupancy)))[1],2)
          Slope <- round(coefficients(summary(lm(z$ROR~z$Occupancy)))[2],2)
          SE <- round(coefficients(summary(lm(z$ROR~z$Occupancy)))[4],2)
          p_value <- round(coefficients(summary(lm(z$ROR~z$Occupancy)))[8],6)
          P <- cor.test(z$ROR, z$Occupancy, method="pearson")
          Pearson <- round(P$estimate,2)
          LRM_df[nrow(LRM_df)+1,] <- c(e, t, m, Intercept, Slope, SE, p_value, Pearson)
          if (p_value <= 1){
            plot1 <- ggplot(data = z, aes(x=z$Occupancy, y=z$ROR, main= paste("ROR ~ ", t))) +
              geom_smooth(method ="lm") +
              geom_point(aes(color = z$Drug_Name)) +
              xlab("Occupancy") +
              ylab("ROR")
            title <- ggdraw() + draw_label(paste(e," ~ ", t, "[",m,"]"), fontface = "bold")
            results <- ggdraw() + draw_label(paste("Intercept: ", Intercept,
                                                   "     Slope: ", Slope,
                                                   "     SE: ", SE,
                                                   "     p-value: ", p_value,
                                                   "     Pearson: ", Pearson), size = 10)
            print(plot_grid(title, plot1, results, ncol=1, rel_heights=c(0.1, 1, 0.1)))
          }
        }
      }
    }
  }
  dev.off()
  LRM_df <- LRM_df %>%
    arrange(p_value) %>%
    mutate(Rank = rank(p_value))
  LRM_df <- LRM_df %>%
    mutate(BH20 = (Rank/nrow(LRM_df))*0.20) %>%
    mutate(Sign20 = (p_value <= BH20))
  ICD_occ_df <- LRM_df
  write_csv2(ICD2_occ_df, "Results/ICD_occ.csv")
}

LRM(ROR_df, ICD_PhD)

# Pearson significance --------------------------------------------------------
ICD_occ <- read_delim("Results/ICD_occ.csv", 
                      ";", escape_double = FALSE, trim_ws = TRUE)
plot_pearson <- function(event){
  x <- ICD_occ %>% 
    arrange(Pearson) %>%
    filter(AE == event)
  ggplot(data = x, mapping = aes(x = Pearson, y = reorder(Target,Pearson), color = Sign20)) +
    geom_point() +
    geom_text(aes(label= p_value),hjust=0, vjust=0) +
    coord_cartesian(xlim = c(-1, 1)) +
    ggtitle(event)
}

png("Visualization/gambling.png")
print(plot_pearson("gambling"))
dev.off()

png("Visualization/compulsive shopping.png")
print(plot_pearson("compulsive shopping"))
dev.off()

png("Visualization/hypersexuality.png")
print(plot_pearson("hypersexuality"))
dev.off()

png("Visualization/impulse-control disorder.png")
print(plot_pearson("impulse-control disorder"))
dev.off()


# Descriptive plots -----------------------------------------------------------

draw_sex <- function(df){
  x <- df
  x <- x %>%
    group_by(Sex) %>%
    count() %>%
    ungroup() %>%
    mutate(per = `n`/sum(`n`)) %>%
    arrange(desc(Sex)) %>%
    mutate(label = scales::percent(per)) %>%
    mutate(r = rank(desc(n)))
  p <- ggplot(data = subset(x, r < 7)) +
    geom_bar(aes(x="", y = per, fill = Sex), stat = "identity", width = 0.5) +
    geom_text(aes(x=1, y = cumsum(per) - per/2, label = label), size = 5, color = "white") +
    ggtitle("Genere dei pazienti") +
    theme(plot.title = element_text(hjust = 0.5), axis.title.x = element_blank(), axis.ticks.x = element_blank()) +
    labs(y = "Frazione") +
    scale_fill_manual(name = "Genere", values = c("#E06B6F","#1282A2","#93905B"), labels = c("Femmine", "Maschi", "Non specificato")
    )
  return(p)
}
DAA <- ICD_df

prepare <- function(df,arg){
  x <- df
  l <- deparse(substitute(df))
  l1 <- deparse(substitute(arg))
  x <- x %>%
    group_by(x[[arg]]) %>%
    count() %>%
    ungroup() %>%
    mutate(per = `n`/sum(`n`))
  x <- x %>%
    rename("arg" = "x[[arg]]")
  x <- x %>%
    arrange(desc(arg)) %>%
    mutate(label = scales::percent(per)) %>%
    mutate(r = rank(desc(n))) %>%
    mutate(df = l) %>%
    mutate(text_pos = cumsum(per) - per/2)
}

x <- as.data.frame(matrix(nrow=1,ncol = 6))
j <- prepare(DAA,"Sex")
y <- prepare(Gioco_Compulsivo,"Sex")
w <- prepare(Shopping_Compulsivo,"Sex")
z <- prepare(Ipersessualità,"Sex")
k <- prepare(ICD,"Sex")
x <- do.call(rbind, list(j,y,w,z,k))
p <- ggplot(data = x) +
    geom_bar(aes(x= df, y = per, fill = arg), stat = "identity", width = 0.8) +
    geom_text(aes(x=df, y = text_pos, label = label), size = 7, color = "white") +
    theme(plot.title = element_text(hjust = 0.5), axis.title.x = element_blank(),
          axis.text.x = element_text(size = 15, angle = 30),
          axis.text.y = element_blank(),axis.title.y = element_blank(),
          axis.ticks.y = element_blank(),legend.text = element_text(size = 10)) +
    scale_fill_manual(name = NULL, values = c("#E06B6F","#1282A2","#93905B"), labels = c("Femmine", "Maschi", "Non specificato")
    )
pdf("Population characteristics/DAA/Sex.pdf")
p
dev.off()

x <- as.data.frame(matrix(nrow=1,ncol = 6))
j <- prepare(DAA,"Reporter Type")
y <- prepare(Gioco_Compulsivo,"Reporter Type")
w <- prepare(Shopping_Compulsivo,"Reporter Type")
z <- prepare(Ipersessualità,"Reporter Type")
k <- prepare(ICD,"Reporter Type")
x <- do.call(rbind, list(j,y,w,z,k))
p <- ggplot(data = subset(x, r < 7)) +
  geom_bar(aes(x=df, y = per, fill = arg), stat = "identity", width = 0.8) +
  geom_text(aes(x=df, y = text_pos, label = label), size = 7, color = "white") +
  theme(plot.title = element_text(hjust = 0.5), axis.title.x = element_blank(),
        axis.text.x = element_text(size = 15, angle = 30),
        axis.text.y = element_blank(),axis.title.y = element_blank(),
        axis.ticks.y = element_blank(),legend.text = element_text(size = 10)) +
  scale_fill_manual(values = c("#EFC000FF","#0073C2FF","#605E3C"), name = NULL, labels = c("Consumatore", "Professionista sanitario", "Non specificato")
  )
pdf("Population characteristics/DAA/Reporter.pdf")
p
dev.off()

x <- as.data.frame(matrix(nrow=1,ncol = 6))
j <- prepare(DAA,"Serious")
y <- prepare(Gioco_Compulsivo,"Serious")
w <- prepare(Shopping_Compulsivo,"Serious")
z <- prepare(Ipersessualità,"Serious")
k <- prepare(ICD,"Serious")
x <- do.call(rbind, list(j,y,w,z,k))
p <- ggplot(data = x) +
  geom_bar(aes(x=df, y = per, fill = arg), stat = "identity", width = 0.8) +
  geom_text(aes(x=df, y = text_pos, label = label), size = 7, color = "white") +
  theme(plot.title = element_text(hjust = 0.5), axis.title.x = element_blank(),
        axis.text.x = element_text(size = 15, angle = 30),
        axis.text.y = element_blank(),axis.title.y = element_blank(),
        axis.ticks.y = element_blank(),legend.text = element_text(size = 10)) +
  scale_fill_manual(values = c("#95C623","#E55812",""), name = NULL, labels = c("Non grave", "Grave", "Non specificato")
  )
pdf("Population characteristics/DAA/Serious.pdf")
p
dev.off()

# pharmacodynamics-------------------------------------------------------------

pdf("Visualization/pCHEMBL_graph.pdf")
ggplot(data = ICD_PhD) +
  geom_point(mapping = aes(x = Target, y = pCHEMBL, group = Substance, color =Substance), size =1) +
  geom_line(mapping = aes(x = Target, y = pCHEMBL, group = Substance, color =Substance), size =0.5) +
  coord_polar() +
  facet_wrap(~Substance, nrow = 3) +
  ggtitle("AFFINITY") +
  theme(axis.line=element_blank(),
        axis.text.y=element_blank(),
        axis.text.x = element_text(size = 5.5),
        axis.ticks=element_blank(),
        axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        plot.title = element_text(hjust = 0.5))
dev.off()

pdf("Visualization/Occupancy_graph.pdf")
ggplot(data = ICD_PhD) +
  geom_point(mapping = aes(x = Target, y = Occupancy, group = Substance, color =Substance), size =1) +
  geom_line(mapping = aes(x = Target, y = Occupancy, group = Substance, color =Substance), size =0.5) +
  coord_polar() +
  facet_wrap(~Substance, nrow = 3) +
  ggtitle("OCCUPANCY") +
  theme(axis.line=element_blank(),
        axis.text.y=element_blank(),
        axis.text.x = element_text(size = 5.5),
        axis.ticks=element_blank(),
        axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        plot.title = element_text(hjust = 0.5))
dev.off()

D3 <- ICD_PhD
D3 <- D3 %>%
  filter(Target == "D3")
pdf("Visualization/D3_affinity.pdf")
ggplot(data = D3) +
  geom_col(aes(x=reorder(Substance,pCHEMBL), y = pCHEMBL, color = Substance), size =2)
dev.off()
pdf("Visualization/D3_occupancy.pdf")
ggplot(data = D3) +
  geom_col(aes(x=reorder(Substance,Occupancy), y = Occupancy, color = Substance), size =2)
dev.off()
