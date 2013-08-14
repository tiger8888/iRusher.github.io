---
layout: post
title: Objective-C runtime学习笔记
categories: blog
tags: objective-c runtime message
---



runtime相关的内容最近经常看到，看大牛们用到这些特性就像这样:

![nb.gif](http://i1.hoopchina.com.cn/user/376/3409376/1277105284c636c.gif) 

尤其是在一些工具类中，使用runtime的特性，通常能达到事半功倍的效果。

## Message,Method,Selector,Message Signature,Implementation的区别

一开始的时候可能会把这些概念都看做一个东西: 传统意义上的一个函数调用。但是，要使用runtime的特性时，这些概念就有必要分清楚。

**Selector(选择器)** : 一个方法的名字。就像`alloc`,`init`,`dictionaryWithObjectsAndKeys:`，其中的冒号也是Selector的一部分，用来标识方法是否需要参数。Selector有一个类型`SEL`: 

	SEL aSelector = @selector(doSomething:);
	// or
	SEL aSelector = NSSelectorFromString(@"doSomething");

**Message(消息)** : Selector和传入方法的参数构成一个Message。如果看到`[dictionary setObject:obj forKey:key]`,那么Message就是一个 __Selector__(`setObject:forKey:`)加 __参数__(`obj`和`key`) 。Message可以被封装到`NSInvocation`对象中。消息被发送到接收方，通常接收方是一个对象。

**Method(方法)** : Selecotr和“实现”（还有附带的元数据）构成一个Method。“实现”是一个函数指针(`IMP`),指向一段代码块。一个Method在运行时表示为`Method`结构体。

**Method Signature(方法签名)** : 方法签名记录一个方法的返回值的类型和传入参数的类型。在运行时由一个`NSMethodSignature`或一个`char *`字符串指针表示。

**Implementation(方法实现)** : “实现”在运行时中表示为`IMP`类型。事实上，这只是一个函数指针。iOS 4.3后包含了将一个`block`转化为`IMP`。

	IMP imp_implementationWithBlock(id block);

## Message动态绑定


### objc_message


在Objective-C中，Message只有在运行的时候才和方法实现绑定在一起，这就是所谓的动态绑定。编译器将一个表达式`[receiver message]`转换成`objc_msgSend(receiver, selector)`，如果消息中带有参数，也一并传递给`objc_msgSend`:
	
	objc_msgSend(receiver, selector, arg1, arg2, ...)

`objc_msgSend`完成整个动态绑定的过程：

* 首先，它会寻找`selector`指向的方法实现。由于相同的方法可能在不同的类中实现，具体指向的方法实现取决于`receiver`;
* 接下来调用方法实现，传入的所有参数都将传递给方法实现，接受对象自己也被传入方法实现(即`self`)；
* 最后，将方法实现的返回值作为自己的返回值返回。

Message传递的关键点在编译器为Class和Object构建的结构中。每个类结构都包含以下两个元素：

* 一个指向超类的指针；
* 一个类分发表(dispath table)。表中的记录由 __方法的Selector__ 和与其关联的具体的类的 __方法实现的地址__ 构成。

### isa 

当一个对象被创建后，它所占用的内存被分配，实例变量被初始化，紧接着，对象中的一个指针指向了对象的类结构，这个指针叫`isa`，可以使对象访问到它对应的类以及父类。

![isa](http://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Art/messaging1.gif)

当一个Message被发送到对象后，`objc_message`顺着对象的`isa`指针在其dispatch_table中查找Selector。如果没有找到，继续在超类的dispath_table中查找，如果一直未找到，则最终会到达`NSObject`类中；如果找到，就调用dispatch_table中Selector对应的方法实现，Messsage中传入的参数也一并交给方法实现。

>   选择使用哪个方法实现，是在运行过程中决定的，这就是消息的动态绑定。

为了加速动态查询的过程，运行时系统将Selector和它使用过的方法实现缓存起来。每个类持有各自的缓存，被缓存的方法实现可以使自己类中的，也可以是从超类中继承的。在搜索dispatch_table之前，先查询消息接受对象的类的缓存，如果找到，就直接使用缓存中的方法实现。

## @dynamic

## Message分发

