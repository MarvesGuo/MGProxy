//
//  BBURLCache.m
//  pregnancy
//
//  Created by 虔灵 on 2017/4/7.
//  Copyright © 2017年 babytree. All rights reserved.
//

#import "BBURLCache.h"

@implementation BBURLCache


- (NSMutableData *)m_httpBodyData
{
    if (!_m_httpBodyData)
    {
        _m_httpBodyData = [[NSMutableData alloc]init];
    }
    return _m_httpBodyData;
}

@end
