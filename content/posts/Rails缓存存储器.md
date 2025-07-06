+++
layout = "article"
title = "Rails缓存存储器"
copyright = true
comment = true
date = 2018-09-26 22:18:51
tags = ["Ruby", "Rails"]
categories = "Rails"
+++


> Rails 为存储缓存数据（SQL 缓存和页面缓存除外）提供了不同的存储器。


[原文地址](https://ruby-china.github.io/rails-guides/caching_with_rails.html#cache-stores)

<!-- more -->

配置
======
`config.cache_store` 配置选项用于设定应用的默认缓存存储器。可以设定其他参数，传给缓存存储器的构造方法

``` ruby
config.cache_store = :memory_store, { size: 64.megabytes }
```

> 此外，还可以在配置块外部调用 `ActionController::Base.cache_store`。


缓存存储器通过 `Rails.cache` 访问。


ActiveSupport::Cache::Store
======

这个类是在 Rails 中与缓存交互的基础。这是个抽象类，不能直接使用。你必须根据存储器引擎具体实现这个类。Rails 提供了几个实现，说明如下。

主要调用的方法有`read`、`write`、`delete`、`exist?`和`fetch`。`fetch`方法接受一个块，返回缓存中现有的值，或者把新值写入缓存。

所有缓存实现有些共用的选项，可以传给构造方法，或者传给与缓存条目交互的各个方法。

- `:namespace`：在缓存存储器中创建命名空间。如果与其他应用共用同一个缓存存储器，这个选项特别有用。
- `:compress`：指定压缩缓存。通过缓慢的网络传输大量缓存时用得着。
- `:compress_threshold`：与 `:compress`选项搭配使用，指定一个阈值，未达到时不压缩缓存。默认为16千字节。
- `:expires_in`：为缓存条目设定失效时间（秒数），失效后自动从缓存中删除。
- `:race_condition_ttl`：与 `:expires_in`选项搭配使用。避免多个进程同时重新生成相同的缓存条目（也叫 dog pile effect），防止让缓存条目过期时出现条件竞争。这个选项设定在重新生成新值时失效的条目还可以继续使用多久（秒数）。如果使用 `:expires_in `选项，最好也设定这个选项。

### 自定义缓存存储器

缓存存储器可以自己定义，只需扩展`ActiveSupport::Cache::Store`类，实现相应的方法。这样，你可以把任何缓存技术带到你的 Rails 应用中。

若想使用自定义的缓存存储器，只需把`cache_store`设为自定义类的实例：

``` ruby
config.cache_store = MyCacheStore.new
```

ActiveSupport::Cache::MemoryStore
======

这个缓存存储器把缓存条目放在内存中，与 Ruby 进程放在一起。可以把`:size`选项传给构造方法，指定缓存的大小限制（默认为`32Mb`）。超过分配的大小后，会清理缓存，把最不常用的条目删除。

``` ruby
config.cache_store = :memory_store, { size: 64.megabytes }
```

如果运行多个 Ruby on Rails 服务器进程（例如使用 Phusion Passenger 或 Puma 集群模式），各个实例之间无法共享缓存数据。这个缓存存储器不适合大型应用使用。不过，适合只有几个服务器进程的低流量小型应用使用，也适合在开发环境和测试环境中使用

ActiveSupport::Cache::FileStore
======

这个缓存存储器使用文件系统存储缓存条目。初始化这个存储器时，必须指定存储文件的目录：

``` ruby
config.cache_store = :file_store, "/path/to/cache/directory"
```

使用这个缓存存储器时，在同一台主机中运行的多个服务器进程可以共享缓存。这个缓存存储器适合一到两个主机的中低流量网站使用。运行在不同主机中的多个服务器进程若想共享缓存，可以使用共享的文件系统，但是不建议这么做。

缓存量一直增加，直到填满磁盘，所以建议你定期清理旧缓存条目。

这是默认的缓存存储器

ActiveSupport::Cache::MemCacheStore
======
这个缓存存储器使用 Danga 的`memcached`服务器为应用提供中心化缓存。Rails 默认使用自带的`dalli` gem。这是生产环境的网站目前最常使用的缓存存储器。通过它可以实现单个共享的缓存集群，效率很高，有较好的冗余。

初始化这个缓存存储器时，要指定集群中所有`memcached`服务器的地址。如果不指定，假定 `memcached`运行在本地的默认端口上，但是对大型网站来说，这样做并不好。

这个缓存存储器的`write`和`fetch`方法接受两个额外的选项，以便利用`memcached`的独有特性。指定`:raw`时，直接把值发给服务器，不做序列化。值必须是字符串或数字。`memcached`的直接操作，如`increment`和`decrement`，只能用于原始值。还可以指定`:unless_exist`选项，不让`memcached`覆盖现有条目。

``` ruby
config.cache_store = :mem_cache_store, "cache-1.example.com", "cache-2.example.com"
```

ActiveSupport::Cache::NullStore
======

这个缓存存储器只应该在开发或测试环境中使用，它并不存储任何信息。在开发环境中，如果代码直接与`Rails.cache` 交互，但是缓存可能对代码的结果有影响，可以使用这个缓存存储器。在这个缓存存储器上调用`fetch`和`read`方法不返回任何值。

``` ruby
config.cache_store = :null_store
```

缓存键
======
缓存中使用的键可以是能响应`cache_key`或 `to_param`方法的任何对象。如果想定制生成键的方式，可以覆盖`cache_key`方法。Active Record 根据类名和记录 ID 生成缓存键。

缓存键的值可以是散列或数组：
``` ruby
# 这是一个有效的缓存键
Rails.cache.read(site: "mysite", owners: [owner_1, owner_2])
```
`Rails.cache`使用的键与存储引擎使用的并不相同，存储引擎使用的键可能含有命名空间，或者根据后端的限制做调整。这意味着，使用`Rails.cache`存储值时使用的键可能无法用于供 `dalli` gem 获取缓存条目。然而，你也无需担心会超出`memcached`的大小限制，或者违背句法规则

---