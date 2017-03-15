# MGProxy
客户端Proxy，可用于缓存webView，加密、实效、预加载，符合标准HTTP协议

## HTTP协议相关 


## HTTP基础 Header
确定HTTP协议版本 0.9。1.0。1.0+ 1.1  NG

只处理GET

* 代理
* 缓存。  副本服务器，不能单单只考虑资源
* 网关。 连接其他应用程序的特殊web服务器
* 隧道 对message进行盲转发的特殊代理
* Agent代理  发起自动Http 请求的半智能Web客户端 （预加载）

报文三部分组成
start line
header
body

两类  request、response


## Delegate代理
xxxx
xxxx

## Cache部分
缓存

缓存命中  （有缓存）
缓存未命中

Http再次验证。 特殊请求，不获取整个对象，快速检测是否最新。 
没有改变，服务端小的 304 Not Modified 做回应。

返回状态码
* 缓存命中  返回 304 
* 缓存未命中  返回 200  OK
* 缓存删除    返回  404 

缓存处理的步骤
* 接受
    * 考虑并行处理
* 解析
    * 将缓存头部放入数据结构中，方便统一操作
* 查询
    * 快速算法来确定是否有缓存。  也会缓存原始请求的的头部，还有一些元数据来标记停留了多长时间，访问了多少次
* 新鲜度检测
    * 是否隔一段时间？
* 创建响应
    * 插入新鲜度信息
        * Cache-Control
        * Age
        * Expires
        * Via 标示是代理缓存
        * 注： 不修改Date
* 发送
* 日志
    * 相关的数据统计

条件GET
* If-Modified-Since：Date再验证   IMS请求
* If-None-Match   标签来验证  Etag：v。6

控制缓存能力
* Cache-Control：no-store    不使用缓存
* Cache-Control：no-cache。   每次都向服务器验证
* Cache-Control：must-revalidate    必须验证
* Cache-Control：max-age        最大时效。（s-maxage）
* Expires

Tips：
* 通过Date判断事都来自缓存，缓存肯定是时间早的
* 客户端缓存 一级就够了 不用考虑时常问题 网状缓存也不用
* 再次验证如果文档没有更新，只需要替换Header部分，content部分不用替换。
* 再次验证服务器出了故障， 需要返回错误的提示



