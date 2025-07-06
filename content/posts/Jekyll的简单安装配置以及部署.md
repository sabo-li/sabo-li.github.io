+++
layout = "article"
title = "Jekyll的简单安装配置以及部署"
copyright = true
comment = true
date = 2018-09-19 01:42:27
tags = ["Jekyll","部署","配置"]
categories = "Jekyll"
+++

> Jekyll 是一个简单的博客形态的静态站点生产机器

准备工作
======

在本地使用Jekyll框架，需要电脑中已安装[Git](http://git-scm.com)、[Ruby](http://ruby-lang.org)

安装Git
------
- Windows：下载并安装 [Git](https://git-scm.com/download/win)
- Mac：使用 [Homebrew](https://brew.sh/index_zh-cn) ：`brew install git --with-gettext`
- Linux (Ubuntu, Debian)：`sudo apt-get install git-core`
- Linux (Fedora, Red Hat, CentOS)：`sudo yum install git-core`

<!-- more -->

安装Ruby
------

Ruby 有多个版本，建议使用[rvm (Ruby Version Manager)](https://rvm.io)来管理Ruby的版本。对于windows小伙伴来说，建议[使用Ruby安装程序](https://rubyinstaller.org/)进行安装

安装Ruby

``` bash
# 安装 Jekyll 需要 Ruby 版本 >= 2.1.0
rvm install 2.5.1
```

使用[ruby-china的源镜像](https://ruby-china.org/wiki/ruby-mirror)
``` bash
# 替换 rvm 的配置信息
echo "ruby_url=https://cache.ruby-china.com/pub/ruby" > ~/.rvm/user/db
```

安装Jekyll
======

``` bash
gem install bundler jekyll
```

国内小伙伴建议先使用[ruby-china的Gem镜像](https://gems.ruby-china.com)

``` bash
# 替换Gem源
gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/

# 替换 Bundler 的 Gem 源代码镜像命令
bundle config mirror.https://rubygems.org https://gems.ruby-china.com
```

使用Jekyll
======

初始化
------

``` bash
Jekyll new 博客文件夹

# 进入博客目录
cd 博客文件夹

# 安装依赖
bundle install
```

查看`jekyll new`更多帮助
``` bash
jekyll new -h
```

本地启动
------

``` bash
# s 是 server

jekyll s
```

然后在可以本地浏览器打开http://localhost:4000，就可以访问启动好的博客啦

查看`jekyll server`更多帮助
``` bash
jekyll s -h
```

使用Next主题
------

我使用的[Next](https://github.com/Simpleyyt/jekyll-theme-next)主题

``` bash
git clone https://github.com/Simpleyyt/jekyll-theme-next
cd jekyll-theme-next
bundle install
jekyll s # 启动
```

此时`项目目录`就是`jekyll-theme-next`，修改`项目目录`下的`_config.yml`文件, 必须重启Hexo本地服务，即可在本地看到新的主题样式

配置
------

Jekyll大部份的的配置在`项目目录`下的`_config.yml`中，根据[Jekyll官方文档](http://jekyllrb.com)，[Jekyll中文文档](http://jekyll.com.cn)和[Next文档](http://theme-next.simpleyyt.com/)按照自己需要改动即可


写文章
------

需要在`_posts`文件夹中创建一个新的文件，文件格式为`年-月-日-标题.md`，`年`是四位数字，`月`和`日`都是两位

更多说明，参考[Jekyll 写作](https://www.jekyll.com.cn/docs/posts/)


部署
======

部署的基本原理同[Hexo的部署](/2018/09/17/Hexo%E7%9A%84%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE%E4%BB%A5%E5%8F%8A%E9%83%A8%E7%BD%B2#部署), 但是Jekyll没有类与Hexo的`hexo-deployer-git`，所以需要手动把这静态资源的目录`_site`的中内容提交到远程就可以了

---