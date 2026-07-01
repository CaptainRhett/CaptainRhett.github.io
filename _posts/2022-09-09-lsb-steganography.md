---
layout: post
title: LSB 图像隐写程序设计
date: 2022-09-09 09:13:23 
description: 北京理工大学课程作业：使用 Python 和 Pillow 实现 LSB 图像隐写的加密与解密。
tags: python image-processing steganography
categories: assignments
---

此为北京理工大学网安专业某学期的某次作业。

# 一、项目背景

## 1. 隐写术

隐写术是一门关于信息隐藏的技巧与科学。所谓信息隐藏，指的是不让除预期接收者之外的任何人知晓信息的传递事件或者信息的内容。

## 2. LSB 隐写术

LSB 隐写术是一种图像隐写术技术，其中通过将每个像素的**最低有效位**替换为要隐藏的消息位来将消息隐藏在图像中。

## 3. 实现原理

为了更好地理解，让我们将数字图像视为像素的二维阵列。每个像素包含取决于其类型和深度的值。使用最广泛的颜色模式 RGB 时，这些值的范围为 0-255。

![RGB 像素示意图](https://img2022.cnblogs.com/blog/2966064/202209/2966064-20220909082237848-432441629.png)
<div class="row mt-3">
    <div class="col-sm mt-3 mt-md-0">
        {% include figure.liquid loading="eager" path="assets/img/lsb.jpg" class="img-fluid rounded z-depth-1" zoomable=true %}
    </div>
</div>

可以使用 ASCII Table 将消息转换为十进制值，然后再转换为二进制。随后逐个迭代像素值，将它们转换为二进制，并将每个最低有效位替换为消息序列中的对应位。

要解码编码图像，只需反转该过程：收集并存储每个像素的最后一位，然后将它们分成 8 位一组，并转换回 ASCII 字符，从而获取隐藏消息。

# 二、项目目标

## 1. 主要目标

编写 **LSB 图像隐写程序**，包括：**加密程序**和**解密程序**。

## 2. 目标分解

- 实现文本信息加密到图像
- 实现图像文件解密到文本

# 三、技术选型

## 1. 如何以二进制方式读写图像文件？

首先安装 Pillow 库。打开控制台后输入以下命令即可自动安装：

```python
pip install pillow
```

然后读取图片：

```python
from PIL import Image  # 从 pillow 库（即 PIL）中导入 Image 类

img = Image.open("../xx.jpg")  # 读取图片存入变量 img 中
print(img.format)  # 输出图片格式 str
print(img.size)  # 输出图片大小信息 tuple = (int, int)
```

获取像素信息：

```python
# 像素载入
pix = img.load()
width = img.size[0]  # .size 方法返回的是一个元组 tuple = (int, int)
height = img.size[1]

# 获取像素点的 RGB 值
rgb_list = []  # 创建一个数组存储 RGB 值
for y in range(height):  # 遍历每一个像素点，将图像看作二维数组
    for x in range(width):  # 如果 x 循环在外层，输出的图像会发生九十度翻转
        r, g, b = pix[x, y]
        rgb_list.append(r)
        rgb_list.append(g)
        rgb_list.append(b)
```

输出图像：

```python
# 输出图像
j = 0
pixels = []  # 以 [(r1, g1, b1), (r2, g2, b2)] 形式存放每个像素点的 RGB 值，用于绘制图像
img_out = Image.new(img.mode, img.size)  # 生成新图像，以原图的格式和大小

# img_out 此时还是一张白纸，下面的代码用于更新 img_out 的像素信息
while j < len(rgb_list):
    pixels.append((rgb_list[j], rgb_list[j + 1], rgb_list[j + 2]))
    j += 3

img_out.putdata(pixels)  # 放置像素信息
img_out.save("img_out2.png")  # 将图像保存到根目录
```

## 2. 信息如何转换？

二进制转文本（解密）：

```python
def bina_to_txt(bina):
    # 只要传入一个由二进制数组成的序列即可翻译成文本
    tex = []
    for i in bina:
        tex.append(chr(int(i, 2)))
    return tex  # 返回一个单字符序列


# 要求 bina 的格式为 ["01010101", "11111111"]
```

文本转二进制（加密）：

```python
def txt_to_bina(txt):
    c = []
    for a in txt:
        c.append("{:0>8}".format(bin(ord(a)).lstrip("0b")))
        # 格式化并将二进制码保存起来
        # 注意要在左侧补齐八位，否则信息会错位

    resultlist = []
    for i in c:
        for j in range(8):
            resultlist.append(i[j])
    return resultlist


# txt 为字符串类型，如 "hello world!"
# print(txt_to_bina("h")) 输出测试
# test_output: ["0", "1", "1", "0", "1", "0", "0", "0"]
```

替换信息位（加密）：

```python
# 替换信息位
i = 0
while i < len(txt_to_bina(txt)):
    temp = list(bin(rgb_list[i]))  # 用 bin() 强制转换，bin() 返回字符串类型
    temp[-1] = txt_to_bina(txt)[i]  # 将 RGB 信息二进制码的最后一位替换成文本二进制码
    rgb_list[i] = int("".join(temp), 2)
    i += 1

# txt_to_bina() 是自定义函数，旨在将文本转化成二进制码，返回一个单字符序列
# 这里直接用第一个像素的 RGB 值作为隐写的开头，所以 rgb_list 和 txt_to_bina() 的 index 是一样的
# 此处可以继续做加密处理

# 特别注意：在 Python 中字符串不能直接修改，replace 方法不会改变原来的 string
# 修改字符串要将字符串转换成序列，修改序列后再将序列转成字符串，实现代码如下：
s = "abcde"
temp = list(s)
temp[-1] = "f"  # 假设要将 s 的最后一位 "e" 修改为 "f"
s = "".join(temp)
```

提取信息位信息：

```python
# 这里直接用的是 "hello world!" 的长度，后期优化可以加个旗帜识别
c = ""
for i in range(96):
    c += bin(rgb_list[i])[-1]  # 图像处理后得到 rgb_list，取二进制码的最后一位

out_list_bin = []
for i in range(12):
    out_list_bin.append(c[i * 8 : (i + 1) * 8])  # 每八位为一组转换出文本

print("".join(bina_to_txt(out_list_bin)))
```
