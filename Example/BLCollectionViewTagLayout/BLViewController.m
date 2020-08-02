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

@interface BLDecorationView : UICollectionReusableView
@end
@implementation BLDecorationView
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.blueColor;
        self.layer.cornerRadius = 5;
        self.clipsToBounds = YES;
        UIButton *obj = UIButton.new;
        [self addSubview:obj];
        obj.translatesAutoresizingMaskIntoConstraints = NO;
        [obj.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
        [obj.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
        [obj.widthAnchor constraintEqualToAnchor:self.widthAnchor].active = YES;
        [obj.heightAnchor constraintEqualToAnchor:self.heightAnchor].active = YES;
        [obj addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}
- (void)buttonClicked:(UIButton *)sender
{
    sender.backgroundColor = [UIColor colorWithHue:0.5 saturation:0.5 brightness:arc4random()%256/255.f alpha:1];
}
- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    [super applyLayoutAttributes:layoutAttributes];
    self.backgroundColor = layoutAttributes.indexPath.section % 2 ? UIColor.redColor : UIColor.blueColor;
    self.layer.zPosition = -1;
}
@end

@interface UINavigationBar (Private)
- (void)_setBarPosition:(UIBarPosition)barPosition;
@end

@interface UIBarButtonItem (Demo)
@property (nonatomic,assign,getter=isSelected) BOOL  selected;
@end
@implementation UIBarButtonItem (Demo)
- (void)setSelected:(BOOL)selected
{
    self.associatedButton.selected = selected;
}
- (BOOL)isSelected
{
    return self.associatedButton.isSelected;
}
- (UIControl *)associatedButton
{
    UIControl *obj = [self valueForKey:@"view"];
    NSAssert(obj, @"associatedButton does not exist");
    return obj;
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
    
    [self updateCollectionViewLayoutConfiguration];
    
    self.collectionView.contentInset = UIEdgeInsetsMake(44, 44, 44, 44);
//    self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(14, 0, 14, 0);
    [self.collectionView registerClass:UICollectionReusableView.class
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                   withReuseIdentifier:UICollectionElementKindSectionHeader];
    [self.collectionView registerClass:UICollectionReusableView.class
            forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                   withReuseIdentifier:UICollectionElementKindSectionFooter];
    NSMutableArray *array = @[].mutableCopy;
    for (unichar var = 'A'; var <= 'Z'; var++) {
        [array addObject:[NSString stringWithCharacters:&var length:1]];
    }
    self.alphabetArray = array.copy;
    self.dataSource = @[self.alphabetArray.mutableCopy].mutableCopy;
    [self add:nil];
    [self add:nil];
    [self add:nil];
    [self add:nil];
    [self add:nil];
    if (!self.navigationController) {
        self.navigationBar.hidden = NO;
    }
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateNavigationBarItems];
    if (_navigationBar && !objc_getAssociatedObject(self, _cmd)) {
        objc_setAssociatedObject(self, _cmd, _navigationBar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        self.collectionView.contentInset = UIEdgeInsetsMake(CGRectGetHeight(self.navigationBar.frame) + 44, 44, 44, 44);
        UIEdgeInsets inset = self.collectionView.contentInset;
        inset.bottom = self.tabBarController.tabBar.isTranslucent ? CGRectGetHeight(self.tabBarController.tabBar.frame) : 0;
        self.blCollectionViewLayout.adjustedContentInset = inset;
        [self.collectionView setContentOffset:CGPointMake(-inset.left, -inset.top) animated:NO];
    }
}
- (UINavigationItem *)navigationItem
{
    if (self.navigationController) return super.navigationItem;
    return self.navigationBar.topItem;
}
- (void)updateNavigationBarItems
{
    self.navigationItem.rightBarButtonItems.firstObject.selected =
    self.blCollectionViewLayout.sectionDecorationVisiable;
    self.navigationItem.rightBarButtonItems.lastObject.selected =
    self.blCollectionViewLayout.sectionHeadersPinToVisibleBounds;
}
- (void)updateCollectionViewLayoutConfiguration
{
    self.blCollectionViewLayout.elementAppearingAnimationFromValue =
    ^UICollectionViewLayoutAttributes * _Nullable(UICollectionViewLayoutAttributes * _Nullable originalLayoutAttributes) {
        if (originalLayoutAttributes.representedElementKind == UICollectionElementCategoryCell) {
            originalLayoutAttributes.alpha = 0.1;
        }
        return originalLayoutAttributes;
    };
    self.blCollectionViewLayout.elementDisappearingAnimationToValue =
    ^UICollectionViewLayoutAttributes * _Nullable(UICollectionViewLayoutAttributes * _Nullable originalLayoutAttributes) {
        if (originalLayoutAttributes.representedElementKind == UICollectionElementCategoryCell) {
            originalLayoutAttributes.alpha = 0.1;
        }
        return originalLayoutAttributes;
    };
    [self.blCollectionViewLayout registerClass:BLDecorationView.class forDecorationViewOfKind:BLCollectionElementKindSectionDecoration];
    [self.blCollectionViewLayout
     autoConfigSystemAdditionalAdjustedContentInsetWith:UIApplication.sharedApplication.statusBarFrame
                                          navigationBar:self.navigationController.navigationBar
                                                 tabbar:self.tabBarController.tabBar];
}
- (UINavigationBar *)navigationBar
{
    if (!_navigationBar) {
        UINavigationItem *item = UINavigationItem.new;
        item.leftBarButtonItems =
        @[
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add:)],
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(delete:)],
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)]
        ];
        item.rightBarButtonItems =
        @[
            [[UIBarButtonItem alloc] initWithTitle:@"Pin" style:UIBarButtonItemStylePlain target:self action:@selector(pin:)],
            [[UIBarButtonItem alloc] initWithTitle:@"Decoration" style:UIBarButtonItemStylePlain target:self action:@selector(decoration:)]
        ];
        item.prompt = @"Fake NavigationBar";
        _navigationBar = UINavigationBar.new;
        [_navigationBar _setBarPosition:UIBarPositionTopAttached];
        _navigationBar.shadowImage = nil;
        _navigationBar.translucent = YES;
        _navigationBar.backgroundColor = UIColor.clearColor;
        [_navigationBar pushNavigationItem:item animated:YES];
        [self.view addSubview:_navigationBar];
        _navigationBar.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:
         @[
             [_navigationBar.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
             [_navigationBar.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
             [_navigationBar.topAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.topAnchor],
         ]];
    }
    return _navigationBar;
}
- (BLCollectionViewTagLayout *)blCollectionViewLayout
{
    return (BLCollectionViewTagLayout *)self.collectionViewLayout;
}
- (IBAction)pin:(UIBarButtonItem *)sender
{
    self.blCollectionViewLayout.sectionHeadersPinToVisibleBounds =
    !self.blCollectionViewLayout.sectionHeadersPinToVisibleBounds;
    self.blCollectionViewLayout.sectionFootersPinToVisibleBounds =
    !self.blCollectionViewLayout.sectionFootersPinToVisibleBounds;
    sender.selected = self.blCollectionViewLayout.sectionFootersPinToVisibleBounds;
}
- (IBAction)decoration:(UIBarButtonItem *)sender
{
    self.blCollectionViewLayout.sectionDecorationVisiable =
    !self.blCollectionViewLayout.sectionDecorationVisiable;
    sender.selected = self.blCollectionViewLayout.sectionDecorationVisiable;
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
    if (kind == BLCollectionElementKindSectionDecoration) {
        return view;
    }
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
    [UIView animateWithDuration:0.3 animations:^{
        [collectionView performBatchUpdates:^{
            if (self.dataSource[indexPath.section].count == 1) {
                [self.dataSource removeObjectAtIndex:indexPath.section];
                [collectionView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section]];
            }else{
                [self.dataSource[indexPath.section] removeObjectAtIndex:indexPath.item];
                [collectionView deleteItemsAtIndexPaths:@[indexPath]];
            }
        } completion:nil];
    }];
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
