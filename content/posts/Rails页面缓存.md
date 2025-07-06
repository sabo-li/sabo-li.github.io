+++
layout = "article"
title = "Rails页面缓存"
copyright = true
comment = true
date = 2018-09-23 23:26:03
tags = ["Ruby", "Rails"]
categories = "Rails"
+++

页面缓存
======
页面缓存是 Rails 提供的一种缓存机制，让 Web 服务器（如 Apache 和 NGINX）直接访问静态页面，而不经由 Rails 动态生成。虽然这种缓存的速度超快，但是不适用于所有情况（例如需要验证身份的页面）。此外，因为 Web 服务器直接从文件系统中访问文件，所以要自行实现缓存失效机制


> 页面缓存已从Rails 4中删除


页面缓存[actionpack-page_caching的地址](https://github.com/rails/actionpack-page_caching)

<!-- more -->

安装
======

在Rails项目中的`Gemfile`文件中添加

``` ruby
gem 'actionpack-page_caching'
```

然后执行`bundle install`命令安装

设置
=======

设置缓存文件存放位置`page_cache_directory`

``` ruby
config.action_controller.page_cache_directory = "#{Rails.root}/public/cached_pa​​ges"
```

也可以给`Controller`单独设置，可以使用以下三种方式

指向一个`lambda`表达式，运行时会自动调用`lambda`的`call`方法

``` ruby
class WeblogController < ApplicationController
  self.page_cache_directory = -> { Rails.root.join("public", request.domain) }
end
```

也可指向一个方法的`symbol`名

``` ruby
class WeblogController < ApplicationController
  self.page_cache_directory = :domain_cache_directory

  private
    def domain_cache_directory
      Rails.root.join("public", request.domain)
    end
end
```

也可以指向实现`call`类方法的对象

``` ruby
class DomainCacheDirectory
  def self.call(request)
    Rails.root.join("public", request.domain)
  end
end

class WeblogController < ApplicationController
  self.page_cache_directory = DomainCacheDirectory
end
```

使用
======

设置
------

``` ruby
class WeblogController < ActionController::Base
  caches_page :show, :new # 设置new和show页面缓存

  # 生成public/cached_pa​​ges/weblog/new.html
  def new
    @list = List.new
  end

  # 生成public/cached_pa​​ges/weblog/:id.html
  def show
    @list = List.find(params[:id])
  end
end
```

更新页面缓存
------
数据更新后，将已生成的页面缓存过期

``` ruby
class WeblogController < ActionController::Base
  def update
    List.update(params[:list][:id], params[:list])
    # 设置public/cached_pa​​ges/weblog/:id.html已过期
    expire_page action: 'show', id: params[:list][:id]
    # 跳转到show，生成新的public/cached_pa​​ges/weblog/:id.html
    redirect_to action: 'show', id: params[:list][:id]
  end
end
```

Nginx配置
------

如果页面缓存文件存在，将页面缓存作为响应内容返回

``` nginx
# Index HTML Files
if (-f $document_root/cached_pa​​ges/$uri/index.html) {
  rewrite (.*) /cached_pa​​ges/$1/index.html break;
}

# Other HTML Files
if (-f $document_root/cached_pa​​ges/$uri.html) {
  rewrite (.*) /cached_pa​​ges/$1.html break;
}

# All
if (-f $document_root/cached_pa​​ges/$uri) {
  rewrite (.*) /cached_pa​​ges/$1 break;
}
```

---