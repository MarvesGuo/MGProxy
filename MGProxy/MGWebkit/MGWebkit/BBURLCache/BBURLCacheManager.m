//
//  BBURLCacheManager.m
//  pregnancy
//
//  Created by 虔灵 on 2017/4/7.
//  Copyright © 2017年 babytree. All rights reserved.
//

#import "BBURLCacheManager.h"
#import <CommonCrypto/CommonDigest.h>
#import "YYCache.h"
#import "YYDiskCache.h"
#import "YYKVStorage.h"



#define BB_URL_CACHE_MANAGER_SAVE_PATH @"KnowledgeURLCache"

#define BB_URL_CACHE_MANAGER_RESPONSE_KEY( URLString ) [NSString stringWithFormat:@"%@_response",[self md5StringWithOrginString:URLString]]
#define BB_URL_CACHE_MANAGER_HTTPBODY_KEY( URLString ) [self md5StringWithOrginString:URLString]

#define BB_URL_CACHE_MANAGER_RESPONSE_CACHE_LIMIT (20 * 1024 * 1024)    //20M
#define BB_URL_CACHE_MANAGER_HTTPBODY_CACHE_LIMIT (200 * 1024 * 1024)   //200M


@interface BBURLCacheManager ()

@property (nonatomic, strong) NSSet *s_whitelistSet;
@property (nonatomic, strong) NSMutableArray *s_cacheArray;


@property (nonatomic, strong) YYDiskCache *s_httpResponseCacheManager;  //存储Response    存DB
@property (nonatomic, strong) YYDiskCache *s_httpBodyCacheManager;      //存储HttpBody    存文件


- (NSURLResponse *)s_cachedResponseWithURLString:(NSString *)URLString;
- (NSData *)s_cachedHttpBodyWithURLString:(NSString *)URLString;

- (BBURLCache *)s_cacheWithURLString:(NSString *)URLString;
- (void)s_saveCache:(BBURLCache *)cache;
- (void)s_deleteCacheWithURLString:(NSString *)URLString;


- (NSSet *)s_whitelist;

@end



static BBURLCacheManager *sharedCacheManager;


@implementation BBURLCacheManager

#pragma mark - life cycle

+ (BBURLCacheManager *)sharedManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCacheManager = [[self alloc] init];
        [sharedCacheManager s_initData];
    });
    return sharedCacheManager;
}


#pragma mark - public methods
+(NSSet *)whitelist
{
    return [[self sharedManager] s_whitelist];
}

+ (NSURLRequest *)insertIMSHeaderValueWithCachedResponse:(NSURLResponse *)response toRequest:(NSURLRequest *)orginRequest
{
    if ([response isKindOfClass:[NSHTTPURLResponse class]])
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if ([[httpResponse.allHeaderFields allKeys] containsObject:@"Last-Modified"])
        {
            NSMutableURLRequest *mutableReqeust = [orginRequest mutableCopy];
            [mutableReqeust addValue:[httpResponse.allHeaderFields objectForKey:@"Last-Modified"] forHTTPHeaderField:@"If-Modified-Since"];
            return [mutableReqeust copy];
        }
    }
    return orginRequest;
}

+ (NSURLRequest *)insertETagHeaderValueWithCachedResponse:(NSURLResponse *)response toRequest:(NSURLRequest *)orginRequest
{
    if ([response isKindOfClass:[NSHTTPURLResponse class]])
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if ([[httpResponse.allHeaderFields allKeys] containsObject:@"Etag"])
        {
            NSMutableURLRequest *mutableReqeust = [orginRequest mutableCopy];
            [mutableReqeust addValue:[httpResponse.allHeaderFields objectForKey:@"Etag"] forHTTPHeaderField:@"If-None-Match"];

            return [mutableReqeust copy];
        }
    }
    return orginRequest;
}


+ (NSURLResponse *)cachedResponseWithURLString:(NSString *)URLString
{
    return [[self sharedManager]s_cachedResponseWithURLString:URLString];
}


+ (NSData *)cachedHttpBodyWithURLString:(NSString *)URLString
{
    return [[self sharedManager]s_cachedHttpBodyWithURLString:URLString];
}


+ (BBURLCache *)cacheWithURLString:(NSString *)URLString
{
    return [[self sharedManager] s_cacheWithURLString:URLString];
}

+ (void)saveCache:(BBURLCache *)cache
{
    [[self sharedManager] s_saveCache:cache];
}

+ (void)deleteCacheWithURLString:(NSString *)URLString
{
    [[self sharedManager] s_deleteCacheWithURLString:URLString];
}

#pragma mark - private methods

- (void)s_initData
{
    // whitelist
    NSArray *whitelistArray = [NSArray arrayWithContentsOfURL:[[NSBundle mainBundle]URLForResource:@"BBURLCacheWhitelist" withExtension:@"plist"]];
    self.s_whitelistSet = [NSSet setWithArray:whitelistArray];
}


- (NSSet *)s_whitelist
{
    return self.s_whitelistSet;
}


#pragma mark -- 存取相关

- (NSURLResponse *)s_cachedResponseWithURLString:(NSString *)URLString
{
    NSURLResponse *response = [self.s_httpResponseCacheManager objectForKey:BB_URL_CACHE_MANAGER_RESPONSE_KEY(URLString)];
    
    BOOL hasHttpBody = [self.s_httpBodyCacheManager containsObjectForKey:BB_URL_CACHE_MANAGER_HTTPBODY_KEY(URLString)];

    if (response && hasHttpBody)
    {
        return response;
    }
    else
    {
        if (response)
        {
            //有Response 无Body
            [self.s_httpResponseCacheManager removeObjectForKey:BB_URL_CACHE_MANAGER_RESPONSE_KEY(URLString)];
            return nil;
        }
        else
        {
            //无Response 有Body
            [self.s_httpBodyCacheManager removeObjectForKey:BB_URL_CACHE_MANAGER_HTTPBODY_KEY(URLString)];
            return nil;
        }
    }
}

- (NSData *)s_cachedHttpBodyWithURLString:(NSString *)URLString
{
    return  [self.s_httpBodyCacheManager objectForKey:BB_URL_CACHE_MANAGER_HTTPBODY_KEY(URLString)];
}


- (BBURLCache *)s_cacheWithURLString:(NSString *)URLString
{
    BBURLCache *cache = [BBURLCache new];
    cache.m_response = [self s_cachedResponseWithURLString:URLString];
    cache.m_httpBodyData = [self s_cachedHttpBodyWithURLString:URLString];
    
    if (cache.m_response && cache.m_httpBodyData)
    {
        return cache;
    }
    else
    {
        return nil;
    }
}


- (void)s_saveCache:(BBURLCache *)cache
{
    [self.s_httpResponseCacheManager setObject:cache.m_response forKey:BB_URL_CACHE_MANAGER_RESPONSE_KEY(cache.m_URLString)];
    
    [self.s_httpBodyCacheManager setObject:cache.m_httpBodyData forKey:BB_URL_CACHE_MANAGER_HTTPBODY_KEY(cache.m_URLString)];
}


- (void)s_deleteCacheWithURLString:(NSString *)URLString
{
    //1、 删除Response
    [self.s_httpResponseCacheManager removeObjectForKey:BB_URL_CACHE_MANAGER_RESPONSE_KEY(URLString)];
    //2、 删除Data
    [self.s_httpBodyCacheManager removeObjectForKey:BB_URL_CACHE_MANAGER_HTTPBODY_KEY(URLString)];
}
#pragma mark - getter/setter methods

- (NSMutableArray *)s_cacheArray
{
    if (!_s_cacheArray)
    {
        _s_cacheArray = [NSMutableArray array];
    }
    return _s_cacheArray;
}


- (YYKVStorage *)s_httpResponseCacheManager
{
    if (!_s_httpResponseCacheManager)
    {
        [self createSaveDir];
        
        _s_httpResponseCacheManager = [[YYDiskCache alloc]initWithPath:[self savePath] inlineThreshold:NSUIntegerMax];
        _s_httpResponseCacheManager.costLimit = BB_URL_CACHE_MANAGER_RESPONSE_CACHE_LIMIT;
    }
    return _s_httpResponseCacheManager;
}


- (YYDiskCache *)s_httpBodyCacheManager
{
    if (!_s_httpBodyCacheManager)
    {
        [self createSaveDir];
        
        _s_httpBodyCacheManager = [[YYDiskCache alloc]initWithPath:[self savePath] inlineThreshold:0];
        _s_httpBodyCacheManager.costLimit = BB_URL_CACHE_MANAGER_HTTPBODY_CACHE_LIMIT;
    }
    return _s_httpBodyCacheManager;
}


#pragma mark utils methdos

- (NSString *)md5StringWithOrginString:(NSString *)orginString
{
    if ([orginString length] == 0)
    {
        return nil;
    }
    unsigned char digest[CC_MD5_DIGEST_LENGTH], i;
    CC_MD5([orginString UTF8String], (int)[orginString lengthOfBytesUsingEncoding:NSUTF8StringEncoding], digest);
    NSMutableString *tempString = [NSMutableString string];
    
    for (i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [tempString appendFormat:@"%02x", (int)(digest[i])];
    }
    return [tempString copy];
}


- (NSString *)savePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [paths firstObject];
    NSString *sourcePath = [cacheDirectory stringByAppendingPathComponent:@"KnowledgeURLCache"];
    
    return sourcePath;
}

- (void)createSaveDir
{
    // 判断文件夹是否存在
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = FALSE;
    BOOL isDirExist = [fileManager fileExistsAtPath:[self savePath] isDirectory:&isDir];
    if(!(isDirExist && isDir))
    {
        BOOL success = [fileManager createDirectoryAtPath:[self savePath] withIntermediateDirectories:YES attributes:nil error:nil];
        if(!success)
        {
            //NSLog(@"创建文件夹失败！");
        }
        else
        {
            //NSLog(@"创建文件夹成功，文件路径%@",path);
        }
    }
}

@end
