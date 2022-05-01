---
layout: article
title: 'Rails中的ActiveSupport::Concern'
copyright: true
comment: true
date: 2018-09-28 23:58:32
tags: [Ruby, Rails]
categories: Rails
---

普通的mixin
======

``` ruby
module M
  # self.included是include时的钩子方法
  def self.included(base)
    # base扩展
    base.extend ClassMethods

    # 打开base，在base中执行代码
    base.class_eval do
      # 这里写一个类include时在类需要执行什么动作
    end
  end

  module ClassMethods
    # 这里写一个类include该module后生成的类方法
  end

  # 这里写一个类include该module后生成的实例类方法
end
```
<!-- more -->

使用 ActiveSupport::Concern
=======

``` ruby
require 'active_support/concern'

module M
  # 扩展当前module
  extend ActiveSupport::Concern

  # 调用Concern中定义的included方法
  included do
    # 这里写一个类include时在类需要执行什么动作
  end

  # 调用Concern中定义的class_methods方法
  class_methods do
    # 这里写一个类include该module后生成的类方法
  end

  # 这里写一个类include该module后生成的实例类方法
end
```

解读 ActiveSupport::Concern
======

``` ruby
module ActiveSupport
  module Concern

    # 定义了一个异常类，不能多次include
    class MultipleIncludedBlocks < StandardError
      def initialize
        super "Cannot define multiple 'included' blocks for a Concern"
      end
    end

    # self.extended是extend时的钩子方法
    def self.extended(base)
      # 定义base中的@_dependencies
      base.instance_variable_set(:@_dependencies, [])
    end

    # ruby在include一个module时会调用append_features方法，进行实际的mixin操作，包括增加常量，方法和变量到模块中
    def append_features(base)
      if base.instance_variable_defined?(:@_dependencies)
        # 如果有引入已经定义@_dependencies时，一般是引入一个已经extend这个Concern的module，才会定义@_dependencies
        # 将后extend这个Concern的module放入到@_dependencies中
        base.instance_variable_get(:@_dependencies) << self
        false
      else
        return false if base < self

        # @_dependencies是详见上面定义的self.extended
        # 先引入包含在@_dependencies中module
        @_dependencies.each { |dep| base.include(dep) }
        super

        # ClassMethods是详见下面定义的class_methods
        # 如果定义ClassMethods,将ClassMethods中的方法extend到base中
        base.extend const_get(:ClassMethods) if const_defined?(:ClassMethods)

        # @_included_block是详见下面定义的included方法
        # 如果定义@_included_block,在base中执行@_included_block中的代码
        base.class_eval(&@_included_block) if instance_variable_defined?(:@_included_block)
      end
    end

    # extend后，将可以使用included这个方法
    def included(base = nil, &block)
      if base.nil?
        # 判断是否多次include
        raise MultipleIncludedBlocks if instance_variable_defined?(:@_included_block)

        # 定义类实例类变量
        @_included_block = block
      else
        super
      end
    end

    # extend后，将可以使用class_methods这个方法
    def class_methods(&class_methods_module_definition)
      # extend时判断当前module是否定义了ClassMethods这个常量，不包括父级
      # 有的话就使用已经定义好的，没有就Module.new一个
      mod = const_defined?(:ClassMethods, false) ?
        const_get(:ClassMethods) :
        const_set(:ClassMethods, Module.new)

      # extend后，调用class_methods方时将块里的定写入到ClassMethods里
      mod.module_eval(&class_methods_module_definition)
    end
  end
end
```

---
