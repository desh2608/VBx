# ====== About run.pl, queue.pl, slurm.pl, and ssh.pl ======
# Usage: <cmd>.pl [options] JOB=1:<nj> <log> <command...>
# e.g.
#   run.pl --mem 4G JOB=1:10 echo.JOB.log echo JOB
#
# Options:
#   --time <time>: Limit the maximum time to execute.
#   --mem <mem>: Limit the maximum memory usage.
#   -–max-jobs-run <njob>: Limit the number parallel jobs. This is ignored for non-array jobs.
#   --num-threads <ngpu>: Specify the number of CPU core.
#   --gpu <ngpu>: Specify the number of GPU devices.
#   --config: Change the configuration file from default.
#
# "JOB=1:10" is used for "array jobs" and it can control the number of parallel jobs.
# The left string of "=", i.e. "JOB", is replaced by <N>(Nth job) in the command and the log file name,
# e.g. "echo JOB" is changed to "echo 3" for the 3rd job and "echo 8" for 8th job respectively.
# Note that the number must start with a positive number, so you can't use "JOB=0:10" for example.
#
# run.pl, queue.pl, slurm.pl, and ssh.pl have unified interface, not depending on its backend.
# These options are mapping to specific options for each backend and
# it is configured by "conf/queue.conf" and "conf/slurm.conf" by default.
# If jobs failed, your configuration might be wrong for your environment.
#
#
# The official documentation for run.pl, queue.pl, slurm.pl, and ssh.pl:
#   "Parallelization in Kaldi": http://kaldi-asr.org/doc/queue.html
# =========================================================~


# Select the backend used by run.sh from "local", "stdout", "sge", "slurm", or "ssh"
cmd_backend='jhu'

# Local machine, without any Job scheduling system
if [ "${cmd_backend}" = local ]; then

    # The other usage
    export train_cmd="run.pl"
    # Used for "*_train.py": "--gpu" is appended optionally by run.sh
    export cuda_cmd="run.pl"
    # Used for "*_recog.py"
    export decode_cmd="run.pl"

# "qsub" (Sun Grid Engine, or derivation of it)
elif [ "${cmd_backend}" = sge ]; then
    # The default setting is written in conf/queue.conf.
    # You must change "-q g.q" for the "queue" for your environment.
    # To know the "queue" names, type "qhost -q"
    # Note that to use "--gpu *", you have to setup "complex_value" for the system scheduler.

    export train_cmd="queue.pl"
    export cuda_cmd="queue.pl"
    export decode_cmd="queue.pl"

# This is an example of specifying several unique options in the JHU CLSP cluster setup.
# Users can modify/add their own command options according to their cluster environments.
elif [ "${cmd_backend}" = jhu ]; then

    export train_cmd="queue.pl --mem 2G"
    export cuda_cmd="queue-ackgpu.pl --mem 2G --gpu 1 -l hostname=c*"
    export decode_cmd="queue.pl --mem 4G"

else
    echo "$0: Error: Unknown cmd_backend=${cmd_backend}" 1>&2
    return 1
fi
