#!/bin/bash

cur_model_list=(CycleGAN deeplab se_resnext50 mask_rcnn bert transformer ddpg_deep_explore paddingrnn yolov3)
usage () {
  cat <<EOF
  usage: $0 [options]
  -h         optional   Print this help message
  -m  model  ${cur_model_list[@]} | all
  -c  cuda_version 9.0|10.0
  -n  image_name
  -i  image_commit_id
  -v  paddle_version
  -p  all_path contains dir of prepare(pretrained models), dataset, logs, such as /ssd1/ljh
EOF
}
if [ $# != 12 ] ; then
  usage
  exit 1;
fi
while getopts h:m:c:n:i:v:p: opt
do
  case $opt in
  h) usage; exit 0 ;;
  m) model="$OPTARG" ;;
  c) cuda_version="$OPTARG" ;;
  n) image_name="$OPTARG" ;;
  i) image_commit_id="$OPTARG" ;;
  v) paddle_version="$OPTARG" ;;
  p) all_path="$OPTARG" ;;
  \?) usage; exit 1 ;;
  esac
done

export http_proxy=http://172.19.57.45:3128
export https_proxy=http://172.19.57.45:3128

origin_path=$(pwd)

prepare(){
    echo "*******prepare benchmark***********"

#    if [ '10.0' == $cuda_version ]
#    then
#        export LD_LIBRARY_PATH=/home/work/418.39/lib64/:$LD_LIBRARY_PATH
#    fi
    export LD_LIBRARY_PATH=/opt/_internal/cpython-2.7.11-ucs4/lib:${LD_LIBRARY_PATH#/opt/_internal/cpython-2.7.11-ucs2/lib:}
    export PATH=/opt/python/cp27-cp27mu/bin/:${PATH}
#    ln -s /usr/lib/x86_64-linux-gnu/libnccl.so.2 /usr/lib/x86_64-linux-gnu/libnccl.so
#    rm /etc/apt/sources.list
#    cp ${all_path}/sources.list /etc/apt
#    apt-get update
#    apt-get install libmysqlclient-dev -y
#    apt-get install git -y
#    pip install MySQL-python

    yum install mysql-devel -y
    pip install MySQL-python

    save_log_dir=${all_path}/logs/log_${paddle_version}
    train_log_dir=${save_log_dir}/train_log
    mkdir -p ${train_log_dir}
    root_path=/home/crim/
    fluid_path=/home/crim/benchmark
    log_path=/home/crim/benchmark/logs
    data_path=${all_path}/dataset
    prepare_path=${all_path}/prepare

    if [ -e ${root_path} ]
    then
        rm ${log_path}/*
        cd ${root_path}
        git pull
        echo "prepare had done"
    else
        mkdir /home/crim
        cd ${root_path}
        git clone https://github.com/PaddlePaddle/benchmark.git
        cd ${fluid_path}
        git submodule init
        git submodule update
        mkdir $log_path
    fi

    cd ${fluid_path}
    benchmark_commit_id=$(git log|head -n1|awk '{print $2}')
    echo "benchmark_commit_id is: "${benchmark_commit_id}
    pip uninstall paddlepaddle-gpu -y
    pip install ${image_name}
    echo "*******prepare end!***********"
}


#run_cycle_gan
CycleGAN(){
    cur_model_path=${fluid_path}/CycleGAN/paddle
    cd ${cur_model_path}
    mkdir data
    ln -s ${data_path}/horse2zebra/ ${cur_model_path}/data
    echo "index is speed, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh train speed ${train_log_dir} > ${log_path}/${FUNCNAME}_speed_1gpus 2>&1
    sleep 60
    echo "index is mem, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh train mem ${train_log_dir} > ${log_path}/${FUNCNAME}_mem_1gpus 2>&1
}


#run_deeplabv3+
deeplab(){
    cur_model_path=${fluid_path}/deeplabv3+/paddle
    cd ${cur_model_path}
    mkdir data
    mkdir -p ./output/model
    ln -s ${data_path}/cityscape ${cur_model_path}/data/cityscape
    ln -s ${prepare_path}/deeplabv3plus_xception65_initialize ${cur_model_path}/deeplabv3plus_xception65_initialize
    echo "index is speed, 1gpu, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh train speed sp ${train_log_dir} > ${log_path}/DeepLab_V3+_speed_1gpus 2>&1
    sleep 60
    echo "index is speed, 8gpus, begin"
    CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run.sh train speed sp ${train_log_dir} > ${log_path}/DeepLab_V3+_speed_8gpus 2>&1
    sleep 60
    echo "index is mem, 1gpus, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh train mem sp ${train_log_dir} > ${log_path}/DeepLab_V3+_mem_1gpus 2>&1
    sleep 60
    echo "index is mem, 8gpus, begin"
    CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run.sh train mem sp ${train_log_dir} > ${log_path}/DeepLab_V3+_mem_8gpus 2>&1
    sleep 60
    echo "index is maxbs, 1gpus, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh train maxbs sp ${train_log_dir} > ${log_path}/DeepLab_V3+_maxbs_1gpus 2>&1
    sleep 60
    echo "index is maxbs, 8gpus, begin"
    CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run.sh train maxbs sp ${train_log_dir} > ${log_path}/DeepLab_V3+_maxbs_8gpus 2>&1
    sleep 60
    echo "index is speed, 8gpus, run_mode is multi_process, begin"
    CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run.sh train speed mp ${train_log_dir} > ${log_path}/DeepLab_V3+_speed_8gpus8p 2>&1
}


#run_se-resnext50
se_resnext50(){
    cur_model_path=${fluid_path}/se-resnext/paddle
    cd ${cur_model_path}
    rm -rf ${cur_model_path}/data/ILSVRC2012
    ln -s ${data_path}/ILSVRC2012 ${cur_model_path}/data/ILSVRC2012
    sed -i '/cd /d' run.sh
    echo "index is speed, 1gpu, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh speed 32 ${train_log_dir} > ${log_path}/SE-ResNeXt50_speed_1gpus 2>&1
    sleep 60
    echo "index is speed, 8gpus, begin"
    CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run.sh speed 32 ${train_log_dir} > ${log_path}/SE-ResNeXt50_speed_8gpus 2>&1
    sleep 60
    echo "index is mem, 1gpus, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh mem 32 ${train_log_dir} > ${log_path}/SE-ResNeXt50_mem_1gpus 2>&1
    sleep 60
    echo "index is mem, 8gpus, begin"
    CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run.sh mem 32 ${train_log_dir} > ${log_path}/SE-ResNeXt50_mem_8gpus 2>&1
    sleep 60
    echo "index is maxbs, 1gpus, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh maxbs 112 ${train_log_dir} > ${log_path}/SE-ResNeXt50_maxbs_1gpus 2>&1
    sleep 60
    echo "index is maxbs, 8gpus, begin"
    CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run.sh maxbs 112 ${train_log_dir} > ${log_path}/SE-ResNeXt50_maxbs_8gpus 2>&1
}


#run_mask-rcnn
mask_rcnn(){
    cur_model_path=${fluid_path}/Mask-RCNN/paddle
    cd ${cur_model_path}
    if python -c "import pycocotools" >/dev/null 2>&1
    then
        echo "cocoapi have already installed"
    else
        echo "cocoapi NOT FOUND"
        cp -r ${prepare_path}/cocoapi/ ./
        cd cocoapi/PythonAPI/
        pip install Cython
        make install
        python2 setup.py install --user
        echo "cocoapi installed"
    fi
    ln -s ${prepare_path}/mask-rcnn/imagenet_resnet50_fusebn ${cur_model_path}/imagenet_resnet50_fusebn
    cd ${cur_model_path}/rcnn
    rm -rf dataset/coco
    ln -s ${data_path}/COCO17 ${cur_model_path}/rcnn/dataset/coco
    echo "index is speed, 1gpu, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh train speed sp ${train_log_dir} > ${log_path}/${FUNCNAME}_speed_1gpus 2>&1
    sleep 60
    echo "index is speed, 8gpus, begin"
    CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run.sh train speed sp ${train_log_dir} > ${log_path}/${FUNCNAME}_speed_8gpus 2>&1
    sleep 60
    echo "index is mem, 1gpu, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh train mem sp ${train_log_dir} > ${log_path}/${FUNCNAME}_mem_1gpus 2>&1
    sleep 60
    echo "index is mem, 8gpus, begin"
    CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run.sh train mem sp ${train_log_dir} > ${log_path}/${FUNCNAME}_mem_8gpus 2>&1
    sleep 60
    echo "index is maxbs, 1gpu, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh train maxbs sp ${train_log_dir} > ${log_path}/${FUNCNAME}_maxbs_1gpus 2>&1
    sleep 60
    echo "index is maxbs, 8gpus, begin"
    CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run.sh train maxbs sp ${train_log_dir} > ${log_path}/${FUNCNAME}_maxbs_8gpus 2>&1
    sleep 60
    echo "index is speed, 8gpus, run_mode is multi_process, begin"
    CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run.sh train speed mp ${train_log_dir} > ${log_path}/${FUNCNAME}_speed_8gpus8p 2>&1
}


#run_bert
bert(){
    cur_model_path=${fluid_path}/NeuralMachineTranslation/BERT/fluid/train
    cd ${cur_model_path}
    ln -s ${data_path}/Bert/data ${cur_model_path}/data
    ln -s ${prepare_path}/chinese_L-12_H-768_A-12 ${cur_model_path}/chinese_L-12_H-768_A-12

    echo "index is speed, 1gpus, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh train speed ${train_log_dir} > ${log_path}/${FUNCNAME}_speed_1gpus 2>&1
    sleep 60
    echo "index is speed, 8gpus, begin"
    CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run.sh train speed ${train_log_dir} > ${log_path}/${FUNCNAME}_speed_8gpus 2>&1
    sleep 60
    echo "index is mem, 1gpus, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh train mem ${train_log_dir} > ${log_path}/${FUNCNAME}_mem_1gpus 2>&1
    sleep 60
    echo "index is mem, 8gpus, begin"
    CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run.sh train mem ${train_log_dir} > ${log_path}/${FUNCNAME}_mem_8gpus 2>&1
    sleep 60
    echo "index is maxbs, 1gpus, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh train maxbs ${train_log_dir} > ${log_path}/${FUNCNAME}_maxbs_1gpus 2>&1
    sleep 60
    echo "index is maxbs, 8gpus, begin"
    CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run.sh train maxbs ${train_log_dir} > ${log_path}/${FUNCNAME}_maxbs_8gpus 2>&1
}


#run_transformer
transformer(){
    cur_model_path=${fluid_path}/NeuralMachineTranslation/Transformer/fluid/train
    cd ${cur_model_path}
    ln -s ${data_path}/transformer/data ${cur_model_path}/data
    cp -r ${prepare_path}/transformer/mosesdecoder ${cur_model_path}/mosesdecoder
    echo "index is speed, 1gpu, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh train speed sp ${train_log_dir} > ${log_path}/${FUNCNAME}_speed_1gpus 2>&1
    sleep 60
    echo "index is speed, 8gpus, begin"
    CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run.sh train speed sp ${train_log_dir} > ${log_path}/${FUNCNAME}_speed_8gpus 2>&1
    sleep 60
    echo "index is mem, 1gpus, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh train mem sp ${train_log_dir} > ${log_path}/${FUNCNAME}_mem_1gpus 2>&1
    sleep 60
    echo "index is mem, 8gpus, begin"
    CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run.sh train mem sp ${train_log_dir} > ${log_path}/${FUNCNAME}_mem_8gpus 2>&1
    sleep 60
    echo "index is maxbs, 1gpus, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh train maxbs sp ${train_log_dir} > ${log_path}/${FUNCNAME}_maxbs_1gpus 2>&1
    sleep 60
    echo "index is maxbs, 8gpus, begin"
    CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run.sh train maxbs sp ${train_log_dir} > ${log_path}/${FUNCNAME}_maxbs_8gpus 2>&1
    sleep 60
    echo "index is speed, 8gpus, run_mode is multi_process, begin"
    CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run.sh train speed mp ${train_log_dir} > ${log_path}/${FUNCNAME}_speed_8gpus8p 2>&1
}


#run_ddpg_deep_explore
ddpg_deep_explore(){
    cur_model_path=${fluid_path}/DDPG_Deep_Explore/Fluid_version
    cd ${cur_model_path}
    if python -c "import parl" >/dev/null 2>&1
    then
        echo "parl have already installed"
    else
        echo "parl NOT FOUND"
        pip install parl
        echo "parl installed"
    fi
    echo "index is speed, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh train speed ${train_log_dir} > ${log_path}/${FUNCNAME}_speed_1gpus 2>&1
    sleep 60
    echo "index is mem, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh train mem ${train_log_dir} > ${log_path}/${FUNCNAME}_mem_1gpus 2>&1
}


#run_paddingrnn
paddingrnn(){
    cur_model_path=${fluid_path}/PaddingRNN/lstm_paddle
    cd ${cur_model_path}
    batch_size=20
    ln -s ${data_path}/simple-examples ${cur_model_path}/data/simple-examples
    echo "index is speed, 1gpus, small model, rnn_type=static, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh speed small static ${batch_size} ${train_log_dir} > ${log_path}/${FUNCNAME}_small_static_speed_1gpus 2>&1
    sleep 60
    echo "index is mem, 1gpus, small model, rnn_type=static, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh mem small static ${batch_size} ${train_log_dir} > ${log_path}/${FUNCNAME}_small_static_mem_1gpus 2>&1
    sleep 60
    echo "index is speed, 1gpus, large model, rnn_type=static, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh speed large static ${batch_size} ${train_log_dir} > ${log_path}/${FUNCNAME}_large_static_speed_1gpus 2>&1
    sleep 60
    echo "index is mem, 1gpus, large model, rnn_type=static, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh mem large static ${batch_size} ${train_log_dir} > ${log_path}/${FUNCNAME}_large_static_mem_1gpus 2>&1
    sleep 60
    echo "index is speed, 1gpus, small model, rnn_type=padding, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh speed small padding ${batch_size} ${train_log_dir} > ${log_path}/${FUNCNAME}_small_padding_speed_1gpus 2>&1
    sleep 60
    echo "index is mem, 1gpus, small model, rnn_type=padding, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh mem small padding ${batch_size} ${train_log_dir} > ${log_path}/${FUNCNAME}_small_padding_mem_1gpus 2>&1
    sleep 60
    echo "index is speed, 1gpus, large model, rnn_type=padding, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh speed large padding ${batch_size} ${train_log_dir} > ${log_path}/${FUNCNAME}_large_padding_speed_1gpus 2>&1
    sleep 60
    echo "index is mem, 1gpus, large model, rnn_type=padding, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh mem large padding ${batch_size} ${train_log_dir} > ${log_path}/${FUNCNAME}_large_padding_mem_1gpus 2>&1
}


#run_yolov3
yolov3(){
    cur_model_path=${fluid_path}/yolov3/paddle
    cd ${cur_model_path}
    if python -c "import pycocotools" >/dev/null 2>&1
    then
        echo "cocoapi have already installed"
    else
        echo "cocoapi NOT FOUND"
        cp -r ${prepare_path}/cocoapi/ ./
        cd cocoapi/PythonAPI/
        pip install Cython
        make install
        python2 setup.py install --user
        echo "cocoapi installed"
    fi

#    cd ${cur_model_path}
#    #yolov3 的模型代码还在models
#    git clone https://github.com/PaddlePaddle/models.git
#    cd models/PaddleCV/yolov3/

    cd ${fluid_path}/models/PaddleCV/yolov3/
    git checkout -b benchmark origin/benchmark

    sed -i 's/build_strategy.memory_optimize/#build_strategy.memory_optimize/g' train.py
    #sh ./weights/download.sh
    ln -s ${prepare_path}/yolov3/yolov3 ./weights/yolov3
    ln -s ${prepare_path}/yolov3/darknet53 ./weights/darknet53

    rm -rf dataset/coco
    ln -s ${data_path}/coco ./dataset/coco
    cp ${fluid_path}/yolov3/paddle/run.sh ./
    echo "index is speed, 1gpu, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh train speed sp ${train_log_dir} > ${log_path}/${FUNCNAME}_speed_1gpus 2>&1
    sleep 60
    echo "index is speed, 8gpus, begin"
    CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run.sh train speed sp ${train_log_dir} > ${log_path}/${FUNCNAME}_speed_8gpus 2>&1
    sleep 60
    echo "index is mem, 1gpus, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh train mem sp ${train_log_dir} > ${log_path}/${FUNCNAME}_mem_1gpus 2>&1
    sleep 60
    echo "index is mem, 8gpus, begin"
    CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run.sh train mem sp ${train_log_dir} > ${log_path}/${FUNCNAME}_mem_8gpus 2>&1
    sleep 60
    echo "index is maxbs, 1gpus, begin"
    CUDA_VISIBLE_DEVICES=0 bash run.sh train maxbs sp ${train_log_dir} > ${log_path}/${FUNCNAME}_maxbs_1gpus 2>&1
    sleep 60
    echo "index is maxbs, 8gpus, begin"
    CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run.sh train maxbs sp ${train_log_dir} > ${log_path}/${FUNCNAME}_maxbs_8gpus 2>&1
    sleep 60
    echo "index is speed, 8gpus, run_mode is multi_process, begin"
    CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run.sh train speed mp ${train_log_dir} > ${log_path}/${FUNCNAME}_speed_8gpus8p 2>&1
}

prepare

if [ $model = "all" ]
then
    for model_name in ${cur_model_list[@]}
    do
        echo "=====================${model_name} run begin=================="
        $model_name
        sleep 60
        echo "*********************${model_name} run end!!******************"
    done
elif echo ${cur_model_list[@]} | grep -w $model &>/dev/null
then
    echo "=====================${model} run begin=================="
    $model
    sleep 60
    echo "*********************${model} run end!!******************"
else
    echo "model: $model not support!"
fi


save(){
    mv ${log_path} ${save_log_dir}/index
    ln -s ${all_path}/env/bin/python /usr/local/bin/mypython
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${all_path}/env/lib/
    cd ${origin_path}
    echo "==================== begin insert to sql ================="
    mypython save.py --code_commit_id ${benchmark_commit_id} \
                 --image_commit_id ${image_commit_id} \
                 --log_path ${save_log_dir} \
                 --cuda_version ${cuda_version} \
                 --paddle_version ${paddle_version}
    echo "******************** end insert to sql!! *****************"
}

save
