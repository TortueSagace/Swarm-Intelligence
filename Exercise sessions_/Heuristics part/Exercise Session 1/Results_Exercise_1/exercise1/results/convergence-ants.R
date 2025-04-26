## Instance ulysses22
# Change for the your filenames and the names of your tests
file.names <- list()
file.names[[1]] <- paste0("ants_ulysses22/data-convergence-m2-",seq(1234,1253),".txt")
file.names[[2]] <- paste0("ants_ulysses22/data-convergence-m5-",seq(1234,1253),".txt")
file.names[[3]] <- paste0("ants_ulysses22/data-convergence-m10-",seq(1234,1253),".txt")
file.names[[4]] <- paste0("ants_ulysses22/data-convergence-m20-",seq(1234,1253),".txt")
file.names[[5]] <- paste0("ants_ulysses22/data-convergence-m50-",seq(1234,1253),".txt")
file.names[[6]] <- paste0("ants_ulysses22/data-convergence-m100-",seq(1234,1253),".txt")

test.names <- c("m2", "m5", "m10", "m20", "m50", "m100" )

# Read data in a list with "names" as elements
data <- list() 
for(i in 1:length(file.names)){
  for(j in 1:length(file.names[[i]])){
    if(is.null(data[[test.names[i]]])){
      data[[test.names[i]]] <- read.table(file=file.names[[i]][j], header=FALSE, sep=" ")
      sel.index <- sapply(seq(1,max( data[[test.names[i]]]$V1)), match,  data[[test.names[i]]]$V1)
      data[[test.names[i]]] <- data[[test.names[i]]][sel.index,]
      colnames(data[[test.names[i]]]) <- c("tours", "quality")
      
    }else{
      aux <- read.table(file=file.names[[i]][j], header=FALSE, sep=" ")
      sel.index <- sapply(seq(1,max(aux$V1)), match, aux$V1)
      aux <- aux[sel.index,]
      data[[test.names[i]]][,"quality"] <- data[[test.names[i]]][,"quality"] + aux[,2]
    }
  }
  data[[test.names[i]]][,"quality"] <- data[[test.names[i]]][,"quality"] / length(file.names[[i]])
  
}

#print(data)
source("./R-scripts/convergence.R")
do.lines.plot(data, output="convergence-ants-ulysses22.png")


## Instance att532
# Change for the your filenames and the names of your tests
file.names <- list()
file.names[[1]] <- paste0("ants_att532/data-convergence-m2-",seq(1234,1253),".txt")
file.names[[2]] <- paste0("ants_att532/data-convergence-m5-",seq(1234,1253),".txt")
file.names[[3]] <- paste0("ants_att532/data-convergence-m10-",seq(1234,1253),".txt")
file.names[[4]] <- paste0("ants_att532/data-convergence-m20-",seq(1234,1253),".txt")
file.names[[5]] <- paste0("ants_att532/data-convergence-m50-",seq(1234,1253),".txt")
file.names[[6]] <- paste0("ants_att532/data-convergence-m100-",seq(1234,1253),".txt")

test.names <- c("m2", "m5", "m10", "m20", "m50", "m100" )

# Read data in a list with "names" as elements
data <- list() 
for(i in 1:length(file.names)){
  for(j in 1:length(file.names[[i]])){
    if(is.null(data[[test.names[i]]])){
      data[[test.names[i]]] <- read.table(file=file.names[[i]][j], header=FALSE, sep=" ")
      sel.index <- sapply(seq(1,max( data[[test.names[i]]]$V1)), match,  data[[test.names[i]]]$V1)
      data[[test.names[i]]] <- data[[test.names[i]]][sel.index,]
      colnames(data[[test.names[i]]]) <- c("tours", "quality")
      
    }else{
      aux <- read.table(file=file.names[[i]][j], header=FALSE, sep=" ")
      sel.index <- sapply(seq(1,max(aux$V1)), match, aux$V1)
      aux <- aux[sel.index,]
      data[[test.names[i]]][,"quality"] <- data[[test.names[i]]][,"quality"] + aux[,2]
    }
  }
  data[[test.names[i]]][,"quality"] <- data[[test.names[i]]][,"quality"] / length(file.names[[i]])
  
}

#print(data)
source("./R-scripts/convergence.R")
do.lines.plot(data, output="convergence-ants-att532.png")
