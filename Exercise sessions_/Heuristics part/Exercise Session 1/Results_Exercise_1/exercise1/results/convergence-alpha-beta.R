## Instance ulysses22
# Change for the your filenames and the names of your tests
file.names <- list()
file.names[[1]] <- paste0("alpha-beta_ulysses22/data-convergence---alpha_0_--beta_1-",seq(1234,1253),".txt")
file.names[[2]] <- paste0("alpha-beta_ulysses22/data-convergence---alpha_1_--beta_0-",seq(1234,1253),".txt")

test.names <- c("a0b1", "a1b0")

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
do.lines.plot(data, output="convergence-alpha-beta-ulysses22.png")

## Instance att532
# Change for the your filenames and the names of your tests
file.names <- list()
file.names[[1]] <- paste0("alpha-beta_att532/data-convergence---alpha_0_--beta_1-",seq(1234,1253),".txt")
file.names[[2]] <- paste0("alpha-beta_att532/data-convergence---alpha_1_--beta_0-",seq(1234,1253),".txt")

test.names <- c("a0b1", "a1b0")

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
do.lines.plot(data, output="convergence-alpha-beta-att532.png")


