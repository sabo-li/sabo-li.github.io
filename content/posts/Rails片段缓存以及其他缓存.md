+++
layout = "article"
title = "Rails片段缓存以及其他缓存"
copyright = false
comment = true
date = 2018-09-25 22:14:00
tags = ["Ruby", "Rails"]
categories = "Rails"
+++

更多详细查看[原文地址](https://ruby-china.github.io/rails-guides/caching_with_rails.html#fragment-caching)

片段缓存
======

动态 Web 应用一般使用不同的组件构建页面，不是所有组件都能使用同一种缓存机制。如果页面的不同部分需要使用不同的缓存机制，在不同的条件下失效，可以使用片段缓存（`ActionView::Helpers::CacheHelper#cache`）。片段缓存把视图逻辑的一部分放在 `cache` 块中，下次请求使用缓存存储器中的副本伺服
<!-- more -->

使用
------

如果想缓存页面中的各个商品，可以使用下述代码：
``` erb
<% @products.each do |product| %>
  <% cache product do %>
    <%= render product %>
  <% end %>
<% end %>
```

首次访问这个页面时，Rails 会创建一个具有唯一键的缓存条目。缓存键类似下面这种

``` bash
views/products/1-201505056193031061005000/bea67108094918eeba42cd4a6e786901
```

中间的数字是 `product_id` 加上商品记录的 `updated_at` 属性中存储的时间戳。Rails 使用时间戳确保不伺服过期的数据。如果 `updated_at` 的值变了，Rails 会生成一个新键，然后在那个键上写入一个新缓存，旧键上的旧缓存不再使用。这叫基于键的失效方式

视图片段有变化时（例如视图的 HTML 有变），缓存的片段也失效。缓存键末尾那个字符串是模板树摘要，是基于缓存的视图片段的内容计算的 MD5 哈希值。如果视图片段有变化，MD5 哈希值就变了，因此现有文件失效


> Memcached 等缓存存储器会自动删除旧的缓存文件


特定条件下缓存一个片段，可以使用 `cache_if` 或 `cache_unless`
``` erb
<% cache_if admin?, product do %>
  <%= render product %>
<% end %>
```

`render` 辅助方法还能缓存渲染集合的单个模板。这甚至比使用 `each` 的前述示例更好，因为是一次性读取所有缓存模板的，而不是一次读取一个。若想缓存集合，渲染集合时传入 `cached: true` 选项

``` erb
<%= render partial: 'products/product', collection: @products, cached: true %>
```

上述代码中所有的缓存模板一次性获取，速度更快。此外，尚未缓存的模板也会写入缓存，在下次渲染时获取

俄罗斯套娃缓存
======

有时，可能想把缓存的片段嵌套在其他缓存的片段里。这叫俄罗斯套娃缓存（Russian doll caching）
俄罗斯套娃缓存的优点是，更新单个商品后，重新生成外层片段时，其他内存片段可以复用
前一节说过，如果缓存的文件对应的记录的 `updated_at` 属性值变了，缓存的文件失效。但是，内层嵌套的片段不失效

``` erb
<% cache product do %>
  <%= render product.games %>
<% end %>
```

上面这个会渲染下面这个

``` erb

<% cache game do %>
  <%= render game %>
<% end %>
```

如果游戏的任何一个属性变了，`updated_at` 的值会设为当前时间，因此缓存失效。然而，商品对象的 `updated_at` 属性不变，因此它的缓存不失效，从而导致应用伺服过期的数据。为了解决这个问题，可以使用 `touch` 方法把模型绑在一起

``` ruby
class Product < ApplicationRecord
  has_many :games
end

class Game < ApplicationRecord
  belongs_to :product, touch: true
end
```

管理依赖
======
为了正确地让缓存失效，要正确地定义缓存依赖。Rails 足够智能，能处理常见的情况，无需自己指定。但是有时需要处理自定义的辅助方法（以此为例），因此要自行定义

隐式依赖
------

多数模板依赖可以从模板中的 `render` 调用中推导出来。下面举例说明 `ActionView::Digestor` 知道如何解码的 `render` 调用

``` ruby

render partial: "comments/comment", collection: commentable.comments
render "comments/comments"
render 'comments/comments'
render('comments/comments')

render "header" => render("comments/header")

render(@topic)         # => render("topics/topic")
render(topics)         # => render("topics/topic")
render(message.topics) # => render("topics/topic")
```

而另一方面，有些调用要做修改方能让缓存正确工作。例如，如果传入自定义的集合，要把下述代码：

``` ruby
render @project.documents.where(published: true)
```

改为

``` ruby
render partial: "documents/document", collection: @project.documents.where(published: true)
```

显式依赖
------
有时，模板依赖推导不出来。在辅助方法中渲染时经常是这样

``` erb
<%= render_sortable_todolists @project.todolists %>
```

此时，要使用一种特殊的注释格式：
``` erb
<%# Template Dependency: todolists/todolist %>
<%= render_sortable_todolists @project.todolists %>
```

某些情况下，例如设置单表继承，可能要显式定义一堆依赖。此时无需写出每个模板，可以使用通配符匹配一个目录中的全部模板：
``` erb
<%# Template Dependency: events/* %>
<%= render_categorizable_events @person.events %>
```

对集合缓存来说，如果局部模板不是以干净的缓存调用开头，依然可以使用集合缓存，不过要在模板中的任意位置添加一种格式特殊的注释，如下所示：

``` erb
<%# Template Collection: notification %>
<% my_helper_that_calls_cache(some_arg, notification) do %>
  <%= notification.name %>
<% end %>
```

外部依赖
------

如果在缓存的块中使用辅助方法，而后更新了辅助方法，还要更新缓存。具体方法不限，只要能改变模板文件的 MD5 值就行。推荐的方法之一是添加一个注释，如下所示：

``` erb
<%# Helper Dependency Updated: Jul 28, 2015 at 7pm %>
<%= some_helper_method(person) %>
```

低层缓存
======

有时需要缓存特定的值或查询结果，而不是缓存视图片段。Rails 的缓存机制能存储任何类型的信息。

实现低层缓存最有效的方式是使用 `Rails.cache.fetch` 方法。这个方法既能读取也能写入缓存。传入单个参数时，获取指定的键，返回缓存中的值。如果传入块，块中的代码在缓存缺失时执行。块返回的值将写入缓存，存在指定键的名下，然后返回那个返回值。如果命中缓存，直接返回缓存的值，而不执行块中的代码。

下面举个例子。应用中有个 `Product` 模型，它有个实例方法，在竞争网站中查找商品的价格。这个方法返回的数据特别适合使用低层缓存：

``` ruby
class Product < ApplicationRecord
  def competing_price
    Rails.cache.fetch("#{cache_key}/competing_price", expires_in: 12.hours) do
      Competitor::API.find_price(id)
    end
  end
end
```


> 注意，这个示例使用了 `cache_key` 方法，因此得到的缓存键类似这种：`products/233-20140225082222765838000/competing_price`。`cache_key` 方法根据模型的 `id` 和 `updated_at` 属性生成一个字符串。这是常见的约定，有个好处是，商品更新后缓存自动失效。一般来说，使用低层缓存缓存实例层信息时，需要生成缓存键。


SQL 缓存
======
查询缓存是 Rails 提供的一个功能，把各个查询的结果集缓存起来。如果在同一个请求中遇到了相同的查询，Rails 会使用缓存的结果集，而不再次到数据库中运行查询。

例如：
``` ruby
class ProductsController < ApplicationController

  def index
    # 运行查找查询
    @products = Product.all

    ...

    # 再次运行相同的查询
    @products = Product.all
  end

end
```

再次运行相同的查询时，根本不会发给数据库。首次运行查询得到的结果存储在查询缓存中（内存里），第二次查询从内存中获取。

然而要知道，查询缓存在动作开头创建，到动作末尾销毁，只在动作的存续时间内存在。如果想持久化存储查询结果，使用低层缓存也能实现

---