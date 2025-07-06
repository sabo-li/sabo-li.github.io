+++
layout = "article"
title = "Rails动作缓存"
copyright = true
comment = true
date = 2018-09-24 23:57:48
tags = ["Ruby", "Rails"]
categories = "Rails"
+++

动作缓存
======

有前置过滤器的动作不能使用页面缓存，例如需要验证身份的页面。此时，应该使用动作缓存。动作缓存的工作原理与页面缓存类似，不过入站请求会经过 Rails 栈处理，以便运行前置过滤器，然后再伺服缓存。这样，可以做身份验证和其他限制，同时还能从缓存的副本中伺服结果。



> 动作缓存已从Rails 4中删除


动作缓存[actionpack-action_caching的地址](https://github.com/rails/actionpack-action_caching)

<!-- more -->

安装
======

在Rails项目中的`Gemfile`文件中添加

``` ruby
gem 'actionpack-action_caching'
```

然后执行`bundle install`命令安装

使用
=======

详细介绍查看动作缓存[actionpack-action_caching](https://github.com/rails/actionpack-action_caching)

``` ruby
class ListsController < ApplicationController
  before_action :authenticate, except: :public

  caches_page   :public
  caches_action :index, :show
end
```

``` ruby
class ListsController < ApplicationController
  before_action :authenticate, except: :public

  # simple fragment cache
  caches_action :current

  # expire cache after an hour
  caches_action :archived, expires_in: 1.hour

  # cache unless it's a JSON request
  caches_action :index, unless: -> { request.format.json? }

  # custom cache path
  caches_action :show, cache_path: { project: 1 }

  # custom cache path with a proc
  caches_action :history, cache_path: -> { request.domain }

  # custom cache path with a symbol
  caches_action :feed, cache_path: :user_cache_path

  protected
    def user_cache_path
      if params[:user_id]
        user_list_url(params[:user_id], params[:id])
      else
        list_url(params[:id])
      end
    end
end
```

---