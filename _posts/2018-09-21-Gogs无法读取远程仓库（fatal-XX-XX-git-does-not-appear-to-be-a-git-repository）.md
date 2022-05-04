---
layout: article
title: 'Gogs无法读取远程仓库（fatal: XX/XX.git does not appear to be a git repository）'
copyright: true
comment: true
date: 2018-09-21 17:14:52
tags: [Gogs]
categories: Gogs
key: post-7
---


> 错误描述：`fatal: 'XX/XX.git' does not appear to be a git repository`


问题
======

部署完Gogs后，在Web页面创建好仓库后，本地向远程推送出现`无法读取远程仓库`的问题，可能原因：`~/.ssh/authorized_keys` 文件中存在重复的 SSH 密钥，所以[公钥使用冲突](https://gogs.io/docs/intro/troubleshooting#%E5%85%AC%E9%92%A5%E4%BD%BF%E7%94%A8%E5%86%B2%E7%AA%81)了

<!-- more -->

解决方案
======
删除`~/.ssh/authorized_keys`文件里除了属于 Gogs 自动添加以外的重复密钥，这样就可以正常了

新的问题
======
但是这样又出现了个新的问题，就是我用`ssh`登不上我的远程服务器了，原来刚刚删除的那个秘钥是`ssh`远程登录密钥，这样可不行的呀

新的方案
======
额外再生成一个新的密钥`id_rsa_gogs`

``` bash
ssh-keygen -t rsa -C '邮箱或者其他标识' -f ~/.ssh/id_rsa_gogs
```

再在本地新建（如果存在就修改）`~/.ssh/config`添加以下内容

``` bash
Host gogs
    HostName example.com # IP地址或者域名
    Port 222 # ssh端口号
    User git # 远程服务器的用户名
    IdentityFile ~/.ssh/id_rsa_gogs # 刚才生成的密钥的路径
    IdentitiesOnly Yes # 只使用这里设置的key
```

然后就可以使用`gogs`这个别名来代替`user@host:222`了

``` bash
# 以前仓库地址为
user@host:222/repositories-path/xxx.git
# 改为现在的地址
gogs:/repositories-path/xxx.git
```

这样就OK了，看看[其他方案](https://discuss.gogs.io/t/how-to-config-ssh-settings/34)


---