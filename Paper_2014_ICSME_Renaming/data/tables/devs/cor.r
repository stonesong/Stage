cor_text <- function(cor) {
	if (cor$p.value < 0.05) {
		return(paste(round(cor$estimate, digits=2)))
	} else {
		return(paste(round(cor$estimate, digits=2), "*"))
	}
}

files <- list.files(pattern=".csv")
results <- c()
for (file in files ) {
	d <- read.csv(file)
	c_act <- cor.test(d$X.devs[d$active==1],d$X.devsWithRename[d$active==1],method="spearman")
	c_all <- cor.test(d$X.devs,d$X.devsWithRename,method="spearman")
	results <- rbind(results,cbind(cor_text(c_act),cor_text(c_all)))
}
results


