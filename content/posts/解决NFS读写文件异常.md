+++
layout = "article"
title = "解决NFS读写文件异常"
copyright = true
comment = true
date = 2020-07-19 22:04:05
tags = ["NFS"]
categories = "NFS"
+++

应用程序在读取 Linux 环境使用NFS挂载的文件时，发现几Kb的文件读取时很正常，但是读取上Mb的文件时特别慢。多方搜索和询问，是因为升级内核后，需要修改同时发起的NFS请求数量即可解决问题

<!-- more -->

原文地址
======

- 阿里云-[如何修改同时发起的NFS请求](https://help.aliyun.com/knowledge_detail/125389.html#task-1130493)

# 如何修改同时发起的NFS请求数量

NFS客户端对于同时发起的NFS请求数量进行了控制，默认编译的内核中此参数值为2，严重影响性能，建议修改为128。本文介绍如何修改同时发起的NFS请求数量。

您可以通过以下两种方法修改同时发起的NFS请求数量。

**说明** 使用方法一修改完成后，需要重启服务器ECS，重启服务器可能影响您的业务使用。如果您不想重启服务器，可以使用方法二修改同时发起的NFS请求数量。

## 方法一

1. 安装NFS客户端，详情请参见[安装NFS客户端](https://help.aliyun.com/document_detail/90529.html#section-kvj-d02-szj)。

2. 执行以下命令，将同时发起的NFS请求数量修改为128。

   ```bash
   echo "options sunrpc tcp_slot_table_entries=128" >> /etc/modprobe.d/sunrpc.conf
   echo "options sunrpc tcp_max_slot_table_entries=128" >>  /etc/modprobe.d/sunrpc.conf
   ```

   **说明** 您只需在首次安装NFS客户端后执行一次此操作（必须通过root用户操作），之后无需重复执行。

3. 重启云服务器ECS。

   ```bash
   reboot
   ```

4. 挂载文件系统，详情请参见[挂载NFS文件系统](https://help.aliyun.com/document_detail/90529.html#section-spc-nlh-cfb)。

5. 执行以下命令查看修改结果。

   如果返回值为128，则说明修改成功。

   ```bash
   cat /proc/sys/sunrpc/tcp_slot_table_entries
   ```

## 方法二

1. 安装NFS客户端，详情请参见[安装NFS客户端](https://help.aliyun.com/document_detail/90529.html#section-kvj-d02-szj)。

2. 执行以下命令，将同时发起的NFS请求数量修改为128。

   ```bash
   echo "options sunrpc tcp_slot_table_entries=128" >> /etc/modprobe.d/sunrpc.conf
   echo "options sunrpc tcp_max_slot_table_entries=128" >>  /etc/modprobe.d/sunrpc.conf
   ```

   **说明** 您只需在首次安装NFS客户端后执行一次此操作（必须通过root用户操作），之后无需重复执行。

3. 挂载文件系统，详情请参见[挂载NFS文件系统](https://help.aliyun.com/document_detail/90529.html#section-spc-nlh-cfb)。

4. 执行以下命令，再次将同时发起的NFS请求数量修改为128。

   ```bash
   sysctl -w sunrpc.tcp_slot_table_entries=128
   ```

5. 卸载文件系统，详情请参见[在Linux系统中卸载文件系统](https://help.aliyun.com/document_detail/91479.html#task-f5r-3kk-2fb)。

6. 重新挂载文件系统，详情请参见[挂载NFS文件系统](https://help.aliyun.com/document_detail/90529.html#section-spc-nlh-cfb)。

7. 执行以下命令查看修改结果。

   如果返回值为128，则说明修改成功。

   ```bash
   cat /proc/sys/sunrpc/tcp_slot_table_entries
   ```

---