---
layout: article
title: GitLab+Jenkins+K8S(生产环境可CI/CD模拟)
copyright: true
comment: true
date: 2020-07-11 18:43:31
tags: [GitLab, Jenkins, K8S]
categories: 部署
key: k-f36497f0661b974ee0dd69de4a213230
---

该文档复制自[Docker+k8s+GitLab+Jenkins(生产环境可CI/CD模拟)](https://www.feiyiblog.com/2020/05/11/Docker-k8s-GitLab-Jenkins-%E7%94%9F%E6%88%90%E7%8E%AF%E5%A2%83%E5%8F%AFCI-CD%E6%A8%A1%E6%8B%9F/)

这个环境仅做参考


> 通过Docker+k8s来部署web集群，GitLab+Jenkins实现代码自动化部署，在Jenkins中通过构建脚本，实现k8s对容器web集群代码自动更新

<!-- more -->

# 运行环境

| ip           | 服务              | 备注                         |
| :----------- | :---------------- | :--------------------------- |
| 192.168.1.1  | GitLab            | 内存4G，双核CPU（CentOS7.8） |
| 192.168.1.4  | Jenkins           | 内核2G，双核CPU（CentOS7.8） |
| 192.168.1.11 | Docker+k8s-master | 内核2G，双核CPU（CentOS7.8） |
| 192.168.1.12 | Docker+k8s-node1  | 内核2G，双核CPU（CentOS7.8） |
| 192.168.1.13 | Docker+k8s-node2  | 内核2G，双核CPU（CentOS7.8） |


# 部署目的

在开发进行代码的更新后，上传到GitLab，Jenkins根据webhook发现代码的更新后，进行代码构建和k8s中的自动部署，展现到web界面中

# 搭建GitLab

参考文档[Git搭建](https://www.feiyiblog.com/2020/03/06/Git版本控制/)和[GitLab搭建](https://www.feiyiblog.com/2020/03/07/GitLab在线代码仓库托管/)

除了程序是通过yum安装的没有什么不同

## 192.168.1.1

```bash
[root@localhost ~]# hostnamectl set-hostname gitlab
[root@localhost ~]# bash
[root@gitlab ~]# vim /etc/hosts
192.168.1.1 gitlab
192.168.1.4 jenkins
```

开启路由转发

```bash
[root@gitlab ~]# echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
[root@gitlab ~]# sysctl -p
net.ipv4.ip_forward = 1
```

安装Git

```bash
[root@gitlab ~]# yum -y install git
```

配置GitLab的repo源

使用清华大学的repo源

```bash
[root@gitlab ~]# cat <<EOF> /etc/yum.repos.d/gitlab-ce.repo
[gitlab-ce]
name=Gitlab CE Repository
baseurl=https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/yum/el7/
gpgcheck=0
enabled=1
EOF
```

安装GitLab

使用yum安装的最新版本发现对密钥问题还有点不稳定

```bash
[root@gitlab ~]# yum -y install gitlab-ce
```

将 SELinux 设置为禁用，可解决设置gitlab公钥后不生效，而且还需要输入账号密码（这个问题我找了十多个小时😓）

```bash
[root@gitlab ~]# setenforce 0
[root@gitlab ~]# sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
```

生产环境中需要修改访问GitLab的域名或者ip

```bash
[root@localhost ~]# vim /etc/gitlab/gitlab.rb
# 将external_url 'http://gitlab.example.com'
# 修改为external_url 'http://192.168.1.1'，本机域名或者ip
```

初始化GitLab

```bash
[root@gitlab ~]# gitlab-ctl reconfigure   # 第一次需要很长时间
```

启动GitLab

```bash
[root@gitlab ~]# gitlab-ctl start
```

放行端口

```bash
[root@gitlab ~]# firewall-cmd --permanent --add-service=http
success
[root@gitlab ~]# firewall-cmd --reload
success
```

登陆到Web管理界面设置的登录密码

```bash
http://192.168.1.1
```

![GitLab](/assets/images/2020-07-11/set_password.png)

默认用户为root

![GitLab](/assets/images/2020-07-11/first_login.png)

登录成功

![img](/assets/images/2020-07-11/gitlab_login.png)

# 搭建Jenkins

参考文档[Jenkins搭建](https://www.feiyiblog.com/2020/03/10/Jenkins代码自动化/)

除了程序是通过yum安装的没有什么不同

## 192.168.1.4

```bash
[root@localhost ~]# hostnamectl set-hostname jenkins
[root@localhost ~]# bash
[root@jenkins ~]# vim /etc/hosts
192.168.1.1 gitlab
192.168.1.4 jenkins
192.168.1.11 k8s-master
192.168.1.12 k8s-node1
192.168.1.13 k8s-node2
```

准备Java环境

使用1.8的Java环境

```bash
[root@jenkins ~]# yum -y install java-1.8.0-openjdk*
```

编写Jenkins的repo源

```bash
[root@jenkins ~]# cat <<EOF> /etc/yum.repos.d/jenkins.repo
[jenkins]
name=Jenkins-stable
baseurl=https://mirrors.tuna.tsinghua.edu.cn/jenkins/redhat-stable/
gpgcheck=1
EOF
# 导入rpm密钥
[root@jenkins ~]# rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
```

安装Jenkins

```bash
[root@jenkins ~]# yum -y install https://mirrors.tuna.tsinghua.edu.cn/jenkins/redhat-stable/jenkins-2.235.1-1.1.noarch.rpm
[root@jenkins ~]# yum -y install git
```

安装加速神奇，Jenkins默认使用google来搜索插件的下载，而且插件也在国外网站，这里将updates目录中的`default.json`内的url换为百度（搜索引擎）和清华（下载插件地址），**前提必须出现过以上界面才会有updates目录**

```bash
[root@jenkins ~]# sed -i 's/http:\/\/www.google.com/https:\/\/www.baidu.com/g' /var/lib/jenkins/updates/default.json
[root@jenkins ~]# sed -i 's/http:\/\/updates.jenkins-ci.org\/download/https:\/\/mirrors.tuna.tsinghua.edu.cn\/jenkins/g' /var/lib/jenkins/updates/default.json
```

启动Jenkins，并放行8080端口

```bash
[root@jenkins ~]# systemctl start jenkins
[root@jenkins ~]# systemctl enable jenkins
[root@jenkins ~]# firewall-cmd --permanent --add-port=8080/tcp
success
[root@jenkins ~]# firewall-cmd --reload
success
```

进入Jenkins的web安装界

访问`http://192.168.1.4:8080`

![Jenkins](/assets/images/2020-07-11/wait_jiemian.png)

在Linux本地查看管理员密码

![Jenkins](/assets/images/2020-07-11/lock_jenkins.png)

输入密码后，如果出现此界面

![Jenkins](/assets/images/2020-07-11/shaowait.png)

如果出现以下

![Jenkins](/assets/images/2020-07-11/lixian.png)

解决方法如下：

```
第一步 打开插件管理的高级设置页面
http://192.168.1.4:8080/pluginManager/advanced

第二步 修改更新站点地址
将https改为http  如果不行 可以用清华的加速站点 如下
https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json
```

安装推荐插件

![Jenkins](/assets/images/2020-07-11/install_chajian.png)

![Jenkins](/assets/images/2020-07-11/wait_install.png)


然后重启服务，并重新访问Jenkins的web界面

```bash
[root@jenkins ~]# systemctl restart jenkins
```

安装完成后，创建管理用户

![Jenkins](/assets/images/2020-07-11/create_jenkins_user.png)

![Jenkins](/assets/images/2020-07-11/shili_config.png)

![Jenkins](/assets/images/2020-07-11/jenkins_install_success.png)

在插件管理中安装三个关于GitLab的插件，用于持续集成

> Gitlab Authentication
>
> Gitlab
>
> Gitlab Hook

选择安装后自动重启Jenkins

# 搭建Kubernetes集群

参考本站文档[Docker安装](https://www.feiyiblog.com/2020/03/23/安装Docker——镜像加速/)和[Kubernetes集群搭建](https://www.feiyiblog.com/2020/04/17/kubernetes安装及集群搭建/)

## 环境准备

按照运行环境中的系统版本和硬件要求

这里使用的现成的Docker环境，没有的可以参考以上链接部署

### 更改主机名

**192.168.1.11**

更改主机名，并设置对其他两台节点的免密登录

```bash
[root@localhost ~]# hostnamectl set-hostname k8s-master
[root@localhost ~]# bash
[root@k8s-master ~]# vim /etc/hosts
192.168.1.11 k8s-master
192.168.1.12 k8s-node1
192.168.1.13 k8s-node2
[root@k8s-master ~]# ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa):
Created directory '/root/.ssh'.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /root/.ssh/id_rsa.
Your public key has been saved in /root/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:y0cMv9gJDShPYbfH/+WUbwtLJivwGTNv4EVT6TpxXHQ root@k8s-master
The key's randomart image is:
+---[RSA 2048]----+
|      o .     o.E|
|     . + o   o ..|
|    . o + o + .  |
|     +   B = +  .|
|      . S * *  .o|
|       o @ * . +.|
|        B &..+. +|
|         * o= o..|
|          o. . . |
+----[SHA256]-----+
[root@k8s-master ~]# ssh-copy-id -i root@k8s-node1
[root@k8s-master ~]# ssh-copy-id -i root@k8s-node2
```

将hosts文件传输到其他两台节点

```bash
[root@k8s-master ~]# scp /etc/hosts root@k8s-node1:/etc
[root@k8s-master ~]# scp /etc/hosts root@k8s-node2:/etc
```

**192.168.1.12**

```bash
[root@localhost ~]# hostnamectl set-hostname k8s-node1
[root@localhost ~]# bash
[root@k8s-node1 ~]#
```

**192.168.1.13**

```bash
[root@localhost ~]# hostnamectl set-hostname k8s-node2
[root@localhost ~]# bash
[root@k8s-node2 ~]#
```

### 关闭沙盒

**k8s-master/node1/node2**

将 SELinux 设置为禁用（也可以设置为 permissive 模式）

```bash
[root@k8s-master ~]# setenforce 0
[root@k8s-master ~]# sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
```

### 开放所需端口

防火墙放行端口，因为比较多，省事可以直接`systemctl stop firewalld`

**master节点**

| 协议 | 方向 | 端口范围  | 作用                    | 使用者                       |
| ---- | ---- | --------- | ----------------------- | ---------------------------- |
| TCP  | 入站 | 6443*     | Kubernetes API 服务器   | 所有组件                     |
| TCP  | 入站 | 2379-2380 | etcd server client API  | kube-apiserver, etcd         |
| TCP  | 入站 | 10250     | Kubelet API             | kubelet 自身、控制平面组件   |
| TCP  | 入站 | 10251     | kube-scheduler          | kube-scheduler 自身          |
| TCP  | 入站 | 10252     | kube-controller-manager | kube-controller-manager 自身 |

```bash
[root@k8s-master ~]# firewall-cmd --permanent --add-port=6443/tcp
[root@k8s-master ~]# firewall-cmd --permanent --add-port=64430-64439/tcp
[root@k8s-master ~]# firewall-cmd --permanent --add-port=2379-2380/tcp
[root@k8s-master ~]# firewall-cmd --permanent --add-port=10250-10252/tcp
[root@k8s-master ~]# firewall-cmd --reload
```

**所有node工作节点**

| 协议 | 方向 | 端口范围    | 作用            | 使用者                     |
| ---- | ---- | ----------- | --------------- | -------------------------- |
| TCP  | 入站 | 10250       | Kubelet API     | kubelet 自身、控制平面组件 |
| TCP  | 入站 | 30000-32767 | NodePort 服务** | 所有组件                   |

```bash
[root@k8s-node1 ~]# firewall-cmd --permanent --add-port=10250/tcp
[root@k8s-node1 ~]# firewall-cmd --permanent --add-port=30000-32767/tcp
[root@k8s-node1 ~]# firewall-cmd --reload
```



### 验证节点UUID

查看每个服务器的uuid，必须不能重复

**k8s-master**

```bash
[root@k8s-master ~]# cat /sys/class/dmi/id/product_uuid
E2B74D56-23A9-4E8B-620C-555387355616
```


### 关闭swap分区

三台节点同样的操作

```bash
[root@k8s-master ~]# swapoff -a
[root@k8s-master ~]# vim /etc/fstab
# 将分区类型为swap的一行注释掉
/dev/mapper/centos-swap swap
# 还是需要调整内核参数
[root@k8s-master ~]# vim /etc/sysctl.conf
# 末尾添加
vm.swappiness = 0
[root@k8s-master ~]# sysctl -p
```

### 设置内核参数

调整iptables桥接流量，依赖于docker的启动，所以需要确保docker已经启动

**k8s-master**

```bash
[root@k8s-master ~]# vim /etc/sysctl.conf
# 末尾添加
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
[root@k8s-master ~]# sysctl -p
# 为确保桥接流量不报错，执行以下命令
[root@k8s-master ~]# modprobe ip_vs_rr
[root@k8s-master ~]# modprobe br_netfilter
# 将修改好的文件传输到node1和node2
[root@k8s-master ~]# scp /etc/sysctl.conf root@k8s-node1:/etc
[root@k8s-master ~]# scp /etc/sysctl.conf root@k8s-node2:/etc
```

**k8s-node1**

```bash
[root@k8s-node1 ~]# sysctl -p
[root@k8s-node1 ~]# modprobe ip_vs_rr
[root@k8s-node1 ~]# modprobe br_netfilter
```

**k8s-node2**

```bash
[root@k8s-node2 ~]# sysctl -p
[root@k8s-node2 ~]# modprobe ip_vs_rr
[root@k8s-node2 ~]# modprobe br_netfilter
```

## 安装Kubernetes

### 编写yum源

**k8s-master**

```bash
[root@k8s-master ~]# vim /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
```

将yum源传给每台节点

```bash
[root@k8s-master ~]# scp /etc/yum.repos.d/kubernetes.repo root@k8s-node1:/etc/yum.repos.d/
[root@k8s-master ~]# scp /etc/yum.repos.d/kubernetes.repo root@k8s-node2:/etc/yum.repos.d/
```

### 安装k8s

**k8s-master/node1/node2**

```bash
[root@k8s-master ~]# yum -y install kubelet kubeadm kubectl
```

如果有的节点在yum安装时，报错404，尝试执行`rm -rf /var/cache/yum/*`后，重新安装

查看k8s版本

```bash
[root@k8s-master ~]# kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.2",
GitCommit:"52c56ce7a8272c798dbc29846288d7cd9fbae032", GitTreeState:"clean",
BuildDate:"2020-04-16T11:54:15Z", GoVersion:"go1.13.9", Compiler:"gc",
Platform:"linux/amd64"}
```

**k8s-master**

安装kubernetes的tab快捷键，只需要在master安装即可

```bash
[root@k8s-master ~]# yum -y install bash-completion
[root@k8s-master ~]# echo "source <(kubectl completion bash)" >> ~/.bashrc && bash
```

### 启动k8s

**k8s-master/node1/node2**

``` bash
[root@k8s-master ~]# systemctl enable --now kubelet
```

## Kubernetes集群搭建

**k8s-master**

初始化集群，完成后获取token值

```bash
[root@k8s-master ~]# kubeadm init --apiserver-advertise-address 192.168.1.11 \
--image-repository registry.aliyuncs.com/google_containers \
--kubernetes-version v1.18.2 --pod-network-cidr=10.244.0.0/16
```

使用管理用户（非root）执行以下操作

```bash
[root@k8s-master ~]# mkdir -p $HOME/.kube
[admin@k8s-master ~]$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
[admin@k8s-master ~]$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

使用root用户执行以下操作

```bash
[root@k8s-master ~]# echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bashrc && source ~/.bashrc
```

### 部署集群网络

下载flannel网络配置文件，有时候会下载失败，前往[coreos/flannel 项目](https://github.com/coreos/flannel/blob/master/Documentation/kube-flannel.yml)手动将内容复制到`kube-flannel.yml`文件中

```bash
[root@k8s-master ~]# curl -LO https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
# 将quay.io改为国内quay-mirror.qiniu.com
[root@k8s-master ~]# sed -i s/quay.io/quay-mirror.qiniu.com/g kube-flannel.yml
```

然后执行以下操作

```bash
[root@k8s-master ~]# kubectl apply -f kube-flannel.yml
```

### 节点加入集群

如果之前生成的token值忘了，查看`kubeadm token list`，还能往上翻看到token值就跳过这步

**k8s-master**

```bash
[root@k8s-master ~]# kubeadm token list
TOKEN                     TTL         EXPIRES                     USAGES
jppmrh.1hovp0cyt4xu2w1l   23h         2020-05-11T02:05:53+08:00   authentication,signing
# 将它删除重新生成
[root@k8s-master ~]# kubeadm token delete jppmrh.1hovp0cyt4xu2w1l
```

如果找不到了，重新生成

```bash
[root@k8s-master ~]# kubeadm token create --print-join-command
```

**k8s-node1/node2**

```bash
[root@k8s-node1 ~]# kubeadm join 192.168.1.11:6443 --token bdsiop.8ptt7ky6t088xyl8 \
    --discovery-token-ca-cert-hash sha256:1b61fd611bd12f46c7c065995f304ad232f2a598cb99127ccc547612ea57eac0
```

输出信息为以下则成功

```
Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
```

### 验证集群节点

**k8s-master**

等待一段时间，直至状态全部为Ready

```bash
[root@k8s-master ~]# kubectl get nodes
NAME         STATUS   ROLES    AGE     VERSION
k8s-master   Ready    master   10m     v1.18.2
k8s-node1    Ready    <none>   3m56s   v1.18.2
k8s-node2    Ready    <none>   3m56s   v1.18.2
```

集群搭建成功

# 运行Docker私库—Registry

为了在环境中更好的管理Docker镜像，决定使用Registry来运行一个容器，用来存放docker镜像，也减少了镜像存储在国外源或者国内源的传输效率，当然也能使用harbor私库代替Registry

**k8s-master**

创建镜像存放目录

```bash
[root@k8s-master ~]# mkdir -p /data/docker/registry
```

下载镜像

```bash
[root@k8s-master ~]# docker pull registry:2
```

运行私库容器

```bash
[root@k8s-master ~]# docker run -itd -p 5000:5000 --restart always \
--volume /data/docker/registry/:/var/lib/registry registry:2
```

查看端口是否映射成功

```bash
[root@k8s-master ~]# netstat -anput | grep 5000
```

检查能否访问到私库

```bash
[root@k8s-master ~]# firewall-cmd --permanent --add-port=5000/tcp
[root@k8s-master ~]# firewall-cmd --reload
[root@k8s-master ~]# curl 192.168.1.11:5000/v2/_catalog
{"repositories":[]}
```

设置三台docker都能识别私库地址

```bash
[root@k8s-master ~]# vim /usr/lib/systemd/system/docker.service
# 以ExecStart开头的一行的末尾添加--insecure-registry 192.168.1.11:5000
[root@k8s-master ~]# scp /usr/lib/systemd/system/docker.service root@k8s-node1:/usr/lib/systemd/system/
[root@k8s-master ~]# scp /usr/lib/systemd/system/docker.service root@k8s-node2:/usr/lib/systemd/system/
```

全部重启docker

```bash
[root@k8s-master ~]# systemctl daemon-reload && systemctl restart docker
```

制作一个镜像上传到私库测试

```bash
[root@k8s-master ~]# wget http://nginx.org/download/nginx-1.11.1.tar.gz
[root@k8s-master ~]# vim Dockerfile
FROM centos
MAINTAINER FeiYi
RUN yum -y install net-tools iproute pcre-devel openssl-devel gcc gcc-c++ make zlib-devel elinks
ADD nginx-1.11.1.tar.gz /usr/src
ENV NGINX_DIR /usr/src/nginx-1.11.1
WORKDIR $NGINX_DIR
RUN ./configure --prefix=/usr/local/nginx --user=nginx --group=nginx && make && make install
WORKDIR /
RUN useradd nginx
RUN ln -s /usr/local/nginx/sbin/nginx /usr/sbin/nginx
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

构建镜像

```bash
[root@k8s-master ~]# docker build -t 192.168.1.11:5000/bin-nginx:latest /root
```

上传镜像

```bash
[root@k8s-master ~]# docker push 192.168.1.11:5000/bin-nginx
[root@k8s-master ~]# curl 192.168.1.11:5000/v2/_catalog
{"repositories":["bin-nginx"]}
```

私库成功

# 使用k8s启动nginx容器

**k8s-master**

## 编写Deployment的模板文件

```bash
[root@node1 ~]# vim nginx-deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: 192.168.1.11:5000/bin-nginx
        ports:
        - containerPort: 80
```

运行模板文件

```bash
[root@node1 ~]# kubectl apply -f nginx-deployment.yml
deployment.apps/nginx created
```

查看是否运行成功

```bash
[root@node1 ~]# kubectl get pod -o wide
NAME                     READY   STATUS    RESTARTS   AGE    IP           NODE
nginx-66fb94d868-h2fkk   1/1     Running   0          2m5s   10.244.2.2   node2
nginx-66fb94d868-zhkf8   1/1     Running   0          2m5s   10.244.1.2   node3
```

可以看到容器的ip，现在只能在运行容器的节点才能够访问到页面内容，如果想让外部主机访问到，需要做一个service模板，用来映射端口

## 编写Service模板

将集群中标签为app: nginx的容器的80端口映射为服务器的30001

```bash
[root@node1 ~]# vim nginx-service.yml
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30001
  selector:
    app: nginx
```

运行Service模板

```bash
[root@node1 ~]# kubectl apply -f nginx-service.yml
service/nginx created
```

访问宿主机的30001端口

```
http://192.168.1.12:30001`和`http://192.168.1.13:30001
```

![k8s_nginx](/assets/images/2020-07-11/k8s_nginx.png)

容器部署成功

# 整合GitLab和Jenkins

**Jenkins**

在Jenkins生成密钥对

```bash
[root@jenkins ~]# ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa):
Created directory '/root/.ssh'.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /root/.ssh/id_rsa.
Your public key has been saved in /root/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:IITvkptc3nJrgxCxA0R0+ExWm5y/PfSIdKaQpD0NhUc root@jenkins
The key's randomart image is:
+---[RSA 2048]----+
|++.oo.oE         |
|..++..=.         |
| .=+.Bo          |
|  +o=.=.         |
|   * = +S+       |
|  + o + O o      |
| . B o + + .     |
|  + + =   .      |
|     +.o         |
+----[SHA256]-----+
```

**GitLab**

登录GitLab

```
http://192.168.1.1
```

创建项目仓库

![gitlab](/assets/images/2020-07-11/admin_create_project.png)

![k8s_gitlab](/assets/images/2020-07-11/k8s_gitlab.png)

在GitLab中添加Jenkins的公钥值

![gitlab](/assets/images/2020-07-11/add_id_rsa_pub.png)

复制Jenkins服务器的公钥到下图位置，查看公钥`cat .ssh/id_rsa.pub`

![k8s_gitlab1](/assets/images/2020-07-11/k8s_gitlab1.png)

在GitLab的项目仓库，创建一个测试代码文件

![k8s_gitlab2](/assets/images/2020-07-11/k8s_gitlab2.png)

![k8s_gitlab3](/assets/images/2020-07-11/k8s_gitlab3.png)

因为密钥上传的是Jenkins的，所以在Jenkins上下载查看

```bash
[root@jenkins ~]# git clone http://192.168.1.1/root/nginx-test.git
[root@jenkins ~]# cd nginx-test/
[root@jenkins nginx-test]# cat index.html
ChaiYanjiang
```

成功

**Jenkins**

```
http://192.168.1.4:8080/
```

创建任务nginx-test

![k8s_jenkins](/assets/images/2020-07-11/k8s_jenkins.png)

设置源码管理时在Gitlab的地址，出现红色说明连接不到，因为GitLab已经有了Jenkins的公钥，这里只需要填写Jenkins的私钥即可

![k8s_jenkins2](/assets/images/2020-07-11/k8s_jenkins2.png)

![Jenkins](/assets/images/2020-07-11/create_con_gitlab.png)

红色报错消失了

![Jenkins](/assets/images/2020-07-11/choose_pingzheng_gitlab.png)

设置构建触发器

当gitlab发生代码变化时，开始进行构建任务

![k8s_jenkins3](/assets/images/2020-07-11/k8s_jenkins3.png)

生成一串token值，用来对GitLab中的项目代码进行操作，所以这个值要放到GitLab中，用于验证允许Jenkins来拿取代码，稍后会将

![k8s_build](/assets/images/2020-07-11/sheng_token.png)

设置构建的命令（CI/CD）

![k8s_build](/assets/images/2020-07-11/k8s_build.png)

```bash
#!/bin/bash
backupcode=/data/backupcode/$JOB_NAME/
mkdir -p $backupcode
chmod 644 $JENKINS_HOME/workspace/$JOB_NAME/*
rsync -acP $JENKINS_HOME/workspace/$JOB_NAME/* $backupcode
echo From 192.168.1.11:5000/bin-nginx > $JENKINS_HOME/workspace/Dockerfile
echo COPY ./nginx-test/* /usr/local/nginx/html/ >> $JENKINS_HOME/workspace/Dockerfile
docker rmi 192.168.1.11:5000/bin-nginx:latest
docker build -t 192.168.1.11:5000/bin-nginx:latest $JENKINS_HOME/workspace/
docker push 192.168.1.11:5000/bin-nginx:latest
ssh root@k8s-master kubectl delete deployment nginx
ssh root@k8s-master kubectl apply -f nginx-deployment.yml
```

保存即可

**GitLab**

192.168.1.1中设置Jenkins中的token值，用来触发Jenkins构建

GitLab默认情况下不允许通过本地网络触发构建，以下这步是为了设置允许本地网络构建，如果不设置允许会在添加token时报错

![GitLab](/assets/images/2020-07-11/admin_settings_integrations.png)

![GitLab](/assets/images/2020-07-11/outbound_requests.png)

![GitLab](/assets/images/2020-07-11/allow_webhooks.png)

保存

设置允许之后，就可以设置GitLab项目与Jenkins的构建触发器连接了

**进入项目**中选择设置

![gitlab](/assets/images/2020-07-11/cd_reops_settings.png)

图中的URL是在Jenkins中的项目路径，这个路径在构建触发器的那里可以看到，复制即可，token则是刚才在Jenkins的管理界面中生成的token值，也是同样的位置，然后点击下方`add webhook`

![gitlab_token](/assets/images/2020-07-11/gitlab_token.png)

add成功后，往下翻到如图所示位置可以看添加成功的URL，然后进行连接测试，出现200即成功

![gitlab_webhooktest](/assets/images/2020-07-11/gitlab_webhooktest.png)

# 整合Jenkins和Docker

**Jenkins**

在Jenkins中做对k8s-master的免密登录，得先修改Jenkins的运行用户，这里我直接用root代替，生产环境请参考这里的[scp报错部分](https://www.feiyiblog.com/2020/03/12/GitLab-Jenkins-Tomcat/)

```bash
[root@jenkins ~]# vim /etc/sysconfig/jenkins
 修改jenkins用户
JENKINS_USER="jenkins"   # 修改为root
```

重启Jenkins并传输密钥

```bash
[root@jenkins ~]# systemctl restart jenkins
[root@jenkins ~]# ssh-copy-id -i root@k8s-master
```

安装Docker，参考文档[Docker安装](https://www.feiyiblog.com/2020/03/23/安装Docker——镜像加速/)，并设置镜像加速，和指定私库地址

# 测试

修改GitLab的测试文件测试Jenkins的自动化部署是否成功

![gitlab_test](/assets/images/2020-07-11/gitlab_test.png)

保存后会开始自动构建部署，访问`192.168.1.13:30001`，如果是以下则成功，如果构建失败，则检查构建脚本，慢慢排错

![k8s_cicd](/assets/images/2020-07-11/k8s_cicd.png)

---