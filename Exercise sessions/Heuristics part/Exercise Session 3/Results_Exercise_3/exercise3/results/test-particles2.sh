#!/bin/bash

folder=$1

mkdir -p $folder

rm -rf ${folder}/data.txt

echo "trial:p5:p10:p20:p50:p100:p200:p500:p1000" >> ${folder}/data.txt

seed=1234
for i in {1..20}; do
  AUX="${i}"
  for m in {5,10,20,50,100,200,500,1000}; do
    echo "seed ${seed} executing ${m}"
    file="${folder}/data-convergence-p${m}-${seed}.txt"
    ./pso --rastrigin --n 10 --ring --evaluations 5000 --particles $m --inertia 1 --phi1 1 --phi2 1 --seed ${seed}  >  ${file}
    SOL=$(cat ${file} | grep -o -E '^Best: [-+0-9.e]+' | cut -d ' ' -f2)
    AUX="${AUX}:${SOL}"
  done
  echo "$AUX" >>  ${folder}/data.txt
  seed=$(( seed + 1 ))
done


