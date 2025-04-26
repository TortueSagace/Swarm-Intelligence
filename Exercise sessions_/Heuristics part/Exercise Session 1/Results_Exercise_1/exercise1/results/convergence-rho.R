## Instance ulysses22
# Change for the your filenames and the names of your tests
file.names <- list()
file.names[[1]] <- paste0("rho_ulysses22/data-convergence-r0.01-",seq(1234,1253),".txt")
file.names[[2]] <- paste0("rho_ulysses22/data-convergence-r0.2-",seq(1234,1253),".txt")
file.names[[3]] <- paste0("rho_ulysses22/data-convergence-r0.5-",seq(1234,1253),".txt")
file.names[[4]] <- paste0("rho_ulysses22/data-convergence-r1-",seq(1234,1253),".txt")

test.names <- c("r0.01", "r0.2", "r0.5", "r1")

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
do.lines.plot(data, output="convergence-rho_ulysses22.png")


## Instance att532
# Change for the your filenames and the names of your tests
file.names <- list()
file.names[[1]] <- paste0("rho_att532/data-convergence-r0.01-",seq(1234,1253),".txt")
file.names[[2]] <- paste0("rho_att532/data-convergence-r0.2-",seq(1234,1253),".txt")
file.names[[3]] <- paste0("rho_att532/data-convergence-r0.5-",seq(1234,1253),".txt")
file.names[[4]] <- paste0("rho_att532/data-convergence-r1-",seq(1234,1253),".txt")

test.names <- c("r0.01", "r0.2", "r0.5", "r1")

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
do.lines.plot(data, output="convergence-rho_att532.png")
