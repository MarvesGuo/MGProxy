//
//  BBURLProtocol.m
//  pregnancy
//
//  Created by 虔灵 on 2017/4/7.
//  Copyright © 2017年 babytree. All rights reserved.
//

#import "BBURLProtocol.h"
#import "BBURLCacheManager.h"
#import "BBURLCache.h"
#import "Reachability.h"

#define  BB_URL_PROTOCOL_HANDLE_KEY @"BBProtocolHandledKey"


@interface BBURLProtocol ()
<
NSURLConnectionDelegate
>
@property (nonatomic, strong) NSURLConnection *s_connection;
@property (nonatomic, strong) BBURLCache *s_cache;

@end


@implementation BBURLProtocol


// 如果URL需要处理则返回YES， 返回NO不需要处理
+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    BOOL isLegalScheme,isLegalHost,hasHandled;

    isLegalScheme = [request.URL.scheme caseInsensitiveCompare:@"http"] == NSOrderedSame || [request.URL.scheme caseInsensitiveCompare:@"https"] == NSOrderedSame;
    isLegalHost = [[BBURLCacheManager  whitelist] containsObject:request.URL.host.lowercaseString];
    
    
    //FIXME: 虔灵 DEBUG  all cache
    isLegalHost = YES;
    
    
    //看看是否已经处理过了，防止无限循环
    hasHandled = [NSURLProtocol propertyForKey:BB_URL_PROTOCOL_HANDLE_KEY inRequest:request] != nil;
    
    if (isLegalScheme && isLegalHost && !hasHandled)
    {
        return YES;
    }
    else
    {
#ifdef DEBUG
        return [self isLegalKnowledgeHost4Debug:request.URL.host.lowercaseString] && !hasHandled;
#endif
        return NO;
    }
}

// 重写方法修改Request的参数
+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *)request {
    // 是否缓存命中
    NSURLResponse *cachedResponse = [BBURLCacheManager cachedResponseWithURLString:request.URL.absoluteString];
    if (cachedResponse)
    {
        // 命中 新鲜度有效期检测
        // 拼接Header IMS、Etag 等标签
        // 1、IMS
        request = [BBURLCacheManager insertIMSHeaderValueWithCachedResponse:cachedResponse toRequest:request];
        // 2、ETag
        request = [BBURLCacheManager insertETagHeaderValueWithCachedResponse:cachedResponse toRequest:request];
        
        return request;
    }
    else
    {
        // 没缓存正常走
        return request;
    }
}


- (void)startLoading
{
    //标示改request已经处理过了，防止无限循环
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:BB_URL_PROTOCOL_HANDLE_KEY inRequest:mutableReqeust];
    
    
    if ([[Reachability reachabilityWithHostName:mutableReqeust.URL.host] currentReachabilityStatus] != NotReachable)
    {
        //有网  直接发送， 命中新鲜度检测都应经在 canonicalRequestForRequest里处理了。
        self.s_connection = [NSURLConnection connectionWithRequest:mutableReqeust delegate:self];
        [self.s_connection start];
    }
    else
    {
        BBURLCache *cache = [BBURLCacheManager cacheWithURLString:self.request.URL.absoluteString];
        //无网
        if (cache)
        {
            // 缓存命中  不用maxAge做新鲜度检测了
            [self.client URLProtocol:self didReceiveResponse:cache.m_response cacheStoragePolicy:NSURLCacheStorageAllowed];
            [[self client] URLProtocol:self didLoadData:cache.m_httpBodyData];
            [self.client URLProtocolDidFinishLoading:self];
        }
        else
        {
            //发送请求
            self.s_connection = [NSURLConnection connectionWithRequest:mutableReqeust delegate:self];
            [self.s_connection start];
        }
    }
}

- (void)stopLoading
{
    [self.s_connection cancel];
}


- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {

    if ([self.s_cache.m_response isKindOfClass:[NSHTTPURLResponse class]])
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;

        if (httpResponse.statusCode == 200)
        {
            // SUCCESS & NEED MODIFY CACHE  正常走 去Save  若是Modify会在Save方法处理
        }
        else if (httpResponse.statusCode == 304)
        {
            // 缓存可用，直接返回
            BBURLCache *cache = [BBURLCacheManager cacheWithURLString:self.request.URL.absoluteString];
            [self.client URLProtocol:self didReceiveResponse:cache.m_response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
            [[self client] URLProtocol:self didLoadData:cache.m_httpBodyData];
            [self.client URLProtocolDidFinishLoading:self];

            return;
        }
        else if (httpResponse.statusCode == 404)
        {
            // 404 删除本地缓存  正常走
            if ([BBURLCacheManager cacheWithURLString:self.request.URL.absoluteString])
            {
                [BBURLCacheManager deleteCacheWithURLString:self.request.URL.absoluteString];
            }
        }
        else
        {
            // OTHER CODE  正常走
        }
    }
    
    self.s_cache.m_response = response;
    self.s_cache.m_URLString = self.request.URL.absoluteString;
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // 走到这了一定是要更新缓存
    [self.s_cache.m_httpBodyData appendData:data];
    [self.client URLProtocol:self didLoadData:data];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {

    if ([self.s_cache.m_response isKindOfClass:[NSHTTPURLResponse class]])
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)self.s_cache.m_response;
        if (httpResponse.statusCode == 200)
        {
            // 第一次 以及后期 update 都是200，其他不存储
            [BBURLCacheManager saveCache:self.s_cache];
        }
    }
    
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}

#pragma mark - getter/setter methods

- (BBURLCache *)s_cache
{
    if (!_s_cache) {
        _s_cache = [[BBURLCache alloc]init];
    }
    return _s_cache;
}


#pragma mark - utils methods

+(BOOL)isLegalKnowledgeHost4Debug:(NSString *)host
{
    // 配测试环境
    __block BOOL isLegal = YES;
    
    NSArray *hostSubArray = [host componentsSeparatedByString:@"."];
    [hostSubArray enumerateObjectsUsingBlock:^(NSString * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == 0)
        {
            if (![obj containsString:@"knowledge"])
            {
                isLegal = NO;
                *stop = YES;
            }
        }
        else if (idx == 1)
        {
            if (![obj containsString:@"babytree"])
            {
                isLegal = NO;
                *stop = YES;
            }
        }
        else
        {
            // do nothing
        }
    }];
    
    return isLegal;
}

@end
