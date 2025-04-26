#!/bin/bash

folder=$1

mkdir -p $folder

rm -rf ${folder}/data.txt

echo "trial:ring:star" >> ${folder}/data.txt

seed=1234
for i in {1..50}; do
  AUX="${i}"
  file="${folder}/data-convergence-ring-${seed}.txt"
  ./pso --rastrigin --n 10 --ring --iterations 20 --particles 50 --inertia 1 --phi1 1 --phi2 1 --seed ${seed}  >  ${file}
   SOL=$(cat ${file} | grep -o -E '^Best: [-+0-9.e]+' | cut -d ' ' -f2)
   AUX="${AUX}:${SOL}"
  file="${folder}/data-convergence-star-${seed}.txt"
  ./pso --rastrigin --n 10 --star --iterations 20 --particles 50 --inertia 1 --phi1 1 --phi2 1 --seed ${seed}  >  ${file}
   SOL=$(cat ${file} | grep -o -E '^Best: [-+0-9.e]+' | cut -d ' ' -f2)
   AUX="${AUX}:${SOL}"
   
   echo "$AUX" >>  ${folder}/data.txt
   seed=$(( seed + 1 ))
done


