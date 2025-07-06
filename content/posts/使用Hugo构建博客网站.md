---
title: "使用Hugo构建博客网站"
date: 2025-07-05T21:56:09+08:00
# draft: true
description: ""
tags: ["HUGO", "博客"]
---

快速入门
===

Hugo 是一个用 Go 编写的静态站点生成器，针对速度进行了优化，并为灵活性而设计。 凭借其先进的模板系统和快速的资源管道，Hugo 可以在几秒钟内（通常更短）渲染完成一个完整的站点。

## 安装Hugo

### 从源代码构建安装扩展/部署版

前置依赖：

- [Git](https://git-scm.cn/book/en/v2/Getting-Started-Installing-Git)
- [Dart Sass](https://sass-lang.com/install/)
- [Golang](https://go.dev/doc/install)


```bash
CGO_ENABLED=1 go install -tags extended,withdeploy github.com/gohugoio/hugo@latest
```

安装成功后执行`hugo version`有版本输出就是安装成功了，成功示例

```bash
$ hugo version
hugo v0.147.8 darwin/amd64 BuildDate=unknown
```

> 如果编译成功，但是`hugo`命令找不到，需要将`GOBIN`环境变量添加系统环境变量中

### 安装编译好的二进制版

参考[官方安装教程](https://gohugo.io/installation/)根据自己的系统类型安装二进制版

## 创建一个站点

创建项目。
``` bash
hugo new site mywebsite
```

进入项目目录
```bash
cd mywebsite
```

把当前目录初始化为一个空的 Git 存储库。
```
git init
```

本次选择使用的是 Blowfish 主题，其他主题可以参考对应的文档即可

将 Blowfish 主题克隆到 themes 目录中，并将其作为 Git 子模块添加到项目中。

```bash
git submodule add -b main https://github.com/nunocoracao/blowfish.git themes/blowfish
```

将`.gitignore`复制到项目根目录，本次只是作为参考，后续可按需自行更改。

```bash
cp themes/blowfish/.gitignore .
```

复制 Blowfish 主题的配置文件到项目根目录，其他主题可参考各自的文档操作

```bash
cp -r themes/blowfish/config ./
```


在站点配置文件中追加一行，指示当前主题。

```bash
echo "theme = 'blowfish'" >> hugo.toml
```

启动 Hugo 的开发服务器以查看站点。

```bash
hugo server
```

### 添加一个新页面

 在 `content/posts` 目录中创建 `content/posts/hello-world.md`

```bash
hugo new content content/posts/hello-world.md
```

修改文件内容为

```md
+++
date = '2025-07-06T16:29:39+08:00'
draft = false
title = 'Hello World'
+++

你好，世界！
===
```

访问`http://localhost:1313/posts/`就能看到刚创建的文章列表

Blowfish 折腾了一些自定义配置
===

## 自定义为霞鹜文楷字体

创建`layouts/partials/extend-head.html`文件，并且修改文件内容为

```html
<link rel="stylesheet" href="https://cdn.staticfile.org/lxgw-wenkai-screen-webfont/1.7.0/style.css" media="print" onload="this.media='all'">
```

创建`assets/css/custom.css`文件，并且修改文件内容为

```css
body, code, button {
  font-family: "LXGW WenKai Screen", "Roboto", "PingFang SC", "Microsoft Yahei", sans-serif;
}
```

其他的一些详细配置，可以看[官方文档](https://blowfish.page/zh-cn/docs/)

## 部署到GitHub Pages

GitHub 允许你使用 Actions 在 GitHub Pages 上托管静态网站。如果想要启用此功能，需要你在代码库中启用 Pages 并创建一个新的 Actions 工作流，以此来构建和部署你的网站。

工作流文件需要是 YAML 格式，放置在 GitHub 仓库的 `.github/workflows/` 目录下，并以 `.yml` 后缀命名即可。

```yaml
# .github/workflows/gh-pages.yml

name: GitHub Pages

on:
  push:
    branches:
      - main

jobs:
  build-deploy:
    runs-on: ubuntu-24.04
    concurrency:
      group: ${{ github.workflow }}-${{ github.ref }}
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        with:
          submodules: true
          fetch-depth: 0

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: "latest"

      - name: Build
        run: hugo --minify

      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        if: ${{ github.ref == 'refs/heads/main' }}
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_branch: gh-pages
          publish_dir: ./public
```

将配置文件推动到 Github，Github 会自动运行工作流。你需要访问 Github 代码库的 Settings > Pages 部分，检查 YAML 配置是否正确。它应该被设置为使用 gh-pages 分支。

一旦配置完成后，重新运行 Actions 工作流，网站会正确构建和部署，你就可以查看 Actions 的日志来检查是否部署成功。

