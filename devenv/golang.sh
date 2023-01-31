#!/bin/bash

# 建议安装前清空`GOROOT`、`GOBIN`等环境变量
$ curl -sSL https://raw.githubusercontent.com/voidint/g/master/install.sh | bash
$ echo "unalias g" >> ~/.bashrc # 可选。若其他程序（如'git'）使用了'g'作为别名。
$ source "$HOME/.g/env"