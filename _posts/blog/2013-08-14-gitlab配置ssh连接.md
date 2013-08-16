---
layout: post
title: Gitlab配置ssh连接
categories: blog
tags: git gitlab ssh
---


## ssh公钥登录

一般在管理远程主机时，都用ssh登录，`ssh user@host`，但是这样每次会使用密码。 使用`ssh-keygen`生成的密钥对，然后将公钥添加的目标主机的`~/.ssh/authorized_keys`文件中，当前主机就成为可信任的主机，下次使用ssh登录时，就不用输入密码了。

Gitlab，Github都支持这种方式的连接，具体操作步骤如下：

####第一步:生成密钥对
使用`ssh-keygen`生成密钥对:

	ssh-keygen -t rsa -C "你的邮箱"

这样就在主目录下的`.ssh`目录中生成了两个文件`id_rsa`和`id_rsa.pub`。`id_rsa`中保存的是私钥，`id_rsa.pub`中保存的是公钥。

####第二步:添加公钥

拷贝公钥到剪切板:

	pbcopy < id_rsa.pub
	
在 个人资料->SSH Keys->Add new 页面中粘贴公钥，就添加完成了。

####第三步:测试

ssh加`-T`选项测试目标服务是否可用:

	ssh -T git@"你的gitlab服务器地址"
	
第一次连接时，会询问是否信任主机，确认后输入yes。如果看到`Welcome to GitLab, Rusher!`就算配置成功了，接下来就可以通过ssh来提交代码了。

>   **Windows** 
>   
>   1. 下载 [Git-Bash](https://code.google.com/p/msysgit/downloads/detail?name=Git-1.8.3-preview20130601.exe&can=2&q=full+installer+official+git )
>   2. 生成密钥对`ssh-keygen -t rsa -C "你的邮箱"`
>   3. 生成之后用 `notepad c:/User/Administrator/.ssh/id_rsa.pub` 打开文件，然后将公钥添加的Gitlab中.
>   4. 测试 `ssh -T git@"你的gitlab服务器地址"`

##Gitlab服务端配置

(只使用客户端可忽略这节内容)

在客户端提交时发现以下错误：

	/usr/local/lib/ruby/1.9.1/net/http.rb:762:in `initialize': getaddrinfo: Name or service not known (SocketError)
	from /usr/local/lib/ruby/1.9.1/net/http.rb:762:in `open'
	from /usr/local/lib/ruby/1.9.1/net/http.rb:762:in `block in connect'
	from /usr/local/lib/ruby/1.9.1/timeout.rb:54:in `timeout'
	from /usr/local/lib/ruby/1.9.1/timeout.rb:99:in `timeout'
	from /usr/local/lib/ruby/1.9.1/net/http.rb:762:in `connect'
	from /usr/local/lib/ruby/1.9.1/net/http.rb:755:in `do_start'
	from /usr/local/lib/ruby/1.9.1/net/http.rb:744:in `start'
	from /home/git/gitlab-shell/lib/gitlab_net.rb:64:in `get'
	from /home/git/gitlab-shell/lib/gitlab_net.rb:30:in `check'
	from ./check:11:in `<main>'
	

在Github的issue里找到说先运行一下`/home/git/gitlab-shell/bin/check` 。先做检测，发现和上面一样的错误。看错误是找不到域名，所以在`/etc/hosts`中需要配置一个地址的映射。

	127.0.0.1  YOUR_DOMIN # YOUR_DOMIN是在/home/git/gitlab-shell/config.yml中配置的gitlab_url
	
##扩展：ssh多用户切换

在配置Gitlab的时候一开始是用管理员账户做测试的，后来建了我自己的账号做开发。这样我的本地就有两个Gitlab账号，如果直接用ssh来提交代码有问题，因为ssh默认使用一开始生成id_rsa那个密钥对，但不同的账号又不能对应到同一个公钥上。如果多个账户一起用，还需要做些配置。

假如有两个账号：root和rusher。

####第一步:为两个账户分别生成密钥对

提示在哪里存储密钥文件的时候，对不同的账号填不同的路径，root放在`/Users/you/.ssh/id_rsa_gitlab_root`下，rusher的放在`/Users/you/.ssh/id_rsa_gitlab_rusher`

	ssh-keygen -t rsa -C rusher@you.com
	
	Generating public/private rsa key pair.
	Enter file in which to save the key (/Users/you/.ssh/id_rsa): /Users/you/.ssh/id_rsa_gitlab_rusher
	Enter passphrase (empty for no passphrase): 
	Enter same passphrase again: 
	Your identification has been saved in /Users/you/.ssh/id_rsa_gitlab_rusher.
	Your public key has been saved in /Users/you/.ssh/id_rsa_gitlab_rusher.pub.


	ssh-keygen -t rsa -C root@you.com
	
	Generating public/private rsa key pair.
	Enter file in which to save the key (/Users/you/.ssh/id_rsa): /Users/you/.ssh/id_rsa_gitlab_root
	Enter passphrase (empty for no passphrase): 
	Enter same passphrase again: 
	Your identification has been saved in /Users/you/.ssh/id_rsa_gitlab_root.
	Your public key has been saved in /Users/you/.ssh/id_rsa_gitlab_root.pub.
	
还是需要将两个账号的公钥分别添加的各自账号的SSH Keys中(rusher: id_rsa_gitlab_rusher.pub和root: id_rsa_gitlab_root.pub) 。

    ssh-add /Users/you/.ssh/id_rsa_gitlab_rusher

	ssh-add /Users/you/.ssh/id_rsa_gitlab_root

####第二步:添加ssh配置文件

在.ssh目录中添加`config`文件，此文件的为不同的账户添加别名(root: root_gitlab 和 rusher: rusher_gitlab)，连接还是同一个服务器，但是使用不同的密钥文件，所以才能将两个账号分开。

	# for root 
	Host root_gitlab
	  HostName git.you.com
	  User git
	  IdentityFile /Users/you/.ssh/id_rsa_gitlab
	
	# for rusher
	Host rusher_gitlab
	  HostName git.you.com
	  User git
	  IdentityFile /Users/you/.ssh/id_rsa_gitlab_rusher

配置完成后，使用`ssh-add`命令

接下来这样使用别名测试，可以查看是否对应到了正确的账号上：

	ssh -T git@root_gitlab 
	
	ssh -T git@rusher_gitlab

####第三步:在git项目中使用别名

正常的项目，我们clone下来之后，origin对应的URL假设为: `git@git.:Rusher/helloworld`，现在需要做个改动，将`git.`要换成`rusher_gitlab`,
	
	git remote set-url origin git@rusher_gitlab:Rusher/helloworld
	
如果是root用户的项目:

	git remote set-url origin git@root_gitlab:root/helloworld
	
	
	
以上配置ssh的方法同样适用于Github,Bitbucket等网站。

## 参考文档

* [Github Help](https://help.github.com/articles/generating-ssh-keys)

UPDATE 2013-08-16: 为不同账号生成密钥对后，需要使用ssh-add将密钥添加进来，否则ssh不能使用正确的密钥

