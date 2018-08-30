//
//  ViewController.m
//  内购
//
//  Created by luomh on 2018/8/29.
//  Copyright © 2018年 luomh. All rights reserved.
//

/*
 * 需要在申请的 APP ID 中打开内购选项，并且 Bundle Identifier 要和项目的一致，
 * 在 Capabilities 中打开IAP(我这里只是测试Demo没有设置)
 * 配置好商品后，将商品ID给到 IAP_requestProductsWithProductIDs: 方法
 */
#define SCREENWIDTH [UIScreen mainScreen].bounds.size.width
#define SCREENHEIGHT [UIScreen mainScreen].bounds.size.height

#import "ViewController.h"
#import "IAPTool.h"

@interface ViewController ()<IAPToolDelegate>

@property (nonatomic, strong) NSMutableArray *products;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"测试";
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    _products = [NSMutableArray arrayWithCapacity:1];
    [[IAPTool shareTool] setDelegate:self];
    [self setupView];
}

- (void)setupView
{
    [self createButtonWithTitle:@"Buy" tag:1];
    [self createButtonWithTitle:@"Restore" tag:2];
}

- (void)clickButton:(UIButton *)btn
{
    if (btn.tag == 1)
    {
        [[IAPTool shareTool] IAP_requestProductsWithProductIDs:@[@"商品ID"]];
    }
    else
    {
        [[IAPTool shareTool] IAP_restorePurchase];
    }
}

#pragma mark - <IAPToolDelegate>
- (void)IAP_requestProducts:(NSArray<SKProduct *> *)products
{
    if (products.count > 0)
    {
        [self.products removeAllObjects];
        [self.products addObjectsFromArray:products];
        SKProduct *product = [products objectAtIndex:0];
        [[IAPTool shareTool] IAP_buyProductWithProductID:product.productIdentifier];
    }
    else
    {
        [self alertUser:@"无可销售商品"];
    }
}
- (void)IAP_buyProductResult:(IAPBuyProductResult)state
{
    NSString *desc = nil;
    switch (state)
    {
        case IAPBuyProductResultSuccess:
        {
            desc = @"购买成功";
        }
            break;
        case IAPBuyProductResultFailed:
        {
            desc = @"购买失败";
        }
            break;
            
        default:
        {
            desc = @"购买中";
        }
            break;
    }
    [self alertUser:desc];
}


#pragma mark - Tools
- (void)createButtonWithTitle:(NSString *)title tag:(NSInteger)tag
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.tag = tag;
    btn.layer.cornerRadius = 5;
    btn.backgroundColor = [UIColor blueColor];
    [btn setTitle:title forState:UIControlStateNormal];
    btn.frame = CGRectMake(40, 100 + 60 * (tag - 1), SCREENWIDTH - 80, 50);
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)alertUser:(NSString * _Nonnull)text
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:text delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alertView show];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
