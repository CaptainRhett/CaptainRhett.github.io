---
layout: post
title: python配置config的若干种方法
date: 2026-03-16 12:08:24 
description: 科学管理项目，助力高效科研
tags: python
---

Python 项目中的配置管理，常见方式包括：**模块常量、字典、数据类、环境变量、配置文件、命令行参数，以及多层配置合并**。不同方法适合不同规模和部署场景。

# 1. 使用 Python 模块保存配置

直接创建一个 `config.py`：

```python
# config.py

OPENAI_API_KEY = "sk-xxx"
OPENAI_MODEL = "gpt-4"
API_BASE_URL = "https://api.openai.com"
DEBUG = False
```

其他文件中导入：

```python
from config import OPENAI_MODEL, DEBUG

print(OPENAI_MODEL)
print(DEBUG)
```

也可以整体导入：

```python
import config

print(config.OPENAI_MODEL)
```

### 优点

* 最简单
* 不需要额外解析
* 支持 Python 表达式
* 适合小型项目

### 缺点

* API Key 等敏感信息容易被提交到 Git
* 修改配置相当于修改代码
* 不适合开发、测试、生产多环境部署

适合：

```text
个人脚本
课程实验
小型原型项目
```

---

# 2. 使用字典保存配置

```python
CONFIG = {
    "openai_api_key": "sk-xxx",
    "openai_model": "gpt-4",
    "api_base_url": "https://api.openai.com",
    "debug": False,
}
```

使用：

```python
model = CONFIG["openai_model"]
debug = CONFIG["debug"]
```

为了避免键不存在时报错，也可以使用：

```python
model = CONFIG.get("openai_model", "gpt-4")
```

还可以按照功能分组：

```python
CONFIG = {
    "openai": {
        "api_key": "sk-xxx",
        "model": "gpt-4",
        "base_url": "https://api.openai.com",
    },
    "database": {
        "host": "localhost",
        "port": 3306,
        "name": "agent_db",
    },
    "application": {
        "debug": False,
        "log_level": "INFO",
    },
}
```

访问方式：

```python
model = CONFIG["openai"]["model"]
db_host = CONFIG["database"]["host"]
```

### 优点

* 灵活
* 易于组织嵌套配置
* 很容易和 JSON、YAML 等配置文件结合

### 缺点

* 没有严格的类型检查
* 键名写错后不容易提前发现
* IDE 自动补全能力较弱

例如：

```python
CONFIG["openai_modle"]
```

这里把 `model` 写成了 `modle`，通常只有运行时才能发现错误。

---

# 3. 使用普通类保存配置

```python
class Config:
    OPENAI_API_KEY = "sk-xxx"
    OPENAI_MODEL = "gpt-4"
    API_BASE_URL = "https://api.openai.com"
    DEBUG = False
```

使用：

```python
print(Config.OPENAI_MODEL)
```

也可以实例化：

```python
class Config:
    def __init__(self):
        self.openai_api_key = "sk-xxx"
        self.openai_model = "gpt-4"
        self.api_base_url = "https://api.openai.com"
        self.debug = False


config = Config()
print(config.openai_model)
```

### 优点

* 比字典结构清晰
* 支持继承、方法和属性
* IDE 自动补全较好

### 缺点

* 需要手动编写初始化代码
* 类型约束仍然较弱
* 大量字段时比较冗长

---

# 4. 使用 `dataclass` 管理配置

这就是你上一段代码采用的核心方法。

```python
from dataclasses import dataclass


@dataclass
class Config:
    openai_api_key: str
    openai_model: str = "gpt-4"
    api_base_url: str = "https://api.openai.com"
    debug: bool = False
```

创建配置：

```python
config = Config(
    openai_api_key="sk-xxx",
    debug=True,
)
```

访问：

```python
print(config.openai_model)
print(config.debug)
```

输出：

```text
gpt-4
True
```

## 不可修改的配置

```python
@dataclass(frozen=True)
class Config:
    openai_api_key: str
    openai_model: str = "gpt-4"
    debug: bool = False
```

下面的操作会报错：

```python
config.openai_model = "new-model"
```

因为 `frozen=True` 表示对象创建后不可修改。

## 带默认工厂

对于列表、字典等可变类型，应该使用 `default_factory`：

```python
from dataclasses import dataclass, field


@dataclass
class Config:
    allowed_hosts: list[str] = field(default_factory=list)
    model_options: dict[str, str] = field(default_factory=dict)
```

不要直接写：

```python
allowed_hosts: list[str] = []
```

因为多个实例可能共享同一个列表对象。

### 优点

* 结构清晰
* 支持类型标注
* IDE 自动补全较好
* 自动生成 `__init__`、`__repr__` 等方法
* 适合中小型项目

### 缺点

* 类型标注默认不会自动进行运行时验证
* 仍然需要编写从环境变量或配置文件读取的逻辑

---

# 5. 使用环境变量

环境变量适合保存：

* API Key
* 数据库密码
* 服务地址
* 部署环境
* Debug 开关

例如，在 Linux 或 macOS 中设置：

```bash
export OPENAI_API_KEY="sk-xxx"
export OPENAI_MODEL="gpt-4"
export DEBUG="true"
```

Python 中读取：

```python
import os

api_key = os.getenv("OPENAI_API_KEY", "")
model = os.getenv("OPENAI_MODEL", "gpt-4")
debug = os.getenv("DEBUG", "false").lower() in {
    "1",
    "true",
    "yes",
}
```

## 封装成配置类

```python
import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Config:
    openai_api_key: str
    openai_model: str
    debug: bool

    @classmethod
    def from_env(cls) -> "Config":
        return cls(
            openai_api_key=os.getenv("OPENAI_API_KEY", ""),
            openai_model=os.getenv("OPENAI_MODEL", "gpt-4"),
            debug=os.getenv("DEBUG", "false").lower()
            in {"1", "true", "yes"},
        )
```

使用：

```python
config = Config.from_env()
```

这里使用 `@classmethod` 比 `@staticmethod` 更有扩展性：

```python
return cls(...)
```

意味着子类调用时，可以返回对应的子类实例。

### 优点

* 不需要把敏感信息写入代码
* 适合 Docker、服务器、CI/CD 和云部署
* 开发环境与生产环境可以使用不同值

### 缺点

* 所有环境变量最初都是字符串
* 布尔值、整数、列表需要手动转换
* 配置较多时管理不方便

---

# 6. 使用 `.env` 文件

`.env` 文件本质上是将环境变量写到文件中。

例如：

```env
OPENAI_API_KEY=sk-xxx
OPENAI_MODEL=gpt-4
API_BASE_URL=https://api.openai.com
DEBUG=true
MAX_RETRIES=3
```

Python 中读取：

```python
import os

from dotenv import load_dotenv

load_dotenv()

api_key = os.getenv("OPENAI_API_KEY")
model = os.getenv("OPENAI_MODEL", "gpt-4")
```

一般应该将 `.env` 加入 `.gitignore`：

```gitignore
.env
```

同时提供一个不包含真实密钥的模板：

```text
.env.example
```

内容例如：

```env
OPENAI_API_KEY=
OPENAI_MODEL=gpt-4
API_BASE_URL=https://api.openai.com
DEBUG=false
MAX_RETRIES=3
```

### 优点

* 本地开发方便
* 敏感配置与代码分离
* 可以为不同开发者配置不同的环境

### 缺点

* `.env` 文件不适合复杂嵌套配置
* 需要注意不能提交真实密钥
* 所有值仍然要进行类型转换

---

# 7. 使用 INI 配置文件

Python 标准库提供了 `configparser`。

`config.ini`：

```ini
[openai]
api_key = sk-xxx
model = gpt-4
base_url = https://api.openai.com

[application]
debug = true
max_retries = 3
```

读取：

```python
import configparser

parser = configparser.ConfigParser()
parser.read("config.ini", encoding="utf-8")

api_key = parser["openai"]["api_key"]
model = parser["openai"].get("model", "gpt-4")
debug = parser["application"].getboolean("debug")
max_retries = parser["application"].getint("max_retries")
```

也可以封装：

```python
from dataclasses import dataclass


@dataclass(frozen=True)
class Config:
    api_key: str
    model: str
    debug: bool
    max_retries: int


def load_config(path: str) -> Config:
    parser = configparser.ConfigParser()
    parser.read(path, encoding="utf-8")

    return Config(
        api_key=parser["openai"]["api_key"],
        model=parser["openai"].get("model", "gpt-4"),
        debug=parser["application"].getboolean("debug"),
        max_retries=parser["application"].getint(
            "max_retries",
        ),
    )
```

### 优点

* Python 标准库原生支持
* 配置分组清晰
* 支持整数、布尔值等转换

### 缺点

* 不适合复杂嵌套结构
* 表达列表、对象等数据比较麻烦

---

# 8. 使用 JSON 配置文件

`config.json`：

```json
{
  "openai": {
    "api_key": "sk-xxx",
    "model": "gpt-4",
    "base_url": "https://api.openai.com"
  },
  "application": {
    "debug": true,
    "max_retries": 3
  }
}
```

读取：

```python
import json
from pathlib import Path


def load_config(path: str) -> dict:
    config_path = Path(path)

    with config_path.open(
        "r",
        encoding="utf-8",
    ) as file:
        return json.load(file)
```

使用：

```python
config = load_config("config.json")

model = config["openai"]["model"]
debug = config["application"]["debug"]
```

### 优点

* 格式通用
* 支持嵌套结构、列表和对象
* Python 标准库直接支持

### 缺点

* 标准 JSON 不支持注释
* 不适合保存密钥
* 键名没有类型检查

---

# 9. 使用 TOML 配置文件

TOML 很适合 Python 项目配置。

`config.toml`：

```toml
[openai]
api_key = "sk-xxx"
model = "gpt-4"
base_url = "https://api.openai.com"

[application]
debug = true
max_retries = 3

[database]
host = "localhost"
port = 3306
```

在较新的 Python 中，可以使用标准库 `tomllib` 读取：

```python
import tomllib
from pathlib import Path


def load_config(path: str) -> dict:
    config_path = Path(path)

    with config_path.open("rb") as file:
        return tomllib.load(file)
```

使用：

```python
config = load_config("config.toml")

print(config["openai"]["model"])
print(config["database"]["port"])
```

### 优点

* 格式清晰
* 支持嵌套、列表、整数和布尔值
* 比 JSON 更适合人工编辑
* Python 项目中使用广泛

### 缺点

* 密钥仍然不应直接放入版本控制
* 读取后通常仍然是字典

---

# 10. 使用 YAML 配置文件

`config.yaml`：

```yaml
openai:
  api_key: sk-xxx
  model: gpt-4
  base_url: https://api.openai.com

application:
  debug: true
  max_retries: 3

database:
  host: localhost
  port: 3306
```

读取后通常得到嵌套字典：

```python
config = {
    "openai": {
        "model": "gpt-4",
    }
}
```

### 优点

* 可读性较好
* 适合复杂嵌套配置
* 常用于机器学习、深度学习和实验配置

### 缺点

* 需要第三方库
* 缩进错误可能导致解析问题
* 部分字符串可能被自动解释为特殊类型
* 不适合直接保存敏感密钥

YAML 常用于：

```text
训练参数
数据集配置
模型结构配置
实验配置
联邦学习参数
```

例如：

```yaml
experiment:
  name: fedrep_cifar10
  seed: 42

federated:
  num_clients: 20
  communication_rounds: 100
  local_epochs: 8

model:
  architecture: resnet18
  num_classes: 10

defense:
  num_buckets: 6
  window_size: 3
  privacy_level: 0.5
```

---

# 11. 使用命令行参数

通过 `argparse` 接收运行时配置。

```python
import argparse


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--model",
        default="gpt-4",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
    )
    parser.add_argument(
        "--max-retries",
        type=int,
        default=3,
    )

    return parser.parse_args()
```

使用：

```python
args = parse_args()

print(args.model)
print(args.debug)
```

运行：

```bash
python main.py --model gpt-4 --debug --max-retries 5
```

### 优点

* 每次运行可以快速修改参数
* 适合实验脚本和训练程序
* 不需要修改配置文件

### 缺点

* 参数多时命令非常长
* 不适合存储密钥
* 复杂嵌套配置不方便

尤其适合机器学习实验：

```bash
python train.py \
  --dataset cifar10 \
  --model resnet18 \
  --num-clients 20 \
  --local-epochs 8 \
  --seed 42
```

---

# 12. 使用不同环境的配置类

可以为开发、测试、生产环境分别定义配置。

```python
from dataclasses import dataclass


@dataclass(frozen=True)
class BaseConfig:
    debug: bool = False
    database_url: str = ""
    log_level: str = "INFO"


@dataclass(frozen=True)
class DevelopmentConfig(BaseConfig):
    debug: bool = True
    database_url: str = "sqlite:///development.db"
    log_level: str = "DEBUG"


@dataclass(frozen=True)
class TestingConfig(BaseConfig):
    debug: bool = True
    database_url: str = "sqlite:///testing.db"
    log_level: str = "DEBUG"


@dataclass(frozen=True)
class ProductionConfig(BaseConfig):
    debug: bool = False
    database_url: str = ""
    log_level: str = "WARNING"
```

按照环境选择：

```python
import os


def get_config() -> BaseConfig:
    environment = os.getenv(
        "APP_ENV",
        "development",
    )

    config_map = {
        "development": DevelopmentConfig,
        "testing": TestingConfig,
        "production": ProductionConfig,
    }

    config_class = config_map.get(environment)

    if config_class is None:
        raise ValueError(
            f"Unknown environment: {environment}"
        )

    return config_class()
```

运行时设置：

```bash
export APP_ENV=production
python main.py
```

### 优点

* 不同环境边界清晰
* 适合 Web 服务和正式部署

### 缺点

* 配置较多时类的数量会增加
* 继承层级复杂后不容易维护

---

# 13. 多层配置覆盖

实际项目中，通常不会只使用一种配置方式，而是按照优先级合并。

常见优先级：

```text
默认配置
   ↓
配置文件
   ↓
环境变量
   ↓
命令行参数
```

后面的配置覆盖前面的配置。

例如默认配置：

```python
config = {
    "model": "gpt-4",
    "debug": False,
    "max_retries": 3,
}
```

配置文件覆盖：

```python
file_config = {
    "model": "gpt-4-mini",
}

config.update(file_config)
```

环境变量覆盖：

```python
import os

if model := os.getenv("OPENAI_MODEL"):
    config["model"] = model
```

命令行覆盖：

```python
if args.model is not None:
    config["model"] = args.model
```

最后优先级为：

```text
命令行参数 > 环境变量 > 配置文件 > 默认值
```

这种方式适合正式项目。

---

# 14. 推荐的组合方式

## 小型脚本

使用 Python 模块常量：

```python
# config.py
MODEL = "gpt-4"
DEBUG = True
```

## 普通课程项目

使用：

```text
dataclass + .env
```

例如：

```python
import os
from dataclasses import dataclass

from dotenv import load_dotenv

load_dotenv()


@dataclass(frozen=True)
class Config:
    api_key: str
    model: str
    debug: bool

    @classmethod
    def from_env(cls) -> "Config":
        return cls(
            api_key=os.getenv("OPENAI_API_KEY", ""),
            model=os.getenv("OPENAI_MODEL", "gpt-4"),
            debug=os.getenv("DEBUG", "false").lower()
            in {"1", "true", "yes"},
        )
```

## 机器学习或科研实验

使用：

```text
YAML/TOML 配置文件 + argparse 命令行覆盖
```

例如：

```bash
python train.py \
  --config configs/cifar10.yaml \
  --seed 42
```

## Web 服务或生产系统

使用：

```text
dataclass 配置对象
+ 环境变量
+ 配置校验
+ 开发/测试/生产环境区分
```

敏感信息放环境变量：

```env
OPENAI_API_KEY=...
DATABASE_PASSWORD=...
```

非敏感复杂配置放 TOML 或 YAML：

```toml
[application]
debug = false
max_retries = 3
```

---

# 15. 各种方法对比

| 方法          |   类型支持 |    敏感信息 | 复杂配置 | 适用场景      |
| ----------- | -----: | ------: | ---: | --------- |
| Python 常量   |     较好 |     不适合 |   一般 | 小型脚本      |
| 字典          |     较弱 |     不适合 |   较好 | 简单项目      |
| 普通类         |     一般 |     不适合 |   一般 | 中小项目      |
| `dataclass` |     较好 | 需结合环境变量 |   较好 | 中小型项目     |
| 环境变量        | 全部为字符串 |      适合 |   较弱 | 部署和密钥     |
| `.env`      | 全部为字符串 |  适合本地开发 |   较弱 | 本地项目      |
| INI         |     一般 |     不适合 |   一般 | 传统应用      |
| JSON        |     较好 |     不适合 |   较好 | 通用配置      |
| TOML        |     较好 |     不适合 |   较好 | Python 项目 |
| YAML        |     较好 |     不适合 |   很好 | 机器学习实验    |
| 命令行参数       |     较好 |     不适合 |   一般 | 实验和脚本     |

比较合理的方案是：

```text
.env
  负责 API Key、API 地址等部署配置

Config dataclass
  负责类型定义和统一访问

YAML 或 TOML
  负责较复杂的模型、实验和业务参数

argparse
  负责临时覆盖实验参数
```

即：

```text
默认值 < YAML/TOML < .env 环境变量 < 命令行参数
```

这也是科研代码和工程项目中较常见、可维护性较好的配置结构。
