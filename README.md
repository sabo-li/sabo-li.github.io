# 个人技术博客

基于 Hugo 静态站点生成器构建的中文技术博客，使用 Blowfish 主题，专注于 Web 开发、DevOps、Ruby/Rails 等技术领域的知识分享。

## 🚀 技术栈

- **静态站点生成器**: [Hugo](https://gohugo.io/)
- **主题**: [Blowfish](https://blowfish.page/)
- **样式框架**: Tailwind CSS
- **语言**: 中文 (zh-CN)

## 📝 内容领域

本博客主要涵盖以下技术领域：

- **Web 开发**: Hexo、Jekyll、Nginx 部署
- **版本控制**: Git 钩子、Gogs 部署和配置
- **Ruby/Rails**: 缓存机制、元编程、ActiveSupport
- **DevOps**: GitLab CI/CD、Jenkins、Kubernetes
- **系统运维**: NFS 配置、HTTPS 证书、DNS API

## 🛠️ 环境要求

在开始之前，请确保您的系统已安装以下工具：

- [Hugo](https://gohugo.io/installation/) (Extended 版本)
- [Git](https://git-scm.com/)
- [Go](https://golang.org/) (用于 Hugo Modules)

## 🚀 快速开始

### 1. 克隆项目

```bash
git clone <your-repository-url>
cd <project-directory>
```

### 2. 初始化子模块

```bash
git submodule update --init --recursive
```

### 3. 启动开发服务器

```bash
hugo server -D
```

访问 `http://localhost:1313` 查看博客。

## 📁 项目结构

```
.
├── archetypes/          # 内容模板
├── assets/             # 静态资源
│   ├── css/           # 自定义样式
│   ├── favicon/       # 网站图标
│   └── images/        # 图片资源
├── config/            # 配置文件
│   └── _default/      # 默认配置
│       ├── hugo.toml  # 主配置文件
│       ├── params.toml # 主题参数
│       ├── menus.*.toml # 菜单配置
│       └── languages.*.toml # 多语言配置
├── content/           # 内容文件
│   └── posts/         # 博客文章
├── layouts/           # 自定义布局
├── static/            # 静态文件
└── themes/            # 主题文件
    └── blowfish/      # Blowfish 主题
```

## ✍️ 内容管理

### 创建新文章

```bash
hugo new posts/your-post-title.md
```

### 文章 Front Matter 格式

```yaml
+++
title = "文章标题"
date = 2024-01-01T00:00:00+08:00
tags = ["标签1", "标签2"]
categories = ["分类"]
draft = false
+++

文章内容...
```

### 常用 Front Matter 字段

- `title`: 文章标题
- `date`: 发布日期
- `tags`: 标签数组
- `categories`: 分类
- `draft`: 是否为草稿
- `layout`: 布局类型（默认为 "article"）
- `comment`: 是否启用评论
- `copyright`: 是否显示版权信息

## ⚙️ 配置说明

### 主要配置文件

- **`config/_default/hugo.toml`**: Hugo 核心配置
- **`config/_default/params.toml`**: Blowfish 主题参数
- **`config/_default/menus.*.toml`**: 导航菜单配置
- **`config/_default/languages.*.toml`**: 多语言设置

### 主题自定义

主题配置主要在 `config/_default/params.toml` 中：

- `colorScheme`: 颜色方案
- `defaultAppearance`: 默认外观（light/dark）
- `homepage.layout`: 首页布局（profile/page/hero/card）
- `article.*`: 文章页面设置
- `list.*`: 列表页面设置

### 自定义样式

在 `assets/css/custom.css` 中添加自定义 CSS 样式。

## 🚀 构建和部署

### 本地构建

```bash
hugo --minify
```

构建后的文件将生成在 `public/` 目录中。

### 部署选项

#### GitHub Pages

1. 在 GitHub 仓库设置中启用 GitHub Pages
2. 使用 GitHub Actions 自动部署：

```yaml
# .github/workflows/hugo.yml
name: Deploy Hugo site to Pages

on:
  push:
    branches: ["main"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

defaults:
  run:
    shell: bash

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          submodules: recursive
      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: 'latest'
          extended: true
      - name: Build
        run: hugo --minify
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v2
        with:
          path: ./public

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v2
```

#### Netlify

1. 连接 GitHub 仓库到 Netlify
2. 设置构建命令：`hugo --minify`
3. 设置发布目录：`public`

## 🔧 开发指南

### 本地开发流程

1. 创建新分支进行开发
2. 使用 `hugo server -D` 启动开发服务器
3. 编写和预览内容
4. 提交更改并推送到远程仓库

### 主题更新

```bash
git submodule update --remote themes/blowfish
```

### 添加新功能

- 自定义 shortcodes: `layouts/shortcodes/`
- 自定义布局: `layouts/`
- 自定义样式: `assets/css/custom.css`

## 📊 功能特性

- ✅ 响应式设计
- ✅ 深色/浅色模式切换
- ✅ 全文搜索
- ✅ 代码高亮和复制
- ✅ 目录导航
- ✅ 标签和分类系统
- ✅ RSS 订阅
- ✅ SEO 优化
- ✅ 多语言支持
- ✅ 图片优化
- ✅ 数学公式支持 (KaTeX)

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进这个博客项目。

## 📞 联系方式

如有问题或建议，请通过以下方式联系：

- 提交 [Issue](../../issues)
- 发起 [Discussion](../../discussions)

---

⭐ 如果这个项目对您有帮助，请给它一个 Star！
