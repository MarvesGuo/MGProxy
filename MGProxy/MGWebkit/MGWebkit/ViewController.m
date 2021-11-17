//
//  ViewController.m
//  MGWebkit
//
//  Created by 虔灵 on 2021/10/12.
//

#import "ViewController.h"
#import "MGUIWebViewController.h"
#import "MGWKViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)uiWebviewAction:(id)sender {
    NSString *url = @"http://www.baidu.com";
    MGUIWebViewController *vc = [[MGUIWebViewController alloc]initWithURL:url];
    [self presentViewController:vc animated:YES completion:nil];
}
- (IBAction)wkWebviewAction:(id)sender {
    
    NSString *url = @"http://www.baidu.com";
    MGWKViewController *vc = [[MGWKViewController alloc]initWithURL:url];
    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction)httpAction:(id)sender {
}

- (IBAction)httpsAction:(id)sender {
}

@end
