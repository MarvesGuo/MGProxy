//
//  BBURLCache.h
//  pregnancy
//
//  Created by 虔灵 on 2017/4/7.
//  Copyright © 2017年 babytree. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BBURLCache : NSObject

@property (nonatomic, strong) NSMutableData * m_httpBodyData;
@property (nonatomic, strong) NSURLResponse * m_response;

@property (nonatomic, strong) NSString      * m_URLString;


@end
