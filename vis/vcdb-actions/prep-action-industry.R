library(verisr)
library(Hmisc) # for capitalize
# director with VCDB incidents in JSON format
vcdb <- json2veris("github/vcdb")
mat <- veris2matrix(vcdb, unknown=T)
nmat <- colnames(mat)
data(industry2)
ind <- getenum(vcdb, "victim.industry2")
ind <- merge(ind, industry2, all.x=T, by.x="enum", by.y="code")
ind <- tail(ind[(!is.na(ind$short)), ], 10)
ind <- ind[with(ind, order(x, decreasing=T)), ]

act.names <- nmat[grep('action.*.variety', nmat)]
foo <- colSums(mat[ , act.names])
foo <- head(sort(foo, decreasing=T), 10)
summary <- paste(foo, "of", nrow(mat))
foo <- round(foo/nrow(mat), 3)
out <- data.frame(label=names(foo), ct=as.vector(foo), ind="Overall", summary=summary)

out2 <- do.call(rbind, lapply(seq(nrow(ind)), function(i) {
  filter <- getfilter(vcdb, list("victim.industry2"=ind$enum[i]))
  print(c(as.character(ind$short)[i], sum(filter)))
  foo <- colSums(mat[filter, act.names])
  foo <- head(sort(foo, decreasing=T), 10)
  summary <- paste(foo, "of", sum(filter))
  foo <- round(foo/sum(filter), 3)
  data.frame(label=names(foo), ct=as.vector(foo), ind=ind$short[i], summary=summary)
}))
out3 <- rbind(out, out2)
cor.name <- sapply(as.character(out3$label), function(x) {
  gum <- unlist(strsplit(x, "[.]"))
  paste0(gum[4], " (", substr(gum[2], 1, 3), ")")
})
short.name <- sapply(as.character(out3$label), function(x) {
  unlist(strsplit(x, "[.]"))[4]
})
cat.name <- sapply(as.character(out3$label), function(x) {
  capitalize(unlist(strsplit(x, "[.]"))[2])
})
action.colors <- c("malware"="#BF2E1A", "hacking"="#FAA635", "social"="#FFD24F", 
                   "misuse"="#B2BB1C", "physical"="#0093A9", "error"="#46166B", 
                   "environmental"="#00A950")
cor.color <- sapply(as.character(out3$label), function(x) {
  gum <- unlist(strsplit(x, "[.]"))
  action.colors[gum[2]]
})
out3$label <- cor.name
out3$color <- cor.color
out3$short <- short.name
out3$cat <- cat.name
out3$summary <- paste(out3$summary, paste0("<font color=\"", out3$color, "\"><b>", out3$short, "</b>"), paste0("<i>", out3$cat, "</i></font>"), sep="<br>")

write.csv(out3, "actions.csv", row.names=F)
write.csv(ind, "industry.csv", row.names=F)
