+++
layout = "article"
title = "使用acme.sh的DNS API配置生成通配域名证书"
copyright = true
comment = true
date = 2020-07-12 00:34:46
tags = ["配置", "Nginx", "acme.sh", "DNS", "HTTPS"]
categories = "配置"
+++

参考地址
======

- [acme.sh DNS API 说明](https://github.com/acmesh-official/acme.sh/wiki/dnsapi)


## DNS API 配置

我用的使用[阿里云](https://www.aliyun.com/minisite/goods?userCode=cma2zz5m)域名服务，其他可以查看[使用说明](https://github.com/acmesh-official/acme.sh/wiki/dnsapi)

首先，需要登录到Aliyun帐户以[获取API密钥](https://ak-console.aliyun.com/#/accesskey)。

<!-- more -->

然后将以下配置写入到`~/.bashrc`文件中，然后执行`source ~/.bashrc`

``` bash
export Ali_Key="获取到的阿里云DNS API Key"
export Ali_Secret="获取到的阿里云DNS API Secret"
```

## 安装 acme.sh

已经安装好的请跳过

``` bash
curl https://get.acme.sh | sh
```

## 执行颁发证书命令

``` bash
acme.sh --issue --force -d example.com -d *.example.com --dns dns_ali
```

## 将证书安装到指定位置

``` bash
acme.sh --installcert -d example.com --key-file example.com.key的路径 --fullchain-file fullchain.cer的路径 --reloadcmd "systemctl force-reload nginx"
```

## Nginx 配置

然后参考[修改-Nginx-配置](/2018/10/06/%E5%85%8D%E8%B4%B9%E7%BB%99%E8%87%AA%E5%B7%B1%E7%9A%84%E7%BD%91%E7%AB%99%E6%B7%BB%E5%8A%A0HTTPS%E5%AE%89%E5%85%A8%E5%8A%A0%E5%AF%86/#%E4%BF%AE%E6%94%B9-Nginx-%E9%85%8D%E7%BD%AE)

现在想要获得 A+ 评级，需要设置 nginx 中的`ssl_protocols`只提供 TLSv1.2 或者更高的协议，禁用不安全或不在受支持的协议，我将原先的`ssl_protocols`更改为：

``` nginx
ssl_protocols TLSv1.2 TLSv1.3;
```

[HTTPS评级 https://myssl.com/](https://myssl.com/)

---