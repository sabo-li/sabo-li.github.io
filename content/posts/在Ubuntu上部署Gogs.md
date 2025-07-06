+++
layout = "article"
title = "在Ubuntu上部署Gogs"
copyright = true
comment = true
date = 2018-09-22 23:05:47
tags = ["部署", "Gogs"]
categories = "Gogs"
+++

> Gogs 是一款极易搭建的自助 Git 服务。

为什么选择Gogs
======
我之前也部署过Gitlab，但是太吃资源了，Gogs相比就很轻量，正好合适搭建私人Git服务器。

<!-- more -->

安装Nginx和数据库
======
要部署Gogs，需要安装Nginx和数据库

安装Nginx

``` bash
sudo apt-get update
sudo apt-get install nginx
```

安装和初始化数据库
------

Gogs支持MySQL，PostgreSQL，SQLite3，MSSQL和TiDB，这里我选择PostgreSQL

``` bash
sudo apt-get update
sudo apt-get install postgresql
```

命令执行完毕后，配置数据库

### 设置密码
安装完毕后需要更改postgres用户的密码，否则就没法使用这个数据库服务器。以postgres这个系统用户的身份运行psql命令

``` bash
sudo -u postgres psql
```

进入psql命令接口

``` sql
ALTER USER postgres WITH PASSWORD '这里写postgres用户的新密码';
```

执行完毕后，`\q`退出

### 创建PostgreSQL的新用户和数据库

``` bash
# -D 没有创建数据库的权限
# -A 没有新建用户的权限
# -P 为新用户设置密码
sudo -u postgres createuser -D -A -P gogs # 创建用户时会提示你输入密码

# 创建一个数据库gogs-db，以 gogs 作为它的所有者
sudo -u postgres createdb -O gogs gogs-db
```

安装Gogs
======

创建新用户
------
为什么创建一个新的用户呢？之前我也一直在纠结。后来，发生了密钥冲突，这个就是因为管理员密钥月Gogs运行应用的用户密钥一样所导致的，如果Gogs运行应用的用户不是管理员也就不会有这个情况了

``` bash
useradd -m git
# 切换到git用户
sudo su git
# 切换到git用户的HOME目录
cd ~
```

下面操作都是在git用户下操作

下载Gogs程序
------

我使用的是[Gogs二进制安装包](https://gogs.io/docs/installation/install_from_binary#%E5%A6%82%E4%BD%95%E9%80%9A%E8%BF%87%E4%BA%8C%E8%BF%9B%E5%88%B6%E5%8D%87%E7%BA%A7%EF%BC%9F)，下载的是Linux，64位，TAR.GZ，可以用`curl`或者`wget`下载文件

示例
``` bash
# 使用curl
curl -O https://dl.gogs.io/0.11.66/gogs_0.11.66_linux_amd64.tar.gz
# 使用 wget
wget https://dl.gogs.io/0.11.66/gogs_0.11.66_linux_amd64.tar.gz
```

解压

``` bash
tar -zxvf gogs_0.11.66_linux_amd64.tar.gz
```

启动Gogs服务
------

``` bash
cd gogs
./gogs web
```

然后再浏览器输入`IP:3000`，端口号默认是3000，这个时候进入应该进入的是`/install`，具体就是一些Gogs程序的基本设置，填完提交后，进入命令行按`ctl+c`结束程序，就可以进行下一步了


Gogs守护进程
======

这部分主要修改Gogs项目中的`scripts`里的文件，以下文件请根据实际情况做修改

``` bash
vim scripts/init/debian/gogs
```

``` bash
#! /bin/sh
### BEGIN INIT INFO
# Provides:          gogs
# Required-Start:    $syslog $network
# Required-Stop:     $syslog
# Should-Start:      mysql postgresql
# Should-Stop:       mysql postgresql
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: A self-hosted Git service written in Go.
# Description:       A self-hosted Git service written in Go.
### END INIT INFO

# Author: Danny Boisvert

# Do NOT "set -e"

# PATH should only include /usr/* if it runs after the mountnfs.sh script
PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="Gogs"
NAME=gogs
SERVICEVERBOSE=yes
PIDFILE=/var/run/$NAME.pid
SCRIPTNAME=/etc/init.d/$NAME
WORKINGDIR=/home/git/gogs # 这是Gogs运行应用的项目路径
DAEMON=$WORKINGDIR/$NAME
DAEMON_ARGS="web"
USER=git # 这是Gogs运行应用的用户
# 以下不做修改
```

然后退出，接着修改下一个文件

``` bash
vim scripts/systemd/gogs.service
```

``` bash
[Unit]
Description=Gogs
After=syslog.target
After=network.target
# 修改这里，如果用到其他服务的话
# After=mariadb.service mysqld.service postgresql.service memcached.service redis.service
# 我这只用到了postgresql
After=postgresql.service

[Service]
Type=simple
User=git # 这是Gogs运行应用的用户
Group=git # 该用户的组
WorkingDirectory=/home/git/gogs # 这是Gogs运行应用的项目路径
# /home/git/gogs/gogs这是Gogs运行应用程序的位置
ExecStart=/home/git/gogs/gogs web
Restart=always
# Environment=USER后是Gogs运行应用的用户
# HOME是该用户的HOME路径
Environment=USER=git HOME=/home/git
# 以下不做修改
```

修改完之后，软连接文件到相应位置

``` bash
# 退出git用户，切到管理员
exit

sudo ln -s /home/git/gogs/scripts/init/debian/gogs /etc/init.d/gogs
sudo ln -s /home/git/gogs/scripts/systemd/gogs.service  /etc/systemd/system/gogs.service
```

然后就可以使用`service`命令来管理Gogs的服务状态了

``` bash
# 例如，启动gogs服务
sudo service gogs start
```

Nginx反向代理Gogs服务
======

只需要在Nginx配置里新引入一个`server`就可以了

``` nginx
server {
    listen 80; # 端口号
    server_name gogs.example.com; # 域名

    location / {
        proxy_pass http://localhost:3000; # Gogs 服务地址
    }
}
```

添加完后，执行`sudo nginx -t`查看是否有误，然后使用`sudo nginx -s reload`重载Nginx，就可以了

---