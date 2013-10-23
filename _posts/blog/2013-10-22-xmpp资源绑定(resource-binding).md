---
layout: post
title: XMPP资源绑定(Resource Binding)
categories: blog
tags: xmpp resource binding
---


一个XMPP的账号由三部分组成: 用户名(user/node)，域名(domain)和资源(resource) 。例如 alice@xmpp.irusher.com/mobile ，user部分(或node)是alice,domain是xmpp.irusher.com,resource部分是mobile。user和domain组合也叫Bare JID，例如：alice@xmpp.i8i8i8.com ，Bare JID常用标识一个用户。包含了user,domain和resource的ID也叫Full JID，在Full JID中，resource一般用来区分一个用户的多个会话，可以由服务端或客户端指定。下面介绍一下resource的绑定过程。

## 资源绑定

客户端通过服务端的验证之后，应该给XMPP流绑定一个特殊的资源以使服务端能够正确的定位到客户端。客户端Bare JID后必须附带resource，与服务端交互时使用Full JID，这样就确保服务端和客户端传输XML段时服务端能够正确的找到对应的客户端。

当一个客户端通过一个资源绑定到XML流上后，它就被称之为"已连接的资源"。服务器应该允许同时处理多个”已连接的资源“，每个”已连接的资源“由不同的XML流合不同的resource来区分。

资源绑定用到的XML命名空间为 "urn:ietf:params:xml:ns:xmpp-bind" .

## 绑定过程

### 1. 验证通过

服务端在SASL协议成功，发送了响应的stream头之后，必需紧接着发送一个由`'urn:ietf:params:xml:ns:xmpp-bind'`标识的`<bind/>`元素。

	S: <stream:stream
       from='im.example.com'
       id='gPybzaOzBmaADgxKXu9UClbprp0='
       to='juliet@im.example.com'
       version='1.0'
       xml:lang='en'
       xmlns='jabber:client'
       xmlns:stream='http://etherx.jabber.org/streams'>

	S: <stream:features>
	     <bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'/>
	   </stream:features>
	  
### 2. 生成resource标识

一个资源标识至少在同一个Bare JID的所有resource标识中是唯一的，这一点需要由服务端来负责。

#### 2.1 服务端生成resource标志

客户端通过发送一个包含空的`<bind/>`元素，类型为的`set`的`IQ`来请求服务端生成resource标志。

	C: <iq id='tn281v37' type='set'>
	    <bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'/>
	   </iq>

服务端生成后发送响应给客户端：

	S: <iq id='tn281v37' type='result'>
	    <bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'>
	      <jid>
	        juliet@im.example.com/4db06f06-1ea4-11dc-aca3-000bcd821bfb
	      </jid>
	    </bind>
	   </iq>
	   
**失败情况:**

1. 一个Bare JID下已经达到了同时在线的上限；
2. 客户端不被允许绑定资源

#### 2.2 客户端设置resource标志

客户端也可以自己设置resource。

客户端通过发送一个包含`<bind/>`元素，类型为的`set`的`IQ`来请求服务端生成resource标志。`<bind/>`元素包含一个子元素`<resource/>`。`<resource/>`元素包含长度非零的字符串。

	C: <iq id='wy2xa82b4' type='set'>
	     <bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'>
	       <resource>balcony</resource>
	     </bind>
	   </iq>
	   
服务端应该接受客户端提交的resource标志。服务端通过`IQ`返回一个`<bind/>`元素，其中包含了一个`<jid>`元素，`<jid>`元素中包含一个Full JID，其中的resource是客户端提交的resource标志。

	S: <iq id='wy2xa82b4' type='result'>
	    <bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'>
	      <jid>juliet@im.example.com/balcony</jid>
	    </bind>
	   </iq>

服务端有可能会拒绝客户端提供的resource标志，而使用服务端生成的resource标志。

**失败情况:**

1. 提交的标志包含非法字符,地址格式可以在这里查到: [Address Format](http://tools.ietf.org/html/rfc6122)
2. 提交的标志已经被占用

#### 2.2.1 resource标志冲突

当客户端提供的resource标志冲突时，服务端应该遵循以下三个策略之一：

1. 重新生成新连接提交的resource标志,使新连接能够继续；
2. 拒绝新的连接，并维持现有的连接；
3. 断开现有的连接，并尝试绑定新的连接；

如果是第一种情况，服务端返回重新生成的resource标志：

	S: <iq id='wy2xa82b4' type='result'>
	    <bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'>
	      <jid>
	   juliet@im.example.com/balcony 4db06f06-1ea4-11dc-aca3-000bcd821bfb
	      </jid>
	    </bind>
	   </iq>

如果是第二种情况，服务端向**新连接**返回一个`<conflict/>`流错误：

	S: <iq id='wy2xa82b4' type='error'>
	     <error type='modify'>
	       <conflict xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
	     </error>
	   </iq>

如果是第三种情况，服务端向**已连接的客户端**发送`<conflict/>`流错误，关闭**已连接的客户端**的流，然后向新的连接发送绑定的结果：

	S: <iq id='wy2xa82b4' type='result'>
	     <bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'>
	       <jid>
	         juliet@im.example.com/balcony
	       </jid>
	     </bind>
	   </iq>
	   

## 应用：强制下线

类似QQ，不同设备上最多只能有一个账户在线，例如一个账号不能在两个iPhone上同时在线，在第二台上登录，就要把第一台踢下线，但是，又允许桌面或web上登录相同的账号。像这样的需求，可以通过resource标志来实现。

假定策略如下：一个账号最多只能在相同系统的设备上有一处登录，例如，用户在一台iPhone上登录，如果又在另外一台设备上登录，那就把第一台踢下线，但是可以允许有一个Android设备登录相同的账号。

实现： 在iOS版本中，登录时，客户端提交自定义的resource标志: iOS，同样，Android版本中，提交自定义的resource标志: Android。这样就可以限制相同系统只能有一处登录了。

假如要求一个账号只能在一个移动设备上登录，实现的时候，则需要iOS和Android使用相同的resource标志，例如: Mobile.

需要特别说明的是，当旧的连接被踢下线后，服务端向客户端发送`<conflict/>`流错误,并关闭流。客户端需要正确的处理这种情况下的应用逻辑。


### Openfire配置冲突解决策略

在管理器的的  服务器>服务器管理器>系统属性 中设置属性`xmpp.session.conflict-limit`的值。

Openfire相关的源码如下，可以根据需要配置对应的属性值:

		  String username = authToken.getUsername().toLowerCase();
          // If a session already exists with the requested JID, then check to see
          // if we should kick it off or refuse the new connection
          ClientSession oldSession = routingTable.getClientRoute(new JID(username, serverName, resource, true));
          if (oldSession != null) {
              try {
                  int conflictLimit = sessionManager.getConflictKickLimit();
                  if (conflictLimit == SessionManager.NEVER_KICK) {
                      reply.setChildElement(packet.getChildElement().createCopy());
                      reply.setError(PacketError.Condition.conflict);
                      // Send the error directly since a route does not exist at this point.
                      session.process(reply);
                      return null;
                  }

                  int conflictCount = oldSession.incrementConflictCount();
                  if (conflictCount > conflictLimit) {
                      // Kick out the old connection that is conflicting with the new one
                      StreamError error = new StreamError(StreamError.Condition.conflict);
                      oldSession.deliverRawText(error.toXML());
                      oldSession.close();
                  }
                  else {
                      reply.setChildElement(packet.getChildElement().createCopy());
                      reply.setError(PacketError.Condition.conflict);
                      // Send the error directly since a route does not exist at this point.
                      session.process(reply);
                      return null;
                  }
              }
              catch (Exception e) {
                  Log.error("Error during login", e);
              }
          }

1. xmpp.session.conflict-limit == -1 :向新连接发送资源绑定冲突的流错误；
2. xmpp.session.conflict-limit <= 1 && != -1 : 向旧连接发送资源绑定冲突的流错误，并且关闭旧的连接(会话)；
3. xmpp.session.conflict-limit > 1: 向新连接发送资源绑定冲突的流错误；


ps: 修改完需要重启openfire。

### XMPPFramework处理

#### 自定义resource

设置`XMPPStream`类的实例变量`myJID`,附带自定义的resource即可。

	    XMPPJID *myJID = [XMPPJID jidWithString:[NSString stringWithFormat:@"%@@%@/%@",user,XMPP_SERVER_ACCOUNT_HOSTNAME,@"xmpp"]];
		[self.xmppStream setMyJID:myJID];

#### 处理冲突

在`XMPPStreamDelegate`的回调方法中处理资源绑定冲突产生的流错误：

	- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
	{
	    
	    NSXMLElement *element = (NSXMLElement*) error;
	    NSString *elementName = [element name];
	    
	    //<stream:error xmlns:stream="http://etherx.jabber.org/streams">
	    //  <conflict xmlns="urn:ietf:params:xml:ns:xmpp-streams"/>
	    //</stream:error>
	
		if ([elementName isEqualToString:@"stream:error"] || [elementName isEqualToString:@"error"])
		{
			NSXMLElement *conflict = [element elementForName:@"conflict" xmlns:@"urn:ietf:params:xml:ns:xmpp-streams"];
			if (conflict)
			{
				
			}
		}
	}

### TODO: Smack处理

## 文档

1. [Extensible Messaging and Presence Protocol (XMPP): Core](http://xmpp.org/rfcs/rfc6120.html#bind)