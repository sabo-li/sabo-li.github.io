+++
layout = "article"
title = "Hexo的安装配置以及部署"
copyright = true
comment = true
date = 2018-09-17 15:35:17
tags = ["Hexo","部署","配置"]
categories = "Hexo"
+++


> Hexo是一个快速、简洁且高效的博客框架

准备工作
======


在本地使用hexo框架，需要电脑中已安装[Git](http://git-scm.com)、[Node.js](http://nodejs.org)

安装Git
------
- Windows：下载并安装 [Git](https://git-scm.com/download/win)
- Mac：使用 [Homebrew](https://brew.sh/index_zh-cn) ：`brew install git --with-gettext`
- Linux (Ubuntu, Debian)：`sudo apt-get install git-core`
- Linux (Fedora, Red Hat, CentOS)：`sudo yum install git-core`

<!-- more -->

安装Node.js
------

Node.js 有多个版本，建议使用[nvm (Node Version Manager)](https://github.com/creationix/nvm)来管理node的版本。对于windows小伙伴来说，建议[使用Node.js安装程序](https://nodejs.org/zh-cn/download/)进行安装，喜欢折腾的小伙伴可以试试[nvm-windows](https://github.com/coreybutler/nvm-windows)

安装Node.js

```
nvm install stable
```

使用[淘宝的 Node.js 镜像](http://npm.taobao.org/mirrors/node)
``` bash
# nvm 使用镜像安装
NVM_NODEJS_ORG_MIRROR=https://npm.taobao.org/mirrors/node nvm install stable

# windows小伙伴如果使用 nvm-windows，设置镜像
nvm node_mirror https://npm.taobao.org/mirrors/node/
```

安装Hexo
======

``` bash
npm install -g hexo-cli
```

国内小伙伴建议使用[淘宝 NPM 镜像](https://npm.taobao.org/)

``` bash
# 安装cnpm
npm install -g cnpm --registry=https://registry.npm.taobao.org
# 使用cnpm安装hexo
cnpm install -g hexo-cli

# windows小伙伴如果使用 nvm-windows，设置npm镜像
nvm npm_mirror https://npm.taobao.org/mirrors/npm/
```

使用hexo
======

初始化
------

``` bash
# --no-install 是使用初始化后跳过npm install
hexo init 项目文件夹 --no-install

# 进入项目目录
cd 项目文件夹

# 安装依赖
cnpm install
```

查看`hexo init`更多帮助
``` bash
hexo init -h
```

本地启动
------

``` bash
# s 是 server

hexo s
```

然后会输出以下信息

```
INFO  Start processing
INFO  Hexo is running at http://localhost:4000 . Press Ctrl+C to stop.
```

然后在可以本地浏览器打开http://localhost:4000，就可以访问启动好的博客啦

查看`hexo server`更多帮助，也可参考[Hexo 服务器](https://hexo.io/zh-cn/docs/server)
``` bash
hexo s -h
```

安装Next主题
------

我使用的[Next](https://github.com/theme-next/hexo-theme-next)主题

``` bash
cd 项目文件夹
git clone https://github.com/theme-next/hexo-theme-next themes/next
```

将`项目目录`下的`_config.yml`配置文件中的`theme: landscape`改为`theme: next`, 然后重启Hexo本地服务，即可在本地看到新的主题样式

如果想改为其他主题，请前往[Hexo Themes](https://hexo.io/themes/)，自行选取后，按照说明文档要求自行修改配置

配置
------

Hexo大部份的的配置在`项目目录`下的`_config.yml`中，根据[Hexo官方文档](https://hexo.io/zh-cn/docs/configuration)按照自己需要改动即可

自己想个性化配置，例如在文章底部增加版权信息，网站底部字数统计等更多，可以参考[Hexo的Next主题个性化配置教程](https://segmentfault.com/a/1190000009544924)，当然这个参考大部分都是`next 5.x`版本，新的版本还是建议参考[theme-next](https://github.com/theme-next)中的配置

写文章
------

创建一个新的文章

``` bash
hexo new 文章名
```

更多说明，参考[Hexo 写作](https://hexo.io/zh-cn/docs/writing)


部署
======

安装`hexo-deployer-git`
------

首先安装[hexo-deployer-git](https://github.com/hexojs/hexo-deployer-git)

``` bash
cnpm install hexo-deployer-git --save
```

创建仓库
------

下面要用到git仓库，创建github.io仓库
1. 点击`New repository`
2. 输入`Repository name`，必需为`用户名.github.io`格式
3. 点击按钮`Create repository`
4. 进入仓库`用户名.github.io`，点击`Settings`，找到`GitHub Pages`模块
5. 点击`Choose a theme`选择一个页面主题
6. 然后这个静态资源存放的远程仓库地址就创建了

指定仓库位置
------

下面将生成好的静态资源推到远程仓库，先修改博客项目目录下的`_config.yml`

``` yaml
deploy:
  type: git
  repo: 生成好的静态资源存放的远程仓库地址
  branch: [分支名称]
```

部署
------

先生成文件后，再将静态资源提交到远程仓库

``` bash
# d 是 deploy
# g 是 generate

hexo g -d
# 或者
hexo d -g
```

等个一会儿后，在浏览器打开`https://用户名.github.io`就可以访问博客网站了

---