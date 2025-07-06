+++
layout = "article"
title = "Ruby元编程手册"
copyright = true
comment = true
date = 2018-09-20 20:57:10
tags = ["Ruby", "元编程"]
categories = "Ruby"
+++

> 这里列出了《Ruby 元编程》介绍的所用法术


环绕别名 Around Alias
======

从一个重新定义的方法中调用原始的、被重命名的版本

``` ruby
  class String
    alias_method :old_reverse, :reverse

    def reverse
      "x#{old_reverse}x"
    end
  end

  'abc'.reverse # => 'xcbax'
```
<!-- more -->

白板类 Blank Slate
======

移除一个对象中的所有方法，以便吧他们转换成幽灵方法

``` ruby
  class C
    def method_missing(name, *args)
      "#{name} is a ghost method"
    end
  end

  obj = C.new
  obj.to_s # => "#<C:...>"

  class B < BasicObject
    def method_missing(name, *args)
      "#{name} is a ghost method"
    end
  end

  blank_slate = B.new
  blank_slate.to_s # => "to_s is a ghost method"
```

类扩展 Class Extension
======

通过向类的单件类中加入模块来定义类方法，是对象扩展的一个特例

``` ruby
  class C
  end

  module M
    def a_method
      'a method'
    end
  end

  class << C
    include M
  end

  C.a_method # => 'a method'
```

类实例变量 Class Instance Variable
======

在一个Class对象的实例变量中存储类级别的状态

``` ruby
  class C
    @my_class_instance_variable = 'some value'

    def self.class_attribute
      @my_class_instance_variable
    end
  end

  C.class_attribute # => 'some value'
```

类宏 Class Macro
======

在类定义中使用方法

``` ruby
  class C
  end

  class << C
    def a_method(arg)
      "a_method(#{arg} called)"
    end
  end

  class C
    a_method :x # => "a_method(x) called"
  end
```

洁净室 Clean Room
======

使用一个对象作为执行一个代码块的环境

``` ruby
  class CleanRoom
    def a_userful_method x
      x * 2
    end
  end

  CleanRoom.new.instance_eval { a_userful_method(3) } # => 6
```

代码处理器 Code Processor
======

处理从外部活的的代码字符串

``` ruby
  File.readlines('a_file_containing_lines_of_ruby.txt').each do |line|
    puts "#{line.chomp} ==> #{eval(line)}"
  end

  # => 1 + 1 ==> 2
  # => Math.log10(100) ==> 2.0
```

上下文探针 Context Probe
======

执行一个代码块来获取一个对象上下文中的信息

``` ruby
  class C
    def initialize
      @x = 'a private instance variable'
    end
  end

  obj = C.new
  obj.instance_eval { @x } # => 'a private instance variable'
```

延迟执行 Deferred Evaluation
======

在 proc 或 lambda 中存储一段代码及其上下文，用于以后执行

``` ruby
  class C
    def store(&block)
      @my_code_capsule = block
    end

    def execute(*args)
      @my_code_capsule.call(*args)
    end
  end

  obj = C.new
  obj.store { $X = 1 }
  $X = 0

  obj.execute
  $X # => 1
```

动态派发 Dynamic Dispatch
======

在运行是决定调用哪个方法

``` ruby
  method_to_call = :reverse
  obj = 'abc'
  obj.send(method_to_call) # => 'reverse'
```

动态方法 Dynamic Method
======

在运行是决定怎样定义一个方法

``` ruby
  class C
  end

  C.class_eval do
    define_method :a_method do
      'a dynamic method'
    end
  end

  obj = C.new
  c.a_method # => 'a dynamic method'
```

动态代理 Dynamic Proxy
======

把不能对应某个方法名的消息转发给另外一个对象

``` ruby
  class MyDynamicProxy
    def initialize(target)
      @target = target
    end

    def method_missing(name, *args, &block)
      "result: #{@target.send(name, *args, &block)}"
    end
  end

  obj = MyDynamicProxy.new('a string')
  obj.reverse # => 'result: gnirts a'
```

扁平作用域 Flat Scope
======

使用闭包在两个作用域之间共享变量

``` ruby
  class C
    def an_attribute
      @attr
    end
  end

  obj = C.new
  a_variable = 100
  obj.instance_eval do
    @attr = a_variable
  end

  obj.an_attribute # => 100
```

幽灵方法 Ghost Method
======

响应一个没有关联方法的消息

``` ruby
  class C
    def method_missing(name, *args)
      name.to_s.reverse
    end
  end

  obj = C.new
  obj.my_ghost_method # => 'dohtem_tsohg_ym'
```

钩子方法 Hook Method
======

复写一个方法来截获对象模型事件

``` ruby
  $INHERITORS = []

  class C
    def self.inherited(subclass)
      $INHERITORS << subclass
    end
  end

  class D < C
  end

  class E < D
  end

  class F < E
  end

  $INHERITORS # => [D, E ,F]
```

内核方法 Kernel Method
======

在Kernel模块中定义一个方法，使得所有对象都可使用

``` ruby
  module Kernel
    def a_method
      'a kernel method'
    end
  end

  a_method # => 'a kernel method'
```

惰性实例变量 Lazy Instance Variable
======

等第一次访问一个实例变量时才对它进行初始化

``` ruby
  class C
    def attribute
      @attribute = @attribute || 'some value'
    end
  end

  obj = C.new
  obj.attribute # => 'some value'
```

拟态方法 Mimic Method
======

把一个方法伪装成另外一种语言构件

``` ruby
  def BaseClass name
    name == 'string' ? String : Object
  end

  class C < BaseClass 'string' # 一个看起像类的方法
    attr_accessor :an_attribute # 一个看起像关键字的方法
  end

  obj = C.new
  obj.an_attribute = 1 # 一个看起像属性的方法
```

猴子打补丁 Monkeypatch
======

修改已有类的特性

``` ruby
  'abc'.reverse # => 'cba'

  class String
    def reverse
      'override'
    end
  end

  'abc'.reverse # => 'override'
```

命名空间 Namespace
======

在一个模块中定义常量，以防止命名冲突

``` ruby
  module MyNamespace
    class Array
      def to_s
        'to_a method in array of the my namespace'
      end
    end
  end

  Array.new.to_s # => []
  MyNamespace::Array.new.to_s # => 'to_a method in array of the my namespace'
```

空指针保护 Nil Guard
======

用'||'操作符覆写一个空引用

``` ruby
  x = nil
  y = x || 'a value' # => 'a value'
```

对象扩展 Object Extension
======

通过一个对象的单件类混入模块来定义单件方法

``` ruby
  obj = Object.new

  module M
    def a_method
      'a singleton method in M'
    end
  end

  class << obj
    include M
  end

  obj.a_method # => 'a singleton method'
```

打开类 Open Class
======

修改已有的类

``` ruby
  class String
    def a_method
      'a method'
    end
  end

  'abc'.a_method # => 'a method'
```

下包含包装器 Prepended Wrapper
======

调用一个用 prepend 方式覆写的方法

``` ruby
  module M
    def reverse
      "x#{super}x"
    end
  end

  String.class_eval do
    prepend M
  end

  'abc'.reverse # => 'xcbax'
```

细化 Refinement
======

为类打补丁，作用范围仅到文件结束，或仅限于包含模块的作用域中

``` ruby
  module MyRefinement
    refine String do
      def reverse
        'refinement reverse'
      end
    end
  end

  'abc'.reverse # => 'cba'
  using MyRefinement
  'abc'.reverse # => 'refine reverse'
```

细化封装器 Refinement Wrapper
======

在细化中调用非细化的方法

``` ruby
  module StringRefinement
    refine String do
      def reverse
        "x#{super}x"
      end
    end
  end

  using StringRefinement
  'abc'.reverse # => 'xcbax'
```

沙盒 Sandbox
======

在一个安全的环境中执行未授权的代码

``` ruby
  def sandbox &code
    proc do
      $SAFE = 2
      yield
    end.call
  end

  begin
    sandbox { File.delete 'a_file' }
  rescue Exception => ex
    ex # =>
  end
```

作用域门 Scope Gate
======

用class, module 或 def 关键字来隔离作用域

``` ruby
  a = 1

  defined? a # => 'local-variable'

  module MModule
    b = 1
    defined? a # => nil
    defined? b # => 'local-variable'
  end

  defined? a # => 'local-variable'
  defined? b # => nil
```

Self Yield
======

把self传给当前代码块

``` ruby
  class Person
    attr_accessor :name, :surname

    def initialize
      yield self
    end
  end

  joe = Person.new do |person|
    person.name = 'Joe'
    person.surname = 'Smith'
  end
```

共享作用域 Shared Scope
======

在同一个扁平作用域的多个上下文中共享变量

``` ruby
  lambda do
    shared = 10
    self.class_eval do
      defined_method :counter do
        shared
      end

      defined_method :down do
        shared -= 1
      end
    end
  end.call

  counter # => 10
  3.times { down }
  counter # => 7
```

单件方法 Singleton Method
======

在一个对象上定义一个方法

``` ruby
  obj = 'abc'

  class << obj
    def obj_singleton_method
      'x'
    end
  end

  obj.obj_singleton_method # => 'x'
```

代码字符串 String of Code
======

执行一段表示ruby代码的字符串

``` ruby
  string_of_code = '1 + 1'
  eval(string_of_code) # => 2
```

符号到Proc Symbol To Proc
======

把一个调用单个方的块转换为一个符号

``` ruby
  (1..6).map(&:even?) # => [false, true, false, true, false, true]
```

---