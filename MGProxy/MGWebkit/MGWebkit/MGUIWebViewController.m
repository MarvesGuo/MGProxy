//
//  MGUIWebViewController.m
//  MGWebkit
//
//  Created by 虔灵 on 2021/10/12.
//

#import "MGUIWebViewController.h"

@interface MGUIWebViewController ()
@property (nonatomic, strong) UIWebView *webview;

@end

@implementation MGUIWebViewController

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



- (UIWebView *)webview
{
    if (!_webview) {
        UIWebView *webview = [[UIWebView alloc]initWithFrame:self.view.frame];
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

@end
