
# data.matrix is a matrix or a data frame
# Customize the plot using par:
# plot.axis.style  0: always parallel to the axis, 1: always horizontal, 2: always perpendicular to the axis, 3: always vertical
# plot.mar margin of the plot (down, left, up, right)
# plot.size.axis / title size of the axis and title
# vertical.x.axis try 1 or 2 
do.boxplot <- function (data.matrix, data.labels=colnames(data.matrix), plot.mar=c(4,14,4,2), plot.title="Sample acotsp", plot.yaxis.label="Mean solution quality", output="sample-acotsp.png", plot.axis.style=1, plot.size.axis=3, plot.size.title=3, plot.text.yaxis=3, vertical.x.axis=1, colors=rep(0, ncol(data.matrix))){

  if(ncol(data.matrix)!= length(data.labels)){
    cat("Error there must be same amount of data sets and data labels.")
    return()
  }
  png(file = output, width = 800, height =  450, units = "px", pointsize = 8, bg = "white")
  par(las=plot.axis.style, mar=plot.mar, cex.axis=plot.size.axis, cex.main=plot.size.title)
  boxplot(data.matrix, main=plot.title, xaxt="n", col=colors)
  mtext(plot.yaxis.label, side=2, line=(plot.mar[2]-3), cex=plot.text.yaxis, las=0)
  axis(1, at=c(1:length(data.labels)), labels=data.labels, line=plot.mar[1] - 3, tick=FALSE, las=vertical.x.axis, cex.axis=plot.size.axis)

  dev.off()
}
