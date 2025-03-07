PaddlePaddle DeepLab V3+模型开源地址，[PaddlePaddle/models/PaddleCV/deeplabv3+](https://github.com/PaddlePaddle/models/tree/develop/PaddleCV/deeplabv3%2B)。

### 准备数据

运行benchmark之前，请按照[PaddlePaddle/models/PaddleCV/deeplabv3+/README.md](https://github.com/PaddlePaddle/models/blob/develop/PaddleCV/deeplabv3%2B/README.md)所述准备数据、下载预训练模型。

你也可以直接使用以下命令下载预训练模型：

```
wget https://paddle-deeplab.bj.bcebos.com/deeplabv3plus_xception65_initialize.tgz
```

### 执行测试

如果您的数据路径和预训练模型的路径不同于`run.sh`中的默认值，请将`run.sh`中`DATASET_PATH`和`INIT_WEIGHTS_PATH`修改成您本地的路径。然后执行`run.sh`进行速度测试。

单卡测试命令：

```
$ CUDA_VISIBLE_DEVICES="0" ./run.sh speed
```

四卡测试命令：

```
$ CUDA_VISIBLE_DEVICES="0,1,2,3" ./run.sh speed
```

#### 说明

当前仓库中，我们对reader进行了优化，通过配置multiprocessing多进程读取数据，来优化模型训练的总体速度。
待[PaddlePaddle/models/PaddleCV/deeplabv3+](https://github.com/PaddlePaddle/models/tree/develop/PaddleCV/deeplabv3%2B)进行相应的更新之后，我们将以[PaddlePaddle/models/PaddleCV/deeplabv3+](https://github.com/PaddlePaddle/models/tree/develop/PaddleCV/deeplabv3%2B)中的版本为准。
