#!/bin/bash

folder=$1
instance=$2
parameter=$3
shift 3
values=$*

mkdir -p $folder

finalfile="${folder}/all-data.txt"

rm -rf $finalfile

ants=10
alpha=1
beta=1
rho=0.5
tours=1000

all=""
varname=""

if [ $parameter == "alpha" ]; then
  varname="--alpha"
else 
  all="$all --alpha $alpha"   
fi

if [ $parameter == "beta" ]; then
  varname="--beta"
else
  all="$all --beta $beta"
fi

if [ $parameter == "rho" ]; then
  varname="--rho"
else
  all="$all --rho $rho"
fi


if [ $parameter == "ants" ]; then
  varname="--ants"
else
  all="$all --ants $ants"
fi

pvalues=${values//' '/':'}

echo "trial:$pvalues" >> $finalfile
seed=1234

for i in {1..50}; do  
  AUX="${i}"
  echo "seed ${seed} executing ${m}"
  for value in $values ; do 
    binstance=$(basename $instance)
    file=${folder}/data-${i}-${varname}-${value}-${binstance}-${seed}.txt
    ./acotsp -i ${instance} --tries 1 --tours $tours --time 0 --localsearch 0 --q0 0 --mmas ${all} ${varname} ${value} --seed ${seed}  >  $file
    SOL=$(cat ${file} | grep -o -E 'Best [-+0-9.e]+' | cut -d ' ' -f2)
    AUX="${AUX}:${SOL}"
  done
  echo "$AUX" >>  $finalfile
  seed=$(( seed + 1 ))
done

rm -rf stat* cmp* best*
