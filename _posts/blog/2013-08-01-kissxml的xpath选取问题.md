---
layout: post
title: KissXML的XPath选取问题
categories: blog
tags: xmppframe kissxml xpath
---

XMPPFramework用的XML解析库还是大神自己写的[KissXML](https://github.com/robbiehanson/KissXML)，有些人生下来就是让人仰望的，哎。

进入主题,如下一段XML:

	<params xmlns="namespace">
		<param name="text">text in element</param>
		<param name="voice">voice in element</param>
	</params>
	
需要得到各个`<param/>`子元素中的键值对应关系`text->text in element`和`voice->voice in element`。最简单的方法就是用XPath选取指定的元素。

KissXML的NSXMLElement类的父类NSXMLNode有一个通过XPath选取子元素得到数组的方法：
	
	- (NSArray *)nodesForXPath:(NSString *)xpath error:(NSError **)error;
	
试之，竟然返回为空。。搜之，发现KissXML上已经有人开了issue，还有热心人把[代码](https://github.com/tipbit/KissXML/commit/48701f10befe903237db12af726a93041d19d244)都补上了，这个世界上还是好人多啊。

前面的方法不能是因为`<params/>`中设置了namespace,需要为元素注册这个namespace，所以修改后的方法为： 

	- (NSArray *)nodesForXPath:(NSString *)xpath namespaceMappings:(NSDictionary*)namespaceMappings error:(NSError **)error
	

第一步： 在namespaceMappings中设置一个命名空间的别名,如这样的：@{@"prefix":@"namespace"} ；

第二步： 在XPath中使用别名 `//prefix:param`

	
    NSString *xmlstring =   @"<params xmlns=\"namespace\" >"
                            @"<param name=\"text\">text in element</param>"
                            @"<param name=\"voice\">voice in element</param>"
                            @"</params>";
    
    NSXMLElement *element = [[NSXMLElement alloc] initWithXMLString:xmlstring error:nil];
    
    NSDictionary *namespaceMap= @{@"prefix":@"namespace"};
    NSArray *subelements = [element nodesForXPath:@"//prefix:param" namespaceMappings:namespaceMap  error:nil];
    for (NSXMLElement *e in subelements) {
        NSLog(@"sublelement: %@", [e XMLString]);
    }

这样就可以选到`<param/>`子元素了。

	2013-08-01 17:35:04.624 ChatModule[14387:c07] sublelement: <param name="text">text in element</param>
	2013-08-01 17:35:04.625 ChatModule[14387:c07] sublelement: <param name="voice">voice in element</param>
	
进一步的，如果想要选择`name`是`text`的`<param/>`元素，可以使用更精确的XPath: `//prefix:param[@name='text']`。

关于为什么要注册namespace，还需要读libxml2的代码，后面抽时间看一下，改动后的代码中加了这么一段：

	if (namespaceMappings) {
		for (NSString* k in namespaceMappings) {
			NSString* v = [namespaceMappings objectForKey:k];
			xmlXPathRegisterNs(xpathCtx, [k xmlChar], [v xmlChar]);
		}
	}
	
看SO上有人直接用libxml2的时候也有这个问题，[xpath-query-for-a-node](http://stackoverflow.com/questions/3744059/xpath-query-for-a-node) 。


关于XPath的语法，[戳这里](http://www.w3school.com.cn/xpath/xpath_syntax.asp) .

完。

