+++
layout = "article"
title = "Ruby中的钩子方法"
copyright = true
comment = true
date = 2018-09-29 23:19:03
tags = ["Ruby"]
categories = "Ruby"
+++


> 钩子方法提供了一种方式用于在程序运行时扩展程序的行为

参考地址：[Ruby 中一些重要的钩子方法](https://ruby-china.org/topics/25397)

<!-- more -->

included
=======

`included`方法是基于`include`的方法，可以在一些`module`或者`class`中`include`了一个`module`时它会被调用。实际在执行`included`之前，模块中的`append_features`被调用并执行具体的`include`操作，注意使用时不要随意覆盖Ruby的`append_features`方法

``` ruby
  module M
    def self.included(base)
      puts "#{base} included #{self}"
    end

    def a_method
      puts "a_method in M"
    end
  end

  class C
    include M
  end
  # => "C included M"

  module O
    include M
  end
  # =>
```

当执行`include M`时，M中的`included`方法将会被调用，`base`既是执行`include`时包含该`module`的类名

extended
=======

扩展(extend) 一个模块，这与 包含(`include`) 有点不同。 `extend`是将定义在 模块(module) 内的方法应用为类的方法，而不是实例的方法, `extended`就是`extend`相对应的钩子方法，注意使用时不要随意覆盖Ruby的`extend_object`方法

``` ruby
  module M
    def self.extended(base)
      puts "#{base} extended #{self}"
    end

    def a_method
      puts "a_method in M"
    end
  end

  class C
    extend M
  end
  # => "C extended M"

  module O
    extend M
  end
  # => "O extended M"
```

prepended
=======

`prepend`是在Ruby 2.0中引入的，并且与`include`和`extend`很不一样。 使用 `include`和`extend`引入的方法可以被目标模块/类重新定义覆盖,而`prepend`是不一样的，它会将`prepend`引入的模块 中的方法覆盖掉我们模块/类中定义的方法，`prepended`就是`prepend`的钩子方法，注意使用时不要随意覆盖Ruby的`prepend_features`方法

``` ruby
  module M
    def self.prepended(base)
      puts "#{base} prepended to #{self}"
    end

    def a_method
      puts "a_method in M"
    end
  end

  class C
    prepend M
  end
  # => "C prepended to M"

  module O
    prepend M
  end
  # => "O prepended to M"
```

inherited
=======

继承是面向对象中一个最重要的概念。Ruby是一门面向对象的编程语言，并且提供了从基/父类继承一个子类的功能，`inherited`就是继承的钩子方法

``` ruby
  class M
    def self.inherited(base)
      puts "#{base} inherits #{self}"
    end

    def a_method
      puts "a_method in M"
    end
  end

  class C < M; end
  # => "C inherits M"
```

method的钩子方法
=======

定义，删除，取消当前类中定义的方法时会触发类或者单例类的相对应的钩子方法

``` ruby
class C
  def self.method_added(method_name)
    puts "Adding #{method_name.inspect}"
  end

  def self.method_removed(method_name)
    puts "Removing #{method_name.inspect}"
  end

  def self.method_undefined(method_name)
    puts "Undefined #{method_name.inspect}"
  end

  # 触发singleton_method_added钩子方法
  def self.singleton_method_added(method_name)
    puts "Adding singleton #{method_name.inspect}"
  end

  # 触发singleton_method_added钩子方法
  def self.singleton_method_removed(method_name)
    puts "Removing singleton #{method_name.inspect}"
  end

  # 触发singleton_method_added钩子方法
  def self.singleton_method_undefined(method_name)
    puts "Undefined singleton #{method_name.inspect}"
  end

  # 触发singleton_method_added钩子方法
  def self.singleton_class_method_added(); end
  # 触发method_added钩子方法
  def class_method_added(); end

  # 触发singleton_method_added钩子方法
  def self.singleton_class_method_removed(); end
  # 触发method_added钩子方法
  def class_method_removed(); end

  # 触发singleton_method_added钩子方法
  def self.singleton_class_method_undefined(); end
  # 触发method_added钩子方法
  def class_method_undefined(); end

  class << self
    # 触发singleton_method_removed钩子方法
    remove_method :singleton_class_method_removed
    # 触发singleton_method_undefined钩子方法
    undef_method :singleton_class_method_undefined
  end

  # 触发method_removed钩子方法
  remove_method :class_method_removed
  # 触发method_undefined钩子方法
  undef_method :class_method_undefined
end

# Adding singleton :singleton_method_added
# Adding singleton :singleton_method_removed
# Adding singleton :singleton_method_undefined
# Adding singleton :singleton_class_method_added
# Adding :class_method_added
# Adding singleton :singleton_class_method_removed
# Adding :class_method_removed
# Adding singleton :singleton_class_method_undefined
# Adding :class_method_undefined
# Removing singleton :singleton_class_method_removed
# Undefined singleton :singleton_class_method_undefined
# Removing :class_method_removed
# Undefined :class_method_undefined
```


---