//
//  HHNetworking.m
//  HHNetworkingDemo
//
//  Created by 韩继宏 on 16/3/30.
//  Copyright © 2016年 韩 继宏. All rights reserved.
//

#import "HHNetworking.h"
#import <AFNetworking.h>
#import <AFHTTPSessionManager.h>
#import <AFNetworkActivityIndicatorManager.h>

// 项目打包上线时不会打印日志
#ifdef DEBUG
#define HHLog(s, ... ) NSLog( @"[%@：in line: %d]-->%@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define HHLog(s, ... )
#endif

static NSString *hh_privateNetworkBaseUrl = nil;
static BOOL hh_isEnableInterfaceDebug = NO;
static BOOL hh_shouldAutoEncode = NO;
static NSDictionary *hh_httpHeaders = nil;
static HHResponseType hh_responseType = HHResponseTypeJSON;
static HHRequestType hh_requestType = HHRequestTypeJSON;

@implementation HHNetworking

+ (void)updateBaseUrl:(NSString *)baseUrl {
    hh_privateNetworkBaseUrl = baseUrl;
}

+ (NSString *)baseUrl {
    return hh_privateNetworkBaseUrl;
}

+ (void)enableInterfaceDebug:(BOOL)isDebug {
    hh_isEnableInterfaceDebug = isDebug;
}

+ (BOOL)isDebug {
    return hh_isEnableInterfaceDebug;
}

+ (void)configResponseType:(HHResponseType)responseType {
    hh_responseType = responseType;
}

+ (void)configRequest:(HHRequestType)requestType {
    hh_requestType = requestType;
}

+ (void)shouldAutoEncodeUrl:(BOOL)shouldAutoEncode {
    hh_shouldAutoEncode = shouldAutoEncode;
}

+ (BOOL)shouldEncode {
    return hh_shouldAutoEncode;
}

+ (void)configCommonHttpHeaders:(NSDictionary *)httpHeaders {
    hh_httpHeaders = httpHeaders;
}

#pragma mark - GET请求
+ (HHURLSessionTask *)getWithUrl:(NSString *)url success:(HHResponseSuccess)success fail:(HHResponseFail)fail {
    return [self getWithUrl:url params:nil success:success fail:fail];
}

+ (HHURLSessionTask *)getWithUrl:(NSString *)url params:(NSDictionary *)params success:(HHResponseSuccess)success fail:(HHResponseFail)fail {
    return [self getWithUrl:url params:params progress:nil success:success fail:fail];
}

+ (HHURLSessionTask *)getWithUrl:(NSString *)url params:(NSDictionary *)params progress:(HHGetProgress)progress success:(HHResponseSuccess)success fail:(HHResponseFail)fail {
    return [self _requestWithUrl:url httpMethod:1 params:params progress:progress success:success fail:fail];
}

#pragma mark - POST请求
+ (HHURLSessionTask *)postWithUrl:(NSString *)url params:(NSDictionary *)params success:(HHResponseSuccess)success fail:(HHResponseFail)fail {
    return [self postWithUrl:url params:params progress:nil success:success fail:fail];
}

+ (HHURLSessionTask *)postWithUrl:(NSString *)url params:(NSDictionary *)params progress:(HHGetProgress)progress success:(HHResponseSuccess)success fail:(HHResponseFail)fail {
    return [self _requestWithUrl:url httpMethod:2 params:params progress:progress success:success fail:fail];
}

#pragma mark - 文件上传
+ (HHURLSessionTask *)uploadFileWithUrl:(NSString *)url uploadingFile:(NSString *)uploadingFile progress:(NSString *)progress success:(HHResponseSuccess)success fail:(HHResponseFail)fail {
    if ([NSURL URLWithString:uploadingFile] == nil) {
        HHLog(@"uploadingFile无效，无法生成URL。请检查待上传文件是否存在");
        return nil;
    }
    
    NSURL *uploadURL = nil;
    if ([self baseUrl] == nil) {
        uploadURL = [NSURL URLWithString:url];
    } else {
        uploadURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseUrl], url]];
    }
    
    if (uploadURL == nil) {
        HHLog(@"URLString无效，无法生成URL。可能是URL中有中文或特殊字符，请尝试Encode URL");
        return nil;
    }
    
    if ([self shouldEncode]) {
        url = [self encodeUrl:url];
    }
    
    AFHTTPSessionManager *manager = [self manager];
    NSURLRequest *request = [NSURLRequest requestWithURL:uploadURL];
    HHURLSessionTask *session = [manager uploadTaskWithRequest:request fromFile:[NSURL URLWithString:uploadingFile] progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progress) {
            //TODO:进度提醒
        }
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        [self successResponse:responseObject callback:success];
        
        if (error) {
            if (fail) {
                fail(error);
            }
            if ([self isDebug]) {
                [self logWithFailError:error url:request.URL.absoluteString params:nil];
            }
        } else {
            if ([self isDebug]) {
                [self logWithSuccessResponse:responseObject url:response.URL.absoluteString params:nil];
            }
        }
    }];
    
    return session;
}

#pragma mark - 文件下载
+ (HHURLSessionTask *)downloadWithUrl:(NSString *)url saveToPath:(NSString *)saveToPath progress:(HHUploadProgress)progress success:(HHResponseSuccess)success fail:(HHResponseFail)fail {
    //TODO: 文件下载
    return nil;
}

#pragma mark - 图片上传
+ (HHURLSessionTask *)uploadWithImage:(UIImage *)image url:(NSString *)url filename:(NSString *)filename name:(NSString *)name mimeType:(NSString *)mimeType params:(NSDictionary *)params progress:(HHUploadProgress)progress success:(HHResponseSuccess)success fail:(HHResponseFail)fail {
    if ([self baseUrl] == nil) {
        if ([NSURL URLWithString:url] == nil) {
            HHLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    } else {
        if ([NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseUrl], url]] == nil) {
            HHLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    }
    
    if ([self shouldEncode]) {
        url = [self encodeUrl:url];
    }
    
    AFHTTPSessionManager *manager = [self manager];
    HHURLSessionTask *session = [manager POST:url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSData *imageData = UIImageJPEGRepresentation(image, 1);
        
        NSString *imageFileName = filename;
        if (filename == nil || ![filename isKindOfClass:[NSString class]] || filename.length == 0) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *str = [formatter stringFromDate:[NSDate date]];
            imageFileName = [NSString stringWithFormat:@"%@.jpg", str];
        }
        
        // 上传图片，以文件流的格式
        [formData appendPartWithFileData:imageData name:name fileName:imageFileName mimeType:mimeType];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progress) {
            progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self successResponse:responseObject callback:success];
        
        if ([self isDebug]) {
            [self logWithSuccessResponse:responseObject
                                     url:task.response.URL.absoluteString
                                  params:params];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (fail) {
            fail(error);
        }
        
        if ([self isDebug]) {
            [self logWithFailError:error url:task.response.URL.absoluteString params:nil];
        }
    }];
    
    return session;
}

#pragma mark - 数据请求（GET和POST）
+ (HHURLSessionTask *)_requestWithUrl:(NSString *)url
                            httpMethod:(NSUInteger)httpMethod
                               params:(NSDictionary *)params
                             progress:(HHDownloadProgress)progress
                              success:(HHResponseSuccess)success
                                 fail:(HHResponseFail)fail {
    AFHTTPSessionManager *manager = [self manager];
    
    if ([self baseUrl] == nil) {
        if ([NSURL URLWithString:url] == nil) {
            HHLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    } else {
        if ([NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseUrl], url]] == nil) {
            HHLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    }
    
    if ([self shouldEncode]) {
        url = [self encodeUrl:url];
    }
    
    HHURLSessionTask *session = nil;
    
    if (httpMethod == 1) {
        session = [manager GET:url parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
            if (progress) {
                progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
            }
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [self successResponse:responseObject callback:success];
            
            if ([self isDebug]) {
                [self logWithSuccessResponse:responseObject url:task.response.URL.absoluteString params:params];
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (fail) {
                fail(error);
            }
            if ([self isDebug]) {
                [self logWithFailError:error url:task.response.URL.absoluteString params:params];
            }
        }];
    } else if (httpMethod == 2) {
        session = [manager POST:url parameters:params progress:^(NSProgress * _Nonnull uploadProgress) {
            if (progress) {
                progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
            }
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [self successResponse:responseObject callback:success];
            if ([self isDebug]) {
                [self logWithSuccessResponse:responseObject url:task.response.URL.absoluteString params:params];
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (fail) {
                fail(error);
            }
            if ([self isDebug]) {
                [self logWithFailError:error url:task.response.URL.absoluteString params:params];
            }
        }];
    }
    
    return session;
}

+ (void)successResponse:(id)responseData callback:(HHResponseSuccess)success {
    if (success) {
        success([self tryToParseData:responseData]);
    }
}

#pragma mark - 解析JSON数据
+ (id)tryToParseData:(id)responseData {
    if ([responseData isKindOfClass:[NSData class]]) {
        // 尝试解析成JSON
        if (responseData == nil) {
            return responseData;
        } else {
            NSError *error = nil;
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
            if (error != nil) {
                return responseData;
            } else {
                return response;
            }
        }
    } else {
        return responseData;
    }
}

#pragma mark - Private
+ (AFHTTPSessionManager *)manager {
    // 开启转圈
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    AFHTTPSessionManager *manager = nil;
    if ([self baseUrl] != nil) {
        manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:[self baseUrl]]];
    } else {
        manager = [AFHTTPSessionManager manager];
    }
    
    switch (hh_requestType) {
        case HHRequestTypeJSON:
            manager.requestSerializer = [AFJSONRequestSerializer serializer];
            [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
            [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            break;
        case HHRequestTypePlainText:
            manager.requestSerializer = [AFHTTPRequestSerializer serializer];
            break;
        default:
            break;
    }
    
    switch (hh_responseType) {
        case HHResponseTypeJSON:
            manager.responseSerializer = [AFJSONResponseSerializer serializer];
            break;
        case HHResponseTypeXML:
            manager.responseSerializer = [AFXMLParserResponseSerializer serializer];
            break;
        case HHResponseTypeData:
            manager.responseSerializer = [AFHTTPResponseSerializer serializer];
            break;
        default:
            break;
    }
    
    manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
    
    for (NSString *key in hh_httpHeaders.allKeys) {
        if (hh_httpHeaders[key] != nil) {
            [manager.requestSerializer setValue:hh_httpHeaders[key] forHTTPHeaderField:key];
        }
    }
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",
                                                                              @"text/html",
                                                                              @"text/json",
                                                                              @"text/plain",
                                                                              @"text/javascript",
                                                                              @"text/xml",
                                                                              @"image/*"]];
    
    // 设置允许同时最大并发数量，过大容易出问题
    manager.operationQueue.maxConcurrentOperationCount = 3;
    
    return manager;
}

#pragma mark - log Success and Fail
+ (void)logWithSuccessResponse:(id)response url:(NSString *)url params:(NSDictionary *)params {
    HHLog(@"\nabsoluteUrl: %@\n params:%@\n response:%@\n\n",
              [self generateGETAbsoluteURL:url params:params],
              params,
              [self tryToParseData:response]);
}

+ (void)logWithFailError:(NSError *)error url:(NSString *)url params:(NSDictionary *)params {
    HHLog(@"\nabsoluteUrl: %@\n params:%@\n errorInfos:%@\n\n",
              [self generateGETAbsoluteURL:url params:params],
              params,
              [error localizedDescription]);
}

//!!!:仅对一级字典结构起作用
+ (NSString *)generateGETAbsoluteURL:(NSString *)url params:(NSDictionary *)params {
    if (params.count == 0) {
        return url;
    }
    
    NSString *queries = @"";
    for (NSString *key in params) {
        id value = [params objectForKey:key];
        
        if ([value isKindOfClass:[NSDictionary class]]) {
            continue;
        } else if ([value isKindOfClass:[NSArray class]]) {
            continue;
        } else if ([value isKindOfClass:[NSSet class]]) {
            continue;
        } else {
            queries = [NSString stringWithFormat:@"%@%@=%@&",
                       (queries.length == 0 ? @"&" : queries),
                       key,
                       value];
        }
    }
    
    if (queries.length > 1) {
        queries = [queries substringToIndex:queries.length - 1];
    }
    
    if (([url rangeOfString:@"http://"].location != NSNotFound
         || [url rangeOfString:@"https://"].location != NSNotFound)
        && queries.length > 1) {
        if ([url rangeOfString:@"?"].location != NSNotFound
            || [url rangeOfString:@"#"].location != NSNotFound) {
            url = [NSString stringWithFormat:@"%@%@", url, queries];
        } else {
            queries = [queries substringFromIndex:1];
            url = [NSString stringWithFormat:@"%@?%@", url, queries];
        }
    }
    
    return url.length == 0 ? queries : url;
}


+ (NSString *)encodeUrl:(NSString *)url {
    return [self hh_URLEncode:url];
}

+ (NSString *)hh_URLEncode:(NSString *)url {
    NSString *newString =
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                              (CFStringRef)url,
                                                              NULL,
                                                              CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
    if (newString) {
        return newString;
    }
    
    return url;
}

@end
