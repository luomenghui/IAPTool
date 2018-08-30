//
//  IAPTool.h
//  内购
//
//  Created by luomh on 2018/8/29.
//  Copyright © 2018年 luomh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

typedef NS_ENUM(NSInteger, IAPBuyProductResult) {
    IAPBuyProductResultSuccess,
    IAPBuyProductResultBuying,
    IAPBuyProductResultFailed,
};

@protocol IAPToolDelegate <NSObject>

- (void)IAP_requestProducts:(NSArray<SKProduct *> *)products;
- (void)IAP_buyProductResult:(IAPBuyProductResult)state;

@end

@interface IAPTool : NSObject

@property (nonatomic, weak) id<IAPToolDelegate>delegate;
/** 购买完成后是否需要验证，默认为NO */
@property (nonatomic, assign) BOOL verifyTheOrder;

+ (instancetype)shareTool;

/**
 请求可销售商品列表

 @param productIDs 商品ID数组
 */
- (void)IAP_requestProductsWithProductIDs:(NSArray<NSString *> *)productIDs;

/**
 购买商品

 @param productID 商品ID
 */
- (void)IAP_buyProductWithProductID:(nonnull NSString *)productID;

/**
 恢复购买（仅限永久有效商品）
 */
- (void)IAP_restorePurchase;

@end
