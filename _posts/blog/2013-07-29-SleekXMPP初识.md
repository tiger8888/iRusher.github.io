---
layout: post
title: SleekXMPP初识 
categories: blog
tags: xmpp python sleekxmpp  
---


后续需要做一些对XMPP的详细的测试，但是为了能使这些测试能使Android端和Web端也能重用，所以需要选择一个轻量级的库来完成测试任务。自然就想到了强大的Python。跨平台，Mac OSX，Windows都能使用,而且开发效率比较高。

[SleekXMPP](http://sleekxmpp.com/)是一个用python写成的XMPP库。在《XMPP: The Definitive Guide》一书中，作者就用SleekXMPP作为示例。

## 安装

#### 安装SleekXMPP

从Github上取到最新的版本：

	git clone https://github.com/fritzy/SleekXMPP.git
	cd SleekXMPP
	sudo python setup.py install

#### 安装DNSPython

用于解析DNS服务器，获取XMPP服务端的信息。具体文档[XMPP_SRV_Records](http://wiki.xmpp.org/web/SRV_Records)。

	git clone http://github.com/rthalley/dnspython
	cd dnspython
	python setup.py install

##示例

以下是官网中的例子，客户端收到一条消息后，立即返回一条信息。其中用到了`msg.reply`,是一个有意思的方法，将`message`中的to和from对调，这样就可以很方便的设置message的to和from属性值,库中还有很多方便的函数，总体来说API非常的友好。

	#!/usr/bin/python
	#!--*-- coding: UTF-8 --*--
	
	import logging
	
	from sleekxmpp import ClientXMPP
	from sleekxmpp.exceptions import IqError, IqTimeout
	import threading
	
	
	class EchoBot(ClientXMPP):
	
	    def __init__(self, jid, password):
	        ClientXMPP.__init__(self, jid, password)
	
	        self.add_event_handler("session_start", self.session_start)
	        self.add_event_handler("message", self.message)
	
	    def session_start(self, event):
	        self.send_presence()
	        self.get_roster()
	
	    def message(self, msg):
	        if msg['type'] in ('chat', 'normal'):
	            msg.reply("Thanks for sending\n%(body)s" % msg).send()
	
	if __name__ == '__main__':
	
	    logging.basicConfig(level=logging.DEBUG,
	                        format='%(levelname)-8s %(message)s')
	
	    xmpp = EchoBot('username', 'password')
	    xmpp.connect()
	
	    xmpp.process(block=True)
	   
	   
## 参考文档

1. [SleekXMPP Architecture](http://sleekxmpp.com/architecture.html)
2. [DNS Configuration](http://prosody.im/doc/dns)
