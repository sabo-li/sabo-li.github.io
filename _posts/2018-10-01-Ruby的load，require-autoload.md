---
layout: article
title: 'Ruby的load，require, autoload'
copyright: true
comment: true
date: 2018-10-01 23:53:39
tags: [Ruby]
categories: Ruby
---

<!-- * 加载其他文件 -->
参考地址：[Ruby 中 require,load,autoload,extend,include,prepend 的区别](https://ruby-china.org/topics/35350)

load(filename, wrap=false) # => true
=====

每次调用都会加载并执行文件文件名中的Ruby程序。如果该文件不在绝对路径中，则在`$:`中查找该文件。如果`wrap`参数为`true`，则加载脚本在匿名模块下执行，从而保护调用程序的全局名称空间。任何情况下，加载文件中的任何局部变量都不会加载到调用程序的环境中

<!-- more -->

require(name) # => true or false
=====

加载指定名称的文件，如果加载成功返回`true`, 如果已经加载返回`false`
如果文件不在绝对路径中，则将在`$LOAD_PATH` `($:)`中查找
如果文件名后缀为`.rb`，则加载源文件。如果扩展名是当前系统平台上的二进制库文件，如`.so`，`.o`或者`.dll`，则Ruby会二进制库加载为Ruby扩展。否则，Ruby会尝试添加`.rb`，`.so`等直到找到为止。否则，就会触发LoadError异常
Ruby扩展名给出的文件名可以使用任何共享库扩展, 例如，在Linux上，套接字扩展名为`socket.so`，`require "socket.dll"` 将加载套接字扩展名
加载文件的路径将被添加到`$LOADED_FEATURES` `($")`中
加载的源文件中的任何常量或全局变量都将在调用程序的全局命名空间中可用

autoload(module, filename) # => nil
=====

`module`通常是模块名或者类名，只有在调用模块或者类时才会加载文件

``` ruby
# m.rb
module M
  puts 'Load M module'
  class A
    def self.hello
      puts 'Hello'
    end
  end
end

## require ：只加载一次
puts "first load: #{(require './m.rb')}"
#= > load M module
#= > first load: true
puts "load again: #{(require './m.rb')}"
#= > load again: false

# load ：多次加载
puts "first load: #{(load './m.rb')}"
#= > load M module
#= > first load: true
puts "load again: #{(load './m.rb')}"
#= > load M module
#= > load again: true

# autoload ：调用时才加载
puts "first load: #{autoload(:M,'./m.rb')}"
#= > first load:
puts "load again: #{autoload(:M,'./m.rb')}"
#= > load again:

M::A.hello
# => Load M module
#= > Hello
```


---