#!/usr/bin/env bash
stage=0

# VBx Hyperparameters (tuned on session0)
Fa=0.1
Fb=5
loopP=0.9

. ./path.sh
. ./utils/parse_options.sh

CORPUS_DIR=/export/c01/corpora6/LibriCSS
DATA_DIR=data/libricss_separated_v2_multi_doa
EXP_DIR=exp/libricss_separated_v2_multi_doa

mkdir -p exp

if [ $stage -le 0 ]; then
  for part in dev; do
    echo "Running VBx on ${part} with Fa=$Fa, Fb=$Fb, loopP=$loopP"
    (
    while read -r line
    do
      filename=$(echo $line | cut -d' ' -f1)

      # Here we combine x-vectors of one recording into 1 ark and segments file, and modify the segments
      # file recording ids to be the same as the recording ids (removing last 2 characters).

      cat $EXP_DIR/$part/xvec/${filename}_{0,1}.ark > $EXP_DIR/$part/xvec/$filename.ark
      cat $EXP_DIR/$part/xvec/${filename}_{0,1}.seg | awk '{print $1, substr($2, 1, length($2)-2), $3, $4}' > $EXP_DIR/$part/xvec/$filename.seg

      # run variational bayes on top of x-vectors
      utils/queue.pl --mem 2G $EXP_DIR/${part}/log/vbx/vb_${filename}.log \
        python diarizer/vbx/vbhmm2.py \
            --init AHC+VB \
            --out-rttm-dir $EXP_DIR/${part}/vbx \
            --xvec-ark-file $EXP_DIR/${part}/xvec/${filename}.ark \
            --segments-file $EXP_DIR/${part}/xvec/${filename}.seg \
            --xvec-transform diarizer/models/ResNet101_16kHz/transform.h5 \
            --plda-file diarizer/models/ResNet101_16kHz/plda \
            --threshold -0.015 \
            --lda-dim 128 \
            --Fa $Fa \
            --Fb $Fb \
            --loopP $loopP &
    done<$DATA_DIR/${part}/reco2channel
    wait
    )
  done
fi

if [ $stage -le 1 ]; then
  # Combine all RTTM files and score
  for part in dev; do
    cat $DATA_DIR/${part}/rttm/*.rttm > $EXP_DIR/ref.rttm
    cat $EXP_DIR/${part}/vbx/*.rttm > $EXP_DIR/hyp.rttm
    LC_ALL= spyder --per-file $EXP_DIR/ref.rttm $EXP_DIR/hyp.rttm
  done
fi

exit 0
