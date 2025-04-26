#!/bin/bash

folder=$1
shift 1
instances=$*

mkdir -p $folder

echo "$instances"

finalfile="${folder}/all-data.txt"

rm -rf $finalfile

ants=10
alpha=1
beta=1
rho=0.5
tours=1000
 
pinstances=${instances//' '/':'}


echo "$pinstances"

echo "trial:$pinstances" >> $finalfile
seed=1234

for i in {1..50}; do  
  AUX="${i}"
  for instance in $instances ; do 
    psize=`cat $instance | grep "^DIMENSION" | cut -d ' ' -f3`
    binstance=$(basename $instance)
    echo "seed ${seed} executing ${m}"
    file=${folder}/data-${i}-${binstance}-${seed}.txt
    ./acotsp -i ${instance} --tries 1 --tours $tours --time 0 --localsearch 0 --q0 0 --as --ants ${ants} --alpha $alpha --beta $beta --rho $rho --seed ${seed}  >  $file
    SOL=$(cat ${file} | grep -o -E 'Best [-+0-9.e]+' | cut -d ' ' -f2)
    AUX="${AUX}:${SOL}"
  done
  echo "$AUX" >>  $finalfile
  seed=$(( seed + 1 ))
done

rm -rf stat* cmp* best*
