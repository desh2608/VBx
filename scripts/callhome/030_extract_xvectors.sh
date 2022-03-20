#!/usr/bin/env bash
stage=0

. ./path.sh
. ./utils/parse_options.sh

DATA_DIR=data/callhome
EXP_DIR=exp/callhome

mkdir -p exp

if [ $stage -le 0 ]; then
  for part in dev test; do
    echo "Extracting x-vectors for ${part}..."
    mkdir -p $EXP_DIR/$part/xvec
    (
    for audio in $(ls $DATA_DIR/${part}/audios_8k/*.wav | xargs -n 1 basename)
    do
      filename=$(echo "${audio}" | cut -f 1 -d '.')
      echo ${filename} > exp/list_${filename}.txt
      
      utils/retry.pl utils/queue-freegpu.pl -l "hostname=c*\&!c21*" --gpu 1 --mem 2G \
        $EXP_DIR/${part}/log/xvec/xvec_${filename}.log \
        python diarizer/xvector/predict.py \
          --gpus true \
          --in-file-list exp/list_${filename}.txt \
          --in-lab-dir $EXP_DIR/${part}/vad \
          --in-wav-dir $DATA_DIR/${part}/audios_8k \
          --out-ark-fn $EXP_DIR/${part}/xvec/${filename}.ark \
          --out-seg-fn $EXP_DIR/${part}/xvec/${filename}.seg \
          --model ResNet101 \
          --weights diarizer/models/ResNet101_8kHz/nnet/raw_195.pth \
          --backend pytorch &

      sleep 10
    done
    wait
    )
    rm exp/list_*
  done
fi

exit 0
