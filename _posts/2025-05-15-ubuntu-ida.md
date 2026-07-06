---
layout: post
title: Ubuntu安装ida（使用conda环境）
date: 2022-09-09 09:13:23 
description: ubuntu安装ida
tags: ida
---
# Ubuntu安装ida（使用conda环境）

## 创建conda环境

建议给 IDA 单独建一个环境，不要直接用 `base`。

```bash
conda create -n ida92 python=3.13 -y
conda activate ida92
```

查看 Conda 环境路径：

```bash
echo $CONDA_PREFIX
```

一般会类似：

```bash
/home/username/miniconda3/envs/ida92
```

## 2. 找到conda环境里的libpython

执行：

```bash
find "$CONDA_PREFIX" -name "libpython3*.so*"
```

你大概率会看到类似：

```
/home/username/miniconda3/envs/ida92/lib/libpython3.13.so
/home/username/miniconda3/envs/ida92/lib/libpython3.13.so.1.0
```

IDA 要绑定的是这个动态库，一般用：

```
/home/username/miniconda3/envs/ida92/lib/libpython3.13.so.1.0
```

## 3. 用 idapyswitch 切换到 Conda Python

假设你的 IDA 安装目录是：

```
/home/username/ida-pro-9.2
```

那么执行：

```
/home/username/ida-pro-9.2/idapyswitch --force-path "$CONDA_PREFIX/lib/libpython3.13.so.1.0"
```

如果你的 IDA 安装目录是：

```
/var/tmp/ida-pro-9.2
```

则执行：

```
/var/tmp/ida-pro-9.2/idapyswitch --force-path "$CONDA_PREFIX/lib/libpython3.13.so.1.0"
```

也可以写成绝对路径：

```
/var/tmp/ida-pro-9.2/idapyswitch --force-path /home/username/miniconda3/envs/ida92/lib/libpython3.13.so.1.0
```

------

## 4. 从 Conda 环境启动 IDA

不要直接双击 IDA，先在终端激活 Conda 环境后启动：

```
conda activate ida92
/var/tmp/ida-pro-9.2/ida
```

进入 IDA 后，在 Python Console 里执行：

```
import sys
print(sys.version)
print(sys.prefix)
```

如果输出里能看到：

```
/home/username/miniconda3/envs/ida92
```

说明 IDAPython 已经在使用你的 Conda 环境。