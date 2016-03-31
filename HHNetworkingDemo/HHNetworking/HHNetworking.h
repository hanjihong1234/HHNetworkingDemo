//
//  HHNetworking.h
//  HHNetworkingDemo
//
//  Created by 韩继宏 on 16/3/30.
//  Copyright © 2016年 韩 继宏. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/*!
 *  @author 韩继宏, 16-03-30 22:03:50
 *
 *  下载进度
 *
 *  @param bytesRead      已下载的大小
 *  @param totalBytesRead 文件总大小
 */
typedef void(^HHDownloadProgress)(ino64_t bytesRead,
                                  ino64_t totalBytesRead);
typedef HHDownloadProgress HHGetProgress;
typedef HHDownloadProgress HHPostProgress;

/*!
 *  @author 韩继宏, 16-03-30 22:03:19
 *
 *  上传进度
 *
 *  @param bytesWritten      已上传的大小
 *  @param totalBytesWritten 总上传的大小
 */
typedef void(^HHUploadProgress)(ino64_t bytesWritten,
                                ino64_t totalBytesWritten);

typedef NS_ENUM(NSUInteger, HHResponseType) {
    HHResponseTypeJSON = 1, // 默认JSON
    HHResponseTypeXML  = 2, // XML
    HHResponseTypeData = 3  // 特殊情况下，一转换服务器就无法识别的，默认会尝试转换成JSON，若失败则需要自己去转换
};

typedef NS_ENUM(NSUInteger, HHRequestType) {
    HHRequestTypeJSON = 1, // 默认JSON
    HHRequestTypePlainText = 2 // 普通text/html
};

@class NSURLSessionTask;
// 请勿直接使用NSURLSessionDataTask,以减少对第三方的依赖
// 所有接口返回的类型都是基类NSURLSessionTask，若要接收返回值
// 且处理，请转换成对应的子类类型
typedef NSURLSessionTask HHURLSessionTask;

/*!
 *  @author 韩继宏, 16-03-30 22:03:09
 *
 *  请求成功的回调
 *
 *  @param response 服务端返回的数据类型，通常都是字典
 */
typedef void(^HHResponseSuccess)(id response);

/*!
 *  @author 韩继宏, 16-03-30 22:03:27
 *
 *  网络响应失败时的回调
 *
 *  @param error 错误信息
 */
typedef void(^HHResponseFail)(NSError *error);

/*!
 *  @author 韩继宏, 16-03-30 22:03:30
 *
 *  基于AFNetworking的网络层封装类
 */
@interface HHNetworking : NSObject

/*!
 *  @author 韩继宏, 16-03-30 22:03:53
 *
 *  用于指定网络请求接口的基础url
 *
 *  @param baseUrl 网络接口的基础url
 */
+ (void)updateBaseUrl:(NSString *)baseUrl;

/*!
 *  @author 韩继宏, 16-03-30 22:03:01
 *
 *  对外公开可获取当前所设置的网络接口基础url
 *
 *  @return 当前基础url
 */
+ (NSString *)baseUrl;

/*!
 *  @author 韩继宏, 16-03-31 13:03:42
 *
 *  开启或关闭接口打印信息
 *
 *  @param isDebug 默认是NO，开发期最好打开
 */
+ (void)enableInterfaceDebug:(BOOL)isDebug;

/*!
 *  @author 韩继宏, 16-03-31 13:03:33
 *
 *  配置响应格式，默认为JSON，如果为XML或者PLIST，需要在全局修改一下
 *
 *  @param responseType 响应格式
 */
+ (void)configResponseType:(HHResponseType)responseType;

/*!
 *  @author 韩继宏, 16-03-31 13:03:56
 *
 *  配置请求格式，默认为JSON，如果要求传XML或者PLIST，需要在全局配置一下
 *
 *  @param requestType 请求格式
 */
+ (void)configRequest:(HHRequestType)requestType;

/*!
 *  @author 韩继宏, 16-03-31 13:03:12
 *
 *  开启或关闭是否自动将URL使用UTF8编码，用于处理链接中有中文时无法请求的问题
 *
 *  @param shouldAutoEncode YES or NO，默认为NO
 */
+ (void)shouldAutoEncodeUrl:(BOOL)shouldAutoEncode;

/*!
 *  @author 韩继宏, 16-03-31 13:03:59
 *
 *  配置公共的请求头，只调用一次即可，通常放在应用启动的时候配置就可以了
 *
 *  @param httpHeaders 只需要将与服务器商定的固定参数设置即可
 */
+ (void)configCommonHttpHeaders:(NSDictionary *)httpHeaders;

/*!
 *  @author 韩继宏, 16-03-31 13:03:50
 *
 *  GET请求接口，若不指定baseUrl，可传完整的url
 *
 *  @param url     接口路径
 *  @param success 接口请求数据成功的回调
 *  @param fail    接口请求数据失败的回调
 *
 *  @return 返回的对象中有可取消请求的API
 */
+ (HHURLSessionTask *)getWithUrl:(NSString *)url
                         success:(HHResponseSuccess)success
                            fail:(HHResponseFail)fail;

/*!
 *  @author 韩继宏, 16-03-31 13:03:42
 *
 *  GET请求接口，若不指定baseUrl，可传完整的url
 *
 *  @param url     接口路径
 *  @param params  接口中所需要的拼接参数，如@{"categoryid" : @(12)}
 *  @param success 接口请求数据成功的回调
 *  @param fail    接口请求数据失败的回调
 *
 *  @return 返回的对象中有可取消请求的API
 */
+ (HHURLSessionTask *)getWithUrl:(NSString *)url
                         params:(NSDictionary *)params
                         success:(HHResponseSuccess)success
                            fail:(HHResponseFail)fail;

/*!
 *  @author 韩继宏, 16-03-31 13:03:17
 *
 *  GET请求接口，若不指定baseUrl，可传完整的url
 *
 *  @param url      接口路径
 *  @param params   接口中所需要的拼接参数
 *  @param progress 请求数据的进度
 *  @param success  接口请求数据成功的回调
 *  @param fail     接口请求数据失败的回调
 *
 *  @return 返回的对象中有可取消请求的API
 */
+ (HHURLSessionTask *)getWithUrl:(NSString *)url
                          params:(NSDictionary *)params
                        progress:(HHGetProgress)progress
                         success:(HHResponseSuccess)success
                            fail:(HHResponseFail)fail;

/*!
 *  @author 韩继宏, 16-03-31 13:03:34
 *
 *  POST请求接口，若不指定baseUrl，可传完整的url
 *
 *  @param url     接口路径
 *  @param params  接口中所需要的拼接参数
 *  @param success 接口请求数据成功的回调
 *  @param fail    接口请求数据失败的回调
 *
 *  @return 返回的对象中有可取消请求的API
 */
+ (HHURLSessionTask *)postWithUrl:(NSString *)url
                          params:(NSDictionary *)params
                         success:(HHResponseSuccess)success
                            fail:(HHResponseFail)fail;

/*!
 *  @author 韩继宏, 16-03-31 13:03:31
 *
 *  POST请求接口，若不指定baseUrl，可传完整的url
 *
 *  @param url      接口路径
 *  @param params   接口中所需要的拼接参数
 *  @param progress 请求数据的进度
 *  @param success  接口请求数据成功的回调
 *  @param fail     接口请求数据失败的回调
 *
 *  @return 返回的对象中有可取消请求的API
 */
+ (HHURLSessionTask *)postWithUrl:(NSString *)url
                          params:(NSDictionary *)params
                        progress:(HHGetProgress)progress
                         success:(HHResponseSuccess)success
                            fail:(HHResponseFail)fail;

/*!
 *  @author 韩继宏, 16-03-31 13:03:49
 *
 *  图片上传接口，若不指定baseUrl，可传完整的url
 *
 *  @param image    图片对象
 *  @param url      上传图片的接口路径
 *  @param filename 给图片起一个名字，默认为当前日期时间，格式为"yyyyMMddHHmmss"，后缀为'jpg'
 *  @param name     与指定的图片相关联的名称，由后端写接口的人指定的，如imagefiles
 *  @param mimeType 默认为image/jpeg
 *  @param params   所需参数
 *  @param progress 上传进度
 *  @param success  上传成功回调
 *  @param fail     上传失败回调
 *
 *  @return <#return value description#>
 */
+ (HHURLSessionTask *)uploadWithImage:(UIImage *)image
                                  url:(NSString *)url
                             filename:(NSString *)filename
                                 name:(NSString *)name
                             mimeType:(NSString *)mimeType
                               params:(NSDictionary *)params
                             progress:(HHUploadProgress)progress
                              success:(HHResponseSuccess)success
                                 fail:(HHResponseFail)fail;

/*!
 *  @author 韩继宏, 16-03-31 14:03:16
 *
 *  文件上传接口
 *
 *  @param url           上传路径
 *  @param uploadingFile 待上传文件的路径
 *  @param progress      上传进度
 *  @param success       上传成功的回调
 *  @param fail          上传失败的回调
 *
 *  @return <#return value description#>
 */
+ (HHURLSessionTask *)uploadFileWithUrl:(NSString *)url
                          uploadingFile:(NSString *)uploadingFile
                               progress:(NSString *)progress
                                success:(HHResponseSuccess)success
                                   fail:(HHResponseFail)fail;

/*!
 *  @author 韩继宏, 16-03-31 14:03:07
 *
 *  下载文件接口
 *
 *  @param url        下载URL
 *  @param saveToPath 下载到哪个路径下
 *  @param progress   下载进度
 *  @param success    下载成功后的回调
 *  @param fail       下载失败后的回调
 *
 *  @return <#return value description#>
 */
+ (HHURLSessionTask *)downloadWithUrl:(NSString *)url
                           saveToPath:(NSString *)saveToPath
                             progress:(HHUploadProgress)progress
                              success:(HHResponseSuccess)success
                                 fail:(HHResponseFail)fail;

@end
