---
layout: post
title: Objective-C实现多重代理
categories: blog
tags: objective-c delegate design-patterns
---



在OC中，一般实现代理的模式如下(用NSURLConnection和AFNetworking的代码做示例)：

首先定义`NSURLConnectionDataDelegate`:

	@protocol NSURLConnectionDataDelegate <NSURLConnectionDelegate>
	@optional
	
	…
	- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
	…
	

然后在初始化`NSURLConnection`传入一个代理对象；

	- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate;

这个代理对象实现协议中的方法:

	@interface AFURLConnectionOperation : NSOperation <NSURLConnectionDelegate,
	#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 50000) || \
	    (defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED >= 1080)
	NSURLConnectionDataDelegate, 
	#endif
	NSCoding, NSCopying>
	
	…
	
	- (void)connection:(NSURLConnection __unused *)connection
	    didReceiveData:(NSData *)data
	{
	    NSUInteger length = [data length];
	    if ([self.outputStream hasSpaceAvailable]) {
	        const uint8_t *dataBuffer = (uint8_t *) [data bytes];
	        [self.outputStream write:&dataBuffer[0] maxLength:length];
	    }
	    
	    dispatch_async(dispatch_get_main_queue(), ^{
	        self.totalBytesRead += length;
	        
	        if (self.downloadProgress) {
	            self.downloadProgress(length, self.totalBytesRead, self.response.expectedContentLength);
	        }
	    });
	}

在`NSURLConnection`中某个合适的时机，代理方法将被调用。

这是iOS开发中最常用的一种模式。但是这样做有个小问题，不能将多个不同的对象设置为一个对象代理类。这种应用场景还是很常见的，例如，在聊天页面设置一个收到消息的代理，实时的更新聊天界面，在历史记录页面也是需要设置代理，更新历史记录，但是聊天页面和历史记录肯定是不同的类。在XMPPFramework中，实现了一个工具类`GCDMulticastDelegate`,可以将消息分发到多个代理类。


### GCDMulticastDelegate


                                                +--------------------------------------------------+
                                                |Module                                            |
                                                |                                                  |
                                                |                              Call Delegate       |
                                                |                                 |                |
                                                | +-------------------------------v-------------+  |
                                                | |GCDMulticastDelegate                         |  |
                                                | |                               +             |  |
                                                | |                               |             |  |
                                                | | +--------------------------+  |Enumerate    |  |
            +-----------------------+           | | | GCDMulticastDelegateNode |  |             |  |
            |         Object        |  add      | | |--------------------------|  |             |  |
            |-----------------------|<--------------->delegate                 <--+             |  |
            | moduleDelegateMethod  |  call     | | | delegateQueue            |  |             |  |
            +-----------------------+           | | +--------------------------+  |             |  |
                                                | |                               |             |  |
                                                | | +--------------------------+  |             |  |
                                                | | | GCDMulticastDelegateNode |  |             |  |
            +-----------------------+  add      | | |--------------------------|  |             |  |
            |         Object        |<--------------->delegate                 <--+             |  |
            |-----------------------|  call     | | | delegateQueue            |  |             |  |
            | moduleDelegateMethod  |           | | +--------------------------+  |             |  |
            +-----------------------+           | |                               |             |  |
                          ...                   | |             ...               v             |  |
                                                | |                                             |  |
                                                | +---------------------------------------------+  |
                                                |                                                  |
                                                +--------------------------------------------------+
                                                

模块中有一个类型为`GCDMulticastDelegate`的成员变量。 `GCDMulticastDelegate`包含一个数组，数组中的每个节点包含实现(其实也可以没有实现)了代理协议中方法的对象的弱引用，这个节点是通过Module暴露出来的方法添加到`GCDMulticastDelegate`的。当Module处理过程中，发生了某个事件，调用了代理的方法，`GCDMulticastDelegate`就遍历节点数组，一次在节点引用的队列上调用代理方法。

上面的Module是XMPPFramework中出现的。我把`GCDMulticastDelegate`抽取出来，可以为我们所用,代码在[这里](https://github.com/iRusher/GCDMulticastDelegate)。






