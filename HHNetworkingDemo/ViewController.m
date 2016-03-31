//
//  ViewController.m
//  HHNetworkingDemo
//
//  Created by 韩继宏 on 16/3/30.
//  Copyright © 2016年 韩 继宏. All rights reserved.
//

#import "ViewController.h"
#import "HHNetworking.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [HHNetworking updateBaseUrl:@"http://apistore.baidu.com"];
    [HHNetworking enableInterfaceDebug:YES];
    
    // 测试GET
    NSString *url = @"http://apistore.baidu.com/microservice/cityinfo?cityname=beijing";
    [HHNetworking getWithUrl:url params:nil progress:^(ino64_t bytesRead, ino64_t totalBytesRead) {
        NSLog(@"progress: %f, cur: %lld, total: %lld",
              (bytesRead * 1.0) / totalBytesRead,
              bytesRead,
              totalBytesRead);
    } success:^(id response) {
        
    } fail:^(NSError *error) {
        
    }];
}

@end
