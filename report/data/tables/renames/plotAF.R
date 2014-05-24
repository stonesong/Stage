i=1:5
main = paste ("Location ", i)

#windows()
par(mfrow=c(3,2))

AF1 <- read.csv2("C:/Users/Stonesong/Documents/StageM2/Stage/report/data/tables/renames/jenkinsAF.csv", header=T)
AF2 <- read.csv2("C:/Users/Stonesong/Documents/StageM2/Stage/report/data/tables/renames/jqueryAF.csv", header=T)
AF3 <- read.csv2("C:/Users/Stonesong/Documents/StageM2/Stage/report/data/tables/renames/phpunitAF.csv", header=T)
AF4 <- read.csv2("C:/Users/Stonesong/Documents/StageM2/Stage/report/data/tables/renames/pyramidAF.csv", header=T)
AF5 <- read.csv2("C:/Users/Stonesong/Documents/StageM2/Stage/report/data/tables/renames/railsAF.csv", header=T)

barplot(AF1$pafr, ylim=c(0,100), col=c(2,"darkorange1",7,7,7,7,7,7,7,7,7,"darkorange1",7,7,7,7,7), names.arg=AF1$period, main="Jenkins", las=2)
barplot(AF2$pafr, ylim=c(0,100), col=c(2,7,7,7,7,7,7,7,7,7,7,7), names.arg=AF2$period, main="JQuery", las=2)
barplot(AF3$pafr, ylim=c(0,100), col=c(2,7,7,"darkorange1"), names.arg=AF3$period, main="PHPUnit", las=2)
barplot(AF4$pafr, ylim=c(0,100), col=c(2,7,7,7,7,7), names.arg=AF4$period, main="Pyramid", las=2)
barplot(AF5$pafr, ylim=c(0,100), col=c(2,7,7,7,"darkorange1","darkorange1",7,7,7,"darkorange1",7,7,"darkorange1"), names.arg=AF5$period, main="Rails", las=2)
