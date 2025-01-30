modelbase='roberta-large';
task='QQP';
seed=0;
sparsitylevel=1e-04 ;
lr=1e7 ;
no_train=False; 


model_path="./fine_tune_ckpt/QQP-roberta-large-4096-0-100";
mask_path="highest_movement";

#2b62f341a7b8

TAG=exp \
TYPE=prompt \
TASK=$task \
K=4096 \
LR=$lr \
SEED=$seed \
MODEL=$model_path \
uselmhead=1 \
useCLS=0 \
num_train_epochs=100 \
mask_path=$mask_path \
sparsitylevel=$sparsitylevel \
pretrained_model=$modelbase \
fixhead=False \
fixembeddings=True \
truncate_head=False \
train_bias_only=False \
no_train=$no_train \
checkpoint_location="./saved_mask/roberta_large_100_qqp" \
bash run_graft_experiment.sh