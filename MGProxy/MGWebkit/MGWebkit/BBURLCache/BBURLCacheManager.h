//
//  BBURLCacheManager.h
//  pregnancy
//
//  Created by 虔灵 on 2017/4/7.
//  Copyright © 2017年 babytree. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BBURLCache.h"

@interface BBURLCacheManager : NSObject


/*
 *  这个类主要负责对BBURLCache数据Model的存储，清理，以及三个工具方法。 数据处理分两部分存储，1、Response 小数据存储在DB里，大数据HttpBody存储文件（SQL存储大文件读取速度不如直接文件读写 >16-20KB，Response读取较频繁，Data读一次就好）
 *  本来打算设计Body小于20KB存库的，但感觉一个Body存储两个地方不方便
 */



+ (BBURLCacheManager *)sharedManager;

/*
 *  这两个方法快速查询，和CDN校验缓存有效期只需要用到Response
 */
+ (NSURLResponse *)cachedResponseWithURLString:(NSString *)URLString;
+ (NSData *)cachedHttpBodyWithURLString:(NSString *)URLString;

/*
 *  这两个对应的存取方法都是Response+HttpBody
 */
+ (BBURLCache *)cacheWithURLString:(NSString *)URLString;
+ (void)saveCache:(BBURLCache *)cache;

+ (void)deleteCacheWithURLString:(NSString *)URLString;


//工具方法
+ (NSSet *)whitelist;      //白名单 要处理的Host
+ (NSURLRequest *)insertIMSHeaderValueWithCachedResponse:(NSURLResponse *)response toRequest:(NSURLRequest *)orginRequest;    // If-modify-since
+ (NSURLRequest *)insertETagHeaderValueWithCachedResponse:(NSURLResponse *)response toRequest:(NSURLRequest *)orginRequest;   //


@end
