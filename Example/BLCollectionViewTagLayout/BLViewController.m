//
//  BLViewController.m
//  BLCollectionViewTagLayout
//
//  Created by bluelich on 09/26/2019.
//  Copyright (c) 2019 bluelich. All rights reserved.
//

#import "BLViewController.h"
#import <BLCollectionViewTagLayout.h>
#import <objc/runtime.h>

@interface UIView (UIScrollIndicator)
@property (nonatomic,assign) BOOL  isIndicator;
@property (nonatomic,assign) BOOL  neverHidden;
@end
@implementation UIView (UIScrollIndicator)
+ (void)load
{
    method_exchangeImplementations(
    class_getInstanceMethod(self, @selector(setAlpha:)),
    class_getInstanceMethod(self, @selector(swizzling_setAlpha:)));
}
- (void)setIsIndicator:(BOOL)isIndicator
{
    objc_setAssociatedObject(self, @selector(isIndicator), @(isIndicator), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (BOOL)isIndicator
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}
- (void)setNeverHidden:(BOOL)neverHidden
{
    objc_setAssociatedObject(self, @selector(neverHidden), @(neverHidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (BOOL)neverHidden
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}
- (void)swizzling_setAlpha:(CGFloat)alpha
{
    if (self.isIndicator && self.neverHidden) alpha = 1;
    [self swizzling_setAlpha:alpha];
}
@end

@implementation UIScrollView (UIScrollIndicator)
+ (void)load
{
    method_exchangeImplementations(
    class_getInstanceMethod(self, @selector(setContentSize:)),
    class_getInstanceMethod(self, @selector(swizzling_setContentSize:)));
}
- (void)swizzling_setContentSize:(CGSize)contentSize
{
    [self swizzling_setContentSize:contentSize];
    //
    UIImageView *verticalScrollIndicator =
    [self valueForKeyPath:@"verticalScrollIndicator"];
    verticalScrollIndicator.isIndicator = YES;
    verticalScrollIndicator.neverHidden =
    CGRectGetHeight(self.bounds) < contentSize.height;
    if (verticalScrollIndicator.neverHidden) {
        verticalScrollIndicator.alpha = 1;
    }
    //
    UIImageView *horizontalScrollIndicator =
    [self valueForKeyPath:@"horizontalScrollIndicator"];
    horizontalScrollIndicator.isIndicator = YES;
    horizontalScrollIndicator.neverHidden =
    CGRectGetWidth(self.bounds) < contentSize.width;
    if (horizontalScrollIndicator.neverHidden) {
        horizontalScrollIndicator.alpha = 1;
    }
}
@end

@interface BLViewController ()<BLCollectionViewDelegateTagStyleLayout>
@property (nonatomic,strong) NSArray<NSString *>  *alphabetArray;
@property (nonatomic,strong) NSMutableArray<NSMutableArray *> *dataSource;
@property (nonatomic,strong) UINavigationBar *navigationBar;
@end

@implementation BLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    
    self.collectionView.contentInset = UIEdgeInsetsMake(44, 44, 44, 44);
//    self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(14, 0, 14, 0);
    
    [self.blCollectionViewLayout
     autoConfigSystemAdditionalAdjustedContentInsetWith:UIApplication.sharedApplication.statusBarFrame
                                          navigationBar:self.navigationController.navigationBar
                                                 tabbar:self.tabBarController.tabBar];
    
    [self.collectionView registerClass:UICollectionReusableView.class
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:UICollectionElementKindSectionHeader];
    [self.collectionView registerClass:UICollectionReusableView.class
            forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:UICollectionElementKindSectionFooter];
    NSMutableArray *array = @[].mutableCopy;
    for (unichar var = 'A'; var <= 'Z'; var++) {
        NSString *text =
        [NSString stringWithCharacters:&var length:1];
        [array addObject:text];
    }
    self.alphabetArray = array.copy;
    self.dataSource = @[self.alphabetArray.mutableCopy].mutableCopy;
    [self add:nil];
    [self add:nil];
    [self add:nil];
    [self add:nil];
    [self add:nil];
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.navigationController) return;
    self.navigationBar.hidden = NO;
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.navigationController) return;
    self.navigationBar.hidden = YES;
}

- (UINavigationBar *)navigationBar
{
    if (self.navigationController) return nil;
    if (!_navigationBar) {
        UINavigationItem *item = UINavigationItem.new;
        item.title = @"Fake NavigationBar";
        item.leftBarButtonItems =
        @[
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add:)],
            [[UIBarButtonItem alloc] initWithTitle:@"  - " style:UIBarButtonItemStyleDone target:self action:@selector(delete:)],
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)]
        ];
        item.rightBarButtonItems =
        @[
            [[UIBarButtonItem alloc] initWithTitle:@"UnPin" style:UIBarButtonItemStyleDone target:self action:@selector(unPin:)],
            [[UIBarButtonItem alloc] initWithTitle:@"Pin" style:UIBarButtonItemStyleDone target:self action:@selector(pin:)]
        ];
        [item.leftBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.style = UIBarButtonItemStyleDone;
        }];
        [item.rightBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.style = UIBarButtonItemStyleDone;
        }];
        item.prompt = @"Prompt";
        _navigationBar = UINavigationBar.new;
        _navigationBar.translucent = YES;
        _navigationBar.backgroundColor = UIColor.clearColor;
        _navigationBar.items = @[item];
        [self.view addSubview:_navigationBar];
        _navigationBar.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:
         @[
             [_navigationBar.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
             [_navigationBar.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
             [_navigationBar.topAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.topAnchor],
         ]];
        UIVisualEffectView *effectView =
        [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
        [self.view addSubview:effectView];
        effectView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:
        @[
            [effectView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
            [effectView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
            [effectView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
            [effectView.bottomAnchor constraintEqualToAnchor:_navigationBar.topAnchor]
        ]];
        {
            self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
            [NSLayoutConstraint activateConstraints:
             @[
                 [self.collectionView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
                 [self.collectionView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
                 [self.collectionView.topAnchor constraintEqualToAnchor:_navigationBar.bottomAnchor],
                 [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
             ]];
        }
    }
    return _navigationBar;
}
- (BLCollectionViewTagLayout *)blCollectionViewLayout
{
    return (BLCollectionViewTagLayout *)self.collectionViewLayout;
}
- (IBAction)pin:(UIBarButtonItem *)sender
{
    self.blCollectionViewLayout.sectionHeadersPinToVisibleBounds = YES;
    self.blCollectionViewLayout.sectionFootersPinToVisibleBounds = YES;
}
- (IBAction)unPin:(UIBarButtonItem *)sender
{
    self.blCollectionViewLayout.sectionHeadersPinToVisibleBounds = NO;
    self.blCollectionViewLayout.sectionFootersPinToVisibleBounds = NO;
}
- (IBAction)add:(UIBarButtonItem *)sender
{
    if (arc4random() % 2) {
        [self.dataSource addObject:self.alphabetArray.mutableCopy];
    }else{
        NSMutableArray *array = @[].mutableCopy;
        NSInteger count = arc4random() % 30;
        for (NSInteger item = 0; item < count; item++) {
            [array addObject:[NSString stringWithFormat:@"Section:%ld\nItem:%ld",self.dataSource.count,item]];
        }
        [self.dataSource addObject:array];
    }
    [self.collectionView reloadData];
}
- (IBAction)delete:(UIBarButtonItem *)sender
{
    if (self.dataSource.count == 0) return;
    [self.dataSource removeObject:self.dataSource.lastObject];
    [self.collectionView reloadData];
}
- (IBAction)refresh:(UIBarButtonItem *)sender
{
    [self.collectionView reloadData];
}
#pragma mark <UICollectionViewDataSource>
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.dataSource.count;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.dataSource[section] count];
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(UICollectionViewCell.class) forIndexPath:indexPath];
    UILabel *label = cell.contentView.subviews.firstObject;
    label.text = self.dataSource[indexPath.section][indexPath.item];
    return cell;
}
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:kind forIndexPath:indexPath];
    UILabel *label = view.subviews.firstObject;
    if (!label) {
        label = UILabel.new;
        label.numberOfLines = 2;
        label.textColor = UIColor.whiteColor;
        [view addSubview:label];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [label.leftAnchor constraintEqualToAnchor:view.leftAnchor constant:5].active = YES;
        [label.centerYAnchor constraintEqualToAnchor:view.centerYAnchor].active = YES;
    }
    NSString *string = [kind stringByReplacingOccurrencesOfString:@"UICollectionElementKindSection" withString:@""];
    label.text = [NSString stringWithFormat:@"%@\nSection:%ld",string,indexPath.section];
    view.backgroundColor = UIColor.purpleColor;
    if (kind == UICollectionElementKindSectionHeader) {
        view.backgroundColor = UIColor.brownColor;
    }
    return view;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    [collectionView performBatchUpdates:^{
        if (self.dataSource[indexPath.section].count == 1) {
            [self.dataSource removeObjectAtIndex:indexPath.section];
            [collectionView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section]];
        }else{
            [self.dataSource[indexPath.section] removeObjectAtIndex:indexPath.item];
            [collectionView deleteItemsAtIndexPaths:@[indexPath]];
        }
    } completion:nil];
}
#pragma mark -
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(BLCollectionViewTagLayout *)collectionViewLayout maximumHeightForSection:(NSInteger)section
{
    return collectionViewLayout.itemSize.height * (section % 5 ? section : 1);
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(BLCollectionViewTagLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if ([self.dataSource[section] count] > 0) {
        return collectionViewLayout.headerReferenceSize;
    }
    return CGSizeZero;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(BLCollectionViewTagLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    if ([self.dataSource[section] count] > 0) {
        return collectionViewLayout.footerReferenceSize;
    }
    return CGSizeZero;
}
@end
