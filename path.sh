# Print immediately
export PYTHONUNBUFFERED=1

export PATH=${PATH}:`pwd`/utils

# Activate environment
. /home/draj/anaconda3/etc/profile.d/conda.sh && conda deactivate && conda activate vbx

export LC_ALL=C
