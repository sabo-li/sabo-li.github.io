+++
layout = "article"
title = "Rails对HTTP条件GET请求的支持"
copyright = true
comment = true
date = 2018-09-27 22:26:19
tags = ["Ruby", "Rails"]
categories = "Rails"
+++

[原文地址](https://ruby-china.github.io/rails-guides/caching_with_rails.html#conditional-get-support)

对条件 GET 请求的支持
======
条件 GET 请求是 HTTP 规范的一个特性，以此告诉 Web 浏览器，GET 请求的响应自上次请求之后没有变化，可以放心从浏览器的缓存中读取。


<!-- more -->

为此，要传递`HTTP_IF_NONE_MATCH`和 `HTTP_IF_MODIFIED_SINCE`首部，其值分别为唯一的内容标识符和上一次改动时的时间戳。浏览器发送的请求，如果内容标识符（`etag`）或上一次修改的时间戳与服务器中的版本匹配，那么服务器只需返回一个空响应，把状态设为未修改。

服务器（也就是我们自己）要负责查看最后修改时间戳和`HTTP_IF_NONE_MATCH`首部，判断要不要返回完整的响应。既然 Rails 支持条件 GET 请求，那么这个任务就非常简单：

``` ruby
class ProductsController < ApplicationController

  def show
    @product = Product.find(params[:id])

    # 如果根据指定的时间戳和 etag 值判断请求的内容过期了
    # （即需要重新处理）执行这个块
    if stale?(last_modified: @product.updated_at.utc, etag: @product.cache_key)
      respond_to do |wants|
        # ... 正常处理响应
      end
    end

    # 如果请求的内容还新鲜（即未修改），无需做任何事
    # render 默认使用前面 stale? 中的参数做检查，会自动发送 :not_modified 响应
    # 就这样，工作结束
  end
end
```

除了散列，还可以传入模型。Rails 会使用`updated_at`和 `cache_key`方法设定`last_modified`和`etag`：

``` ruby
class ProductsController < ApplicationController
  def show
    @product = Product.find(params[:id])

    if stale?(@product)
      respond_to do |wants|
        # ... 正常处理响应
      end
    end
  end
end
```

如果无需特殊处理响应，而且使用默认的渲染机制（即不使用`respond_to`，或者不自己调用`render`），可以使用 `fresh_when`简化这个过程：

``` ruby
class ProductsController < ApplicationController

  # 如果请求的内容是新鲜的，自动返回 :not_modified
  # 否则渲染默认的模板（product.*）

  def show
    @product = Product.find(params[:id])
    fresh_when last_modified: @product.published_at.utc, etag: @product
  end
end
```

有时，我们需要缓存响应，例如永不过期的静态页面。为此，可以使用 `http_cache_forever`辅助方法，让浏览器和代理无限期缓存。

默认情况下，缓存的响应是私有的，只在用户的 Web 浏览器中缓存。如果想让代理缓存响应，设定`public: true`，让代理把缓存的响应提供给所有用户。

使用这个辅助方法时，`last_modified`首部的值被设为`Time.new(2011, 1, 1).utc`，`expires`首部的值被设为 100 年。


> 使用这个方法时要小心，因为浏览器和代理不会作废缓存的响应，除非强制清除浏览器缓存。


``` ruby
class HomeController < ApplicationController
  def index
    http_cache_forever(public: true) do
      render
    end
  end
end
```

强 Etag 与弱 Etag
-------
Rails 默认生成弱 ETag。这种 Etag 允许语义等效但主体不完全匹配的响应具有相同的 Etag。如果响应主体有微小改动，而不想重新渲染页面，可以使用这种 Etag。

为了与强 Etag 区别，弱 Etag 前面有`W/`。
``` ruby
W/"618bbc92e2d35ea1945008b42799b0e7" # => 弱 ETag
"618bbc92e2d35ea1945008b42799b0e7"   # => 强 ETag
```

与弱 Etag 不同，强 Etag 要求响应完全一样，不能有一个字节的差异。在大型视频或 PDF 文件内部做 Range 查询时用得到。有些 CDN，如 Akamai，只支持强 Etag。如果确实想生成强 Etag，可以这么做：

``` ruby
class ProductsController < ApplicationController
  def show
    @product = Product.find(params[:id])
    fresh_when last_modified: @product.published_at.utc, strong_etag: @product
  end
end
```

也可以直接在响应上设定强 Etag：

``` ruby
response.strong_etag = response.body
# => "618bbc92e2d35ea1945008b42799b0e7"
```
---