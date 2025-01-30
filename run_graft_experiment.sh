# Required environment variables:
# TAG: tag for the trail
# TYPE: finetune / prompt / prompt-demo  
# TASK: SST-2 / sst-5 / mr / cr / mpqa / subj / trec / CoLA / MNLI / SNLI / QNLI / RTE / MRPC / QQP / STS-B
# BS: batch size (recommendation: 2 / 4 / 8)
# LR: learning rate (recommendation: 1e-5 / 2e-5 / 5e-5)
# SEED: random seed (13 / 21 / 42 / 87 / 100)
# MODEL: pre-trained model name (roberta-*, bert-*), see Transformers model list

# Number of training instances per label
#K=16


# Task specific parameters
# The default length is 128 and the default number of samples is 16.
# For some tasks, we use longer length or double demo (when using demonstrations, double the maximum length).
# For some tasks, we use smaller number of samples to save time (because of the large size of the test sets).
# All those parameters are set arbitrarily by observing the data distributions.
TASK_EXTRA=""
case $TASK in
    CoLA)
        TEMPLATE=*cls**sent_0*_This_is*mask*.*sep+*
        MAPPING="{'0':'incorrect','1':'correct'}"
        ;;
    SST-2)
        TEMPLATE=*cls**sent_0*_It_was*mask*.*sep+*
        MAPPING="{'0':'terrible','1':'great'}"
        ;;
    imdb)
        TEMPLATE=*cls**sent_0*_It_was*mask*.*sep+*
        MAPPING="{'0':'terrible','1':'great'}"
        TASK_EXTRA="--first_sent_limit 110 --double_demo"   
        ;;    
    MRPC)
        TEMPLATE=*cls**sent_0**mask*,*+sentl_1**sep+*
        MAPPING="{'0':'No','1':'Yes'}"
        ;;
    QQP)
        TEMPLATE=*cls**sent_0**mask*,*+sentl_1**sep+*
        MAPPING="{'0':'No','1':'Yes'}"
        TASK_EXTRA="--num_sample 4"
        ;;
    STS-B)
        TEMPLATE=*cls**sent_0**mask*,*+sentl_1**sep+*
        MAPPING="{'0':'No','1':'Yes'}"
        ;;
    MNLI)
        TEMPLATE=*cls**sent-_0*?*mask*,*+sentl_1**sep+*
        MAPPING="{'contradiction':'No','entailment':'Yes','neutral':'Maybe'}"
        TASK_EXTRA="--first_sent_limit 110 --max_seq_len 256 --num_sample 4"
        ;;
    anli)
        TEMPLATE=*cls**sent-_0*?*mask*,*+sentl_1**sep+*
        MAPPING="{'contradiction':'No','entailment':'Yes','neutral':'Maybe'}"
        TASK_EXTRA="--max_seq_len 256 --num_sample 4"
        ;;    
    SNLI)
        TEMPLATE=*cls**sent-_0*?*mask*,*+sentl_1**sep+*
        MAPPING="{'contradiction':'No','entailment':'Yes','neutral':'Maybe'}"
        TASK_EXTRA="--max_seq_len 256 --num_sample 4"
        ;;
    QNLI)
        TEMPLATE=*cls**sent-_0*?*mask*,*+sentl_1**sep+*
        MAPPING="{'not_entailment':'No','entailment':'Yes'}"
        ;;
    RTE)
        TEMPLATE=*cls**sent-_0*?*mask*,*+sentl_1**sep+*
        MAPPING="{'not_entailment':'No','entailment':'Yes'}"
        TASK_EXTRA="--max_seq_len 256 --first_sent_limit 240"
        ;;
    mr)
        TEMPLATE=*cls**sent_0*_It_was*mask*.*sep+*
        MAPPING="{0:'terrible',1:'great'}"
        TASK_EXTRA="--first_sent_limit 110 --other_sent_limit 50 --double_demo"
        ;;
    sst-5)
        TEMPLATE=*cls**sent_0*_It_was*mask*.*sep+*
        MAPPING="{0:'terrible',1:'bad',2:'okay',3:'good',4:'great'}"
        TASK_EXTRA="--first_sent_limit 110 --other_sent_limit 20 --double_demo"
        ;;
    subj)
        TEMPLATE=*cls**sent_0*_This_is*mask*.*sep+*
        MAPPING="{0:'subjective',1:'objective'}"
        TASK_EXTRA="--first_sent_limit 110 --other_sent_limit 50 --double_demo"
        ;;
    trec)
        TEMPLATE="*cls**mask*:*+sent_0**sep+*"
        MAPPING="{0:'Description',1:'Entity',2:'Expression',3:'Human',4:'Location',5:'Number'}"
        TASK_EXTRA="--first_sent_limit 110 --double_demo"
        ;;
    ag_news)
        TEMPLATE="*cls**mask*:*+sent_0**sep+*"
        MAPPING="{'0':'World','1':'Sports','2':'Business','3':'Tech'}"
        TASK_EXTRA="--first_sent_limit 110 --double_demo"
        ;;    
    cr)
        TEMPLATE=*cls**sent_0*_It_was*mask*.*sep+*
        MAPPING="{0:'terrible',1:'great'}"
        TASK_EXTRA="--first_sent_limit 110 --other_sent_limit 50 --double_demo"
        ;;
    mpqa)
        TEMPLATE=*cls**sent_0*_It_was*mask*.*sep+*
        MAPPING="{0:'terrible',1:'great'}"
        TASK_EXTRA="--first_sent_limit 110  --double_demo"
        ;;

esac

# Gradient accumulation steps
# For medium-sized GPUs (e.g., 2080ti with 10GB memory), they can only take 
# a maximum batch size of 2 when using large-size models. So we use gradient
# accumulation steps to achieve the same effect of larger batch sizes.
DATA_DIR=./data/k-shot/$TASK/$K-$SEED
log_file_store=./log_files/log_noembed_SGD_graft

if [ $pretrained_model == 'roberta-base' ]; then
    len=128;
elif [ $pretrained_model == 'gpt2' ]; then
    len=256;
else 
    len=128;
fi   

python Grafting.py \
  --task_name $TASK \
  --data_dir $DATA_DIR \
  --model_name_or_path $MODEL \
  --cache_dir model_files \
  --few_shot_type $TYPE \
  --num_k $K \
  --max_seq_length $len \
  --max_length_per_example $len \
  --per_device_eval_batch_size 16 \
  --per_device_train_batch_size 8\
  --gradient_accumulation_steps 128 \
  --learning_rate $LR \
  --num_train_epochs $num_train_epochs\
  --seed 0 \
  --no_train $no_train \
  --template $TEMPLATE \
  --mapping $MAPPING \
  --output_dir="temp" \
  --use_lm_head=$uselmhead \
  --mask_path=$mask_path \
  --fix_head $fixhead\
  --fix_embeddings $fixembeddings\
  --use_CLS_linearhead $useCLS\
  --sparsity_level $sparsitylevel \
  --modelbase $pretrained_model \
  --truncate_head $truncate_head\
  --train_bias_only $train_bias_only\
  --log_file_store $log_file_store\
  --checkpoint_location $checkpoint_location\
  $TASK_EXTRA \
  $1 




# Delete the checkpoint 
# Since we need to run multiple trials, saving all the checkpoints takes 
# a lot of storage space. You can find all evaluation results in `log` file anyway.
#rm -r result/$TASK-$TYPE-$K-$SEED-$MODEL-$TRIAL_IDTF-$REAL_BS-$LR \
