do.lines.plot <- function(data.list=NULL, test.names=names(data.list), plot.mar=c(6,16,4,3), plot.title="Sample acotsp", plot.yaxis.label="Mean solution quality",plot.xaxis.label="Tours", output="sample-acotsp.png", plot.axis.style=1, plot.size.axis=3, plot.size.title=3){
  
  # Get x&y axis bounds
  x.min <- min(unlist(lapply(data.list,function(data) return(min(data$tours))))) 
  x.max <- max(unlist(lapply(data.list,function(data) return(max(data$tours)))))
  y.min <- min(unlist(lapply(data.list,function(data) return(min(data$quality)))))
  y.max <- max(unlist(lapply(data.list,function(data) return(max(data$quality)))))
  # Little adjust
  y.min <- y.min - (y.min/100) ; x.min <- x.min - (x.min/100)
  y.max <- y.max + (y.max/100) ; x.max <- x.max + (x.max/100)

  # Line types and color
  line.type <- 1:length(data.list)
  line.col <-  1:length(data.list)

  # Init plot
  png(file = output, width = 800, height =  450, units = "px", pointsize = 8, bg = "white")
  par(las=plot.axis.style, mar=plot.mar, cex.axis=plot.size.axis, cex.main=plot.size.title, xaxs= "i", yaxs="i", pty="m", mgp=c(5,2,0), cex.lab=3)
  plot(data.list[[1]]$tours, data.list[[1]]$quality, ylab=NA, type="n", main=plot.title, xlim=c(x.min,x.max),ylim=c(y.min, y.max), xlab=plot.xaxis.label)

  for(i in 1:length(data.list)){
     name <- test.names[i]
     # Complete lines for a nicer visualization
     data.x <- c(x.min, data.list[[name]]$tours, x.max)
     data.y <- c(data.list[[name]]$quality[1], data.list[[name]]$quality, data.list[[name]]$quality[length(data.list[[name]]$quality)])
     # Plot
     lines(data.x, data.y , col=line.col[i], lty=line.type[i], lwd=3)
  }

  legend("topright", "(x,y)", lty=line.type, lwd=rep(2,length(line.type)), col=line.col, legend=names(data.list), xjust=1, yjust=1, seg.len=3, cex=3, bg="white")
  axis(2)
  # Adjust line in case you need less space between axis and label
  mtext(plot.yaxis.label, side=2, line=13, cex=3,las=0)
  dev.off()
}
