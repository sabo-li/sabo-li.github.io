+++
layout = "article"
title = "向Gogs仓库推送代码后，自动更新远程仓库的代码"
copyright = true
comment = true
date = 2018-09-20 21:38:59
tags = ["Gogs", "自动部署"]
categories = "[Gogs]"
+++


> Gogs服务同博客静态服务在同一服务器，我想每次push后，Gogs接受成功后会自动更新远程服务器的资源


<!-- more -->

用Hexo框架写完博客后，使用`hexo d -g`会将生成好的静态资源推送到自己的远程仓库，远程服务器每次都要登上去手动`git pull`，而写个`crontab`有又觉得不怎么好，然后就找到了[Git 服务端钩子](https://git-scm.com/book/zh/v2/%E8%87%AA%E5%AE%9A%E4%B9%89-Git-Git-%E9%92%A9%E5%AD%90)`post-receive`此挂钩在整个过程完结以后运行，可以用来更新其他系统服务或者通知用户

这个钩子在Gogs的`gogs-repositories`目录下，每一个仓库目录下都有`hooks/post-receive`这个钩子，将以下改好后添加到文件内即可

``` bash
unset GIT_DIR
NowPath=`pwd`
DeployPath="/var/www/blog" # 要将这里的路径修改为远程服务器上存放博客静态资源的目录
cd $DeployPath
git pull origin master
cd $NowPath
exit 0
```

---