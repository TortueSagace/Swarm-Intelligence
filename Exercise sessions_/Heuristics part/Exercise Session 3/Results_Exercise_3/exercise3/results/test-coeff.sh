#!/bin/bash

folder=$1

mkdir -p $folder

rm -rf ${folder}/data.txt

echo "trial:0.1:0.3:0.5:0.7:0.9:1" >> ${folder}/data.txt

for p1 in {0.1,0.3,0.5,0.7,0.9,1}; do
  AUX="${p1}"
  for p2 in {0.1,0.3,0.5,0.7,0.9,1}; do
    SS=0
    seed=1234
    for i in {1..20}; do
      file="${folder}/data-convergence-p1${p1}-p2${p2}-${seed}.txt"
     ./pso --rosenbrock --n 10 --star --iterations 50 --particles 20 --inertia 1 --phi1 $p1 --phi2 $p2 --seed ${seed}  >  ${file}
      SOL=$(cat ${file} | grep -o -E '^Best: [-+0-9.e]+' | cut -d ' ' -f2)
      SS=$(awk "BEGIN {print $SS+$SOL; exit}")
      seed=$(( seed + 1 ))
    done
    AUX="${AUX}:${SS}"
  done
  echo "$AUX" >>  ${folder}/data.txt
  
done


