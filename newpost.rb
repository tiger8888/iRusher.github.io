#!/usr/bin/env ruby

unless ARGV[0]
  puts 'Usage: newpost "the post title" catagory'
  exit(-1)
end

date_prefix = Time.now.strftime("%Y-%m-%d")
postname = ARGV[0].strip.downcase.gsub(/ /, '-')
post = "./_posts/"+ARGV[1]+"/#{date_prefix}-#{postname}.md"

header = <<-END
---
layout: post
title: #{ARGV[0]}
categories: blog
tags:
---

END

File.open(post, 'w') do |f|
  f << header
end

system("open", post)
