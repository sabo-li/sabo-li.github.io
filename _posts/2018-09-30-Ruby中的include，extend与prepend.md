---
layout: article
title: Ruby中的include，extend与prepend
copyright: true
comment: true
date: 2018-09-30 23:32:30
tags: [Ruby]
categories: Ruby
key: post-16
---
include, extend, prepend
======
参考地址：[ruby include extend prepend 使用方法](https://ruby-china.org/topics/21501)
<!-- more -->
``` ruby
  module A
    def a_method
      puts 'a method'
    end

    def self.aa_method
      puts 'aa method'
    end
  end

  module B
    extend A
  end

  module C
    include A
  end

  class AA
    extend A
  end

  class BB
    include A
  end

  class CC
    prepend A

    def a_method
      puts 'a method in CC'
    end
  end

  B.ancestors # => [B]
  C.ancestors # => [C, A]
  AA.ancestors # => [AA, Object, Kernel, BasicObject]
  BB.ancestors # => [BB, A, Object, Kernel, BasicObject]
  CC.ancestors # => [A, CC, Object, Kernel, BasicObject]
```

BB将新增一个类方法，AA的祖先链中没有A
CC将新增一个实例方法，BB的祖先链中有A

Ruby `prepend`与`include`类似，首先都是添加实例方法的，不同的是扩展module在祖先链上的放置位置不同

当调用方法时， Ruby是如何找到方法定义的
======

1. 实例方法，首先在实例中查找，然后再实例对象的单件类中查找，之后沿祖先链依次向上找
2. 类方法，首先在类的单件类中查找，然后沿着类的单件类的祖先链一次向上找（类的单件类的祖先链 = 类的祖先链的各个节点的单件类组成的链）


---