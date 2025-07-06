+++
layout = "article"
title = "基于 Ruby 3.0.0 以上版本 使用 Jekyll 4.2"
date = 2022-04-10 16:52:00
tags = ["Jekyll"]
categories = "Jekyll"
+++


要求
===

运行 Jekyll 需要以下条件

1.需要 Ruby 版本 > 2.5.0

2.RubyGems

3.GCC 和 Make

可以参考 [Jekyll-Installation-Guides](https://jekyllrb.com/docs/installation/#guides) 根据自己环境选择安装

安装
===

1.满足以上[要求](https://jekyllrb.com/docs/installation/)

2.安装 jekyll 和 bundler gems，如果在国内出现网络错误或者下载慢，可以使用 [RubyGems 镜像](https://gems.ruby-china.com/)。

``` bash
gem install jekyll bundler
```

我在MacOS上实际执行时，出现了错误 `fatal error: 'openssl/ssl.h' file not found`

可使用 以下命令解决

``` bash
brew install openssl
brew link --force openssl
gem install eventmachine -- --with-cppflags=-I/usr/local/opt/openssl/include
# 然后再执行
gem install jekyll
```

3.创建一个新的 Jekyll 站点在 `./myblog`

``` bash
jekyll new myblog
```

4.切换到新目录。

``` bash
cd myblog
```

5.构建站点并使其在本地服务器上可用。

``` bash
bundle exec jekyll serve
```

如果用的 Ruby >= 3.0.0，可能会出现错误 `require': cannot load such file -- webrick (LoadError)`，使用以下命令解决

``` bash
bundle add webrick
```

6.在浏览器访问 `http://localhost:4000`


写文章
===

发表一篇新文章，你所需要做的就是在 /_posts 文件夹中创建一个新的文件，文件内容格式查看 `Markdown` [基本撰写和格式语法](https://docs.github.com/cn/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax)。文件名的命名非常重要。Jekyll 要求一篇文章的文件名遵循下面的格式：

> 年-月-日-标题.MARKUP

下面是一些合法的文件名的例子：

> 2011-12-31-new-years-eve-is-awesome.md
>
> 2012-09-12-how-to-write-a-blog.markdown

之前一直想从 Hexo 切换到 Jekyll，但是一看到这个格式就很别扭，每次创建文件都得敲一个日期进去，后来在[Awesome (Gem-Packaged) Jekyll Plugins](https://github.com/planetjekyll/awesome-jekyll-plugins)发现一个很好用的插件[Jekyll::Compose](https://github.com/jekyll/jekyll-compose)，扩展了 `jekyll` 命令，可以非常方便创建新的文件

添加和使用 Jekyll::Compose
---

在 `Gemfile` 中添加：

``` ruby
gem 'jekyll-compose', group: [:jekyll_plugins]
```

然后执行 `bundle`，等待执行成功后就可以使用了

例如创建一个 `_posts` 文件夹中创建一个新的文章，可以使用

``` bash
jekyll post 文章名字
```

其他用法详见 `jekyll help` 或者查看 `Jekyll::Compose` [使用说明](https://github.com/jekyll/jekyll-compose#usage)


使用主题
===

写好文章后如果觉的页面不好看，可以切换到自己喜欢的主题，比如我首次用的就是[TeXt Theme](https://github.com/kitian616/jekyll-TeXt-theme/blob/master/README-zh.md#%E6%96%87%E6%A1%A3)


编译和发布
===

部署到 Github
---

使用的是 Github Pages，新建一个 USERNAME.github.io 源码仓库，GitHub 会自动的编译，几分钟后你就可以通过`https://USERNAME.github.io`访问到你的网站了。


使用静态资源文件
---

使用以下命令编译生成静态文件，编译好的文件位于 `_site` 文件夹

``` bash
JEKYLL_ENV=production bundle exec jekyll build
```