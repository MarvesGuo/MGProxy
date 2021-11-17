//
//  MGWKViewController.m
//  MGWebkit
//
//  Created by 虔灵 on 2021/10/12.
//

#import "MGWKViewController.h"
#import <WebKit/WKWebView.h>
#import <WebKit/WKWebViewConfiguration.h>
#import <WebKit/WKURLSchemeHandler.h>

@interface MGWKViewController ()
<
    WKURLSchemeHandler
>

@property (nonatomic, strong) WKWebView *webview;


@end

@implementation MGWKViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
- (instancetype) initWithURL:(NSString *)url
{
    if (self = [super init]) {
        [self webview];
        if (url.length > 0) {
            NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
            [self.webview loadRequest:req];
        }
    }
    return self;
}



- (WKWebView *)webview
{
    if (!_webview) {
        
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc]init];
        [config setURLSchemeHandler:self forURLScheme:@"http"];
        [config setURLSchemeHandler:self forURLScheme:@"https"];    // 苹果官方不行 'https' is a URL scheme that WKWebView handles natively'， 可以调用私有API
        
        WKWebView *webview = [[WKWebView alloc]initWithFrame:self.view.frame configuration:config];
        [self.view addSubview:webview];
        _webview = webview;
        UIControl *control = [[UIControl alloc]initWithFrame:CGRectMake(0, 0, webview.frame.size.width, 64)];
        [control addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:control];
        
    }
    return _webview;
}


- (void)closeAction
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)webView:(WKWebView *)webView startURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask
{
    
}

-(void)webView:(WKWebView *)webView stopURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask
{
    
}


@end
