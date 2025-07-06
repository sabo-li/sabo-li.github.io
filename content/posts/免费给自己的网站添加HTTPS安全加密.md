+++
layout = "article"
title = "免费给自己的网站添加HTTPS安全加密"
copyright = true
comment = true
date = 2018-10-06 19:56:47
tags = ["配置", "Nginx", "acme.sh", "HTTPS"]
categories = "配置"
+++

参考地址
======

- [使用 acme.sh 给 Nginx 安装 Let’s Encrypt 提供的免费 SSL 证书](https://ruby-china.org/topics/31983)
- [acme.sh 说明](https://github.com/Neilpang/acme.sh/wiki/%E8%AF%B4%E6%98%8E)
- [分享一个 HTTPS A+ 的 nginx 配置](https://www.textarea.com/zhicheng/fenxiang-yige-https-a-di-nginx-peizhi-320/)


HTTPS
=======
超文本传输安全协议（英语：Hypertext Transfer Protocol Secure，缩写：HTTPS，常称为HTTP over TLS，HTTP over SSL或HTTP Secure）是一种透过计算器网上进行安全通信的传输协议。HTTPS经由HTTP进行通信，但利用SSL/TLS来加密数据包。HTTPS开发的主要目的，是提供对网站服务器的身份认证，保护交换数据的隐私与完整性。这个协议由网景公司（Netscape）在1994年首次提出，随后扩展到互联网上。

<!-- more -->

安装 acme.sh
======

``` bash
curl  https://get.acme.sh | sh
# 重新载入
source ~/.bashrc
```

安装过程不会污染已有的系统任何功能和文件, 所有的修改都限制在安装目录中: `~/.acme.sh/`

生成证书
======
`acme.sh`实现了`acme`协议支持的所有验证协议。 一般有两种方式验证：`http`和`dns`验证。我这里使用的是 `http`方式，`http`方式需要在你的网站根目录下放置一个文件，这个目录需要读写权限，来验证你的域名所有权，完成验证。其他方式可以参考[acme.sh 生成证书](https://github.com/Neilpang/acme.sh/wiki/%E8%AF%B4%E6%98%8E#2-%E7%94%9F%E6%88%90%E8%AF%81%E4%B9%A6)。

``` bash
acme.sh --issue -d mydomain.com -w /home/user/www/mydomain.com/
```

copy / 安装证书
======
注意，默认生成的证书都放在安装目录下：`~/.acme.sh/`，请不要直接使用此目录下的文件，例如： 不要直接让 `nginx`/`apache`的配置文件使用这下面的文件. 这里面的文件都是内部使用，而且目录结构可能会变化。

正确的使用方法是使用`--installcert`命令，并指定目标位置，然后证书文件会被copy到相应的位置。

``` bash
# key-file 服务器端的
acme.sh --installcert -d mydomain.com \
        --key-file /home/user/.nginx/ssl/mydomain.com.key \
        --fullchain-file /home/user/.nginx/ssl/fullchain.cer \
        --reloadcmd "sudo service nginx force-reload"
```

这里用的是`service nginx force-reload`，不是`service nginx reload`，据测试，`reload`并不会重新加载证书，所以用的`force-reload`

`--installcert`命令可以携带很多参数，来指定目标文件。并且可以指定`reloadcmd`，当证书更新以后，`reloadcmd`会被自动调用，让服务器生效，详细参数请参考: https://github.com/Neilpang/acme.sh#3-install-the-issued-cert-to-apachenginx-etc

`Nginx`的配置`ssl_certificate`使用`/home/user/.nginx/ssl/fullchain.cer`，而非 `/home/user/.nginx/ssl/mydomain.com.cer`，否则[SSL Labs](https://www.ssllabs.com/ssltest/)的测试会报`Chain issues Incomplete`错误

修改 visudo
======

修改一下`sudoer`文件，让`sudo service nginx force-reload`不需要输入密码

``` bash
sudo visudo
```

文件内添加以下内容，`user`是`acme.sh`安装所用的账号
``` bash
user ALL=(ALL) NOPASSWD: /usr/sbin/service nginx force-reload
```

nano编辑器的简单使用
------

- 移动光标
用`Ctrl+b`移动到上一字符，`Ctrl+f`移动到下一字符
用`Ctrl+p`移动到上一行，`Ctrl+n`移动到下一行
用`Ctrl+y`移动到上一页，`Ctrl+v`移动到下一页

- 保存
使用`Ctrl+o`来保存所做的修改，回车即可

- 退出
按`Ctrl+x`

- 其他
其中`^`表示`Ctrl`键，`M`表示`Alt`键

使用其他编辑器
------
如果觉得nano不好用，可以设置使用其他编辑器，输入以下后，按照提示选择即可

```bash
sudo update-alternatives --config editor
```

生成 dhparam.pem 文件
======

```bash
openssl dhparam -out /home/user/.nginx/ssl/dhparam.pem 2048
```

修改 Nginx 配置
======

``` nginx
server {
    listen 80;
    listen 443 ssl;
    server_name mydomain.com;

    # 证书文件
    ssl_certificate /home/user/.nginx/ssl/fullchain.cer;
    # 证书私钥
    ssl_certificate_key /home/user/.nginx/ssl/mydomain.com.key;
    # 为DHE密码指定具有DH参数的文件
    ssl_dhparam /home/user/.nginx/ssl/dhparam.pem;

    # 开启缓存，有利于减少SSL握手开销
    ssl_session_cache shared:SSL:10m;
    # SSL会话过期时间，有利于减少服务器开销
    ssl_session_timeout 10m;
    # 指定可用的SSL协议
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    # 屏蔽不安全的加密方式
    ssl_ciphers "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA";
    # 指定在使用SSLv3和TLS协议时，服务器密码应优先于客户端密码
    ssl_prefer_server_ciphers on;
    # 开启HSTS，强制全站加密，如果你的网站要引用不加密的资源，或者考虑将来取消加密，就不要开这个
    add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";

    # ... 其他配置
}
```

配置好后，执行
``` bash
# 测试配置是否有问题
sudo service nginx configtest
# 重启nginx服务
sudo service nginx restart
```

测试SSL服务
======
按照以上步骤完整配好后，应该是 A+
测试地址：https://www.ssllabs.com/ssltest/

后续维护
======

目前由于`acme`协议和`letsencrypt CA`都在频繁的更新, 因此`acme.sh`也经常更新以保持同步.

``` bash
acme.sh --upgrade
# 开启自动更新
acme.sh --upgrade --auto-upgrade
# 关闭自动更新
acme.sh --upgrade --auto-upgrade 0
```

目前证书在 60 天以后会自动更新, 需要定期重新申请，这部分`acme.sh`已经帮你做了，在安装的时候往 `crontab`增加了一行每天执行的命令，执行`crontab -l`，会看到以下信息

``` bash
49 0 * * * "/home/user/.acme.sh"/acme.sh --cron --home "/home/user/.acme.sh" > /dev/null
```

你可以尝试执行一下，看看是否正确运行
``` bash
"/home/user/.acme.sh"/acme.sh --cron --home "/home/user/.acme.sh"
```

最后走一下`acme.sh --cron`的流程看看能否正确执行
``` bash
acme.sh --cron -f
```

---