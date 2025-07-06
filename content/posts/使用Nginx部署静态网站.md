+++
layout = "article"
title = "使用Nginx部署静态网站"
copyright = true
comment = true
date = 2018-09-18 00:30:50
tags = ["Nginx", "部署", "静态"]
categories = "Nginx"
+++

> Nginx（发音同engine x）是一个异步框架的 Web服务器，也可以用作反向代理，负载平衡器 和 HTTP缓存

配置静态网站
======

``` nginx
server {
    listen 80; # 端口号
    server_name example.com; # 域名

    location / {
        root /var/www/project_dir; # 静态项目路径
        index index.html; # 网站初始页
        error_page 404 /index.html; # 静态页面重定向服务器错误页面
    }
}
```
<!-- more -->

将以上配置存到一个文件中，然后编辑`nginx.conf`（使用`nginx -t`可以看到具体路径），用`include 配置文件的路径;`引入到配置中，退出编辑器，使用`nginx -t`来测试配置是否有误，有问题的改好后再进行下一步，使用`nginx -s reload`重新加载Nginx配置

---