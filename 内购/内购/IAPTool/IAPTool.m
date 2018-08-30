//
//  IAPTool.m
//  内购
//
//  Created by luomh on 2018/8/29.
//  Copyright © 2018年 luomh. All rights reserved.
//

#ifdef DEBUG
#define checkURL @"https://sandbox.itunes.apple.com/verifyReceipt"
#define DLog(fmt,...) NSLog((@"++++++ " fmt @" ++++++"), ##__VA_ARGS__)
#else
#define checkURL @"https://buy.itunes.apple.com/verifyReceipt"
#define DLog(fmt,...)
#endif

#import "IAPTool.h"

@interface IAPTool ()<SKProductsRequestDelegate, SKPaymentTransactionObserver, NSURLSessionDelegate>

@property (nonatomic, strong) NSMutableDictionary *productDict;

@end

@implementation IAPTool

static IAPTool *tool = nil;
+ (instancetype)shareTool
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tool = [[self alloc] init];
    });
    return tool;
}

- (void)IAP_requestProductsWithProductIDs:(NSArray<NSString *> *)productIDs
{
    DLog(@"根据传入的产品ID请求可销售商品");
    
    NSSet *set = [NSSet setWithArray:productIDs];
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:set];
    request.delegate = self;
    [request start];
}

- (void)IAP_buyProductWithProductID:(nonnull NSString *)productID
{
    DLog(@"购买指定的商品");
    if (!productID)
    {
        NSLog(@"传入的productID为nil，购买终止");
        return;
    }
    
    SKProduct *product = self.productDict[productID];
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)IAP_restorePurchase
{
    // 恢复已经完成的所有交易.（仅限永久有效商品）
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)verifyThePuchaseWithProductID:(NSString * _Nonnull)productID
{
    /* 验证凭据，获取到苹果返回的交易凭据
     appStoreReceiptURL iOS7.0增加的，购买交易完成后，会将凭据存放在该地址 */
    NSURL *receiptUrl = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptUrl];
    
    NSString *receiptString = [receiptData base64EncodedStringWithOptions:NSUTF8StringEncoding];
    NSString *bodyString = [NSString stringWithFormat:@"{\"receipt-data\" : \"%@\"}", receiptString];
    NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURL *url = [NSURL URLWithString:checkURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = bodyData;
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:queue];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (!error)
        {
            NSDictionary *resultDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!resultDict)
                {
                    // 验证失败
                    [self.delegate IAP_buyProductResult:IAPBuyProductResultFailed];
                }
                else
                {
                    [self.delegate IAP_buyProductResult:IAPBuyProductResultSuccess];
                }
            });
            
        } else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate IAP_buyProductResult:IAPBuyProductResultFailed];
            });
        }
    }];
    [task resume];
}

#pragma mark - <SKProductsRequestDelegate>
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSMutableArray *products = [NSMutableArray arrayWithCapacity:1];
    for (SKProduct *product in response.products)
    {
        [self.productDict setValue:product forKey:product.productIdentifier];
        [products addObject:product];
    }
    [self.delegate IAP_requestProducts:products];
}

#pragma mark - <SKPaymentTransactionObserver>
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
    NSString *statusString = @"未知状态";
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:    // 购买完成
            {
                
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                if (self.verifyTheOrder)
                {
                    statusString = @"购买完成，需要认证!";
                    [self verifyThePuchaseWithProductID:transaction.payment.productIdentifier];
                }
                else
                {
                    statusString = @"购买完成";
                    [self.delegate IAP_buyProductResult:IAPBuyProductResultSuccess];
                }
            }
                break;
            case SKPaymentTransactionStateRestored:     // 恢复成功
            {
                statusString = @"恢复成功";
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [self.delegate IAP_buyProductResult:IAPBuyProductResultSuccess];
            }
                break;
            case SKPaymentTransactionStateFailed:       // 购买失败
            {
                statusString = @"购买失败";
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [self.delegate IAP_buyProductResult:IAPBuyProductResultFailed];
            }
                break;
            case SKPaymentTransactionStatePurchasing:   // 购买中
            {
                statusString = @"购买中";
                [self.delegate IAP_buyProductResult:IAPBuyProductResultBuying];
            }
                break;
            case SKPaymentTransactionStateDeferred:     // 已购买过
            {
                statusString = @"已购买过";
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [self.delegate IAP_buyProductResult:IAPBuyProductResultSuccess];
            }
                break;
                
            default:
                break;
        }
        DLog(@"购买状态: %@", statusString);
    }
}

- (NSMutableDictionary *)productDict
{
    if (!_productDict)
    {
        _productDict = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    return _productDict;
}


@end
