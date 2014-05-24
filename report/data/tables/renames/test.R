
d<-table(c(rep(10, 3), rep(9, 3), rep(8, 5)))

barplot(d,  main=main[4], xlab='RSSI', xlim=c(0, 4), ylim=c(0, 32))