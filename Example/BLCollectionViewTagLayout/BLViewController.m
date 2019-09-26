//
//  BLViewController.m
//  BLCollectionViewTagLayout
//
//  Created by bluelich on 09/26/2019.
//  Copyright (c) 2019 bluelich. All rights reserved.
//

#import "BLViewController.h"
#import <BLCollectionViewTagLayout.h>

@interface BLViewController ()

@end

@implementation BLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    self.collectionView.contentInset = UIEdgeInsetsMake(44, 44, 44, 44);
    self.collectionView.backgroundColor = UIColor.redColor;
    self.view.backgroundColor = UIColor.blueColor;
    self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(14, 0, 14, 0);
    [(BLCollectionViewTagLayout *)self.collectionViewLayout autoConfigSystemAdditionalAdjustedContentInsetWith:UIApplication.sharedApplication.statusBarFrame navigationBar:self.navigationController.navigationBar tabbar:self.tabBarController.tabBar];
    [self.collectionView registerClass:UICollectionReusableView.class
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:UICollectionElementKindSectionHeader];
    [self.collectionView registerClass:UICollectionReusableView.class
            forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:UICollectionElementKindSectionFooter];
    self.collectionView.contentOffset = CGPointZero;
}
- (void)flashScrollIndicators
{
    [self.collectionView flashScrollIndicators];
}
#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 10;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 10;
}

static NSInteger const labelTag = 1000;
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    UILabel *label = [cell.contentView viewWithTag:labelTag];
    if (!label) {
        label = [UILabel new];
        label.tag = labelTag;
        label.numberOfLines = 0;
        [cell.contentView addSubview:label];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [label.centerXAnchor constraintEqualToAnchor:cell.contentView.centerXAnchor].active = YES;
        [label.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor].active = YES;
    }
    label.text = [NSString stringWithFormat:@"section:%ld\nitem:%ld",indexPath.section,indexPath.item];
    cell.backgroundColor = UIColor.lightGrayColor;
    return cell;
}
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:kind forIndexPath:indexPath];
    UILabel *label = [view viewWithTag:1000];
    if (!label) {
        label = [UILabel new];
        label.tag = 1000;
        label.numberOfLines = 0;
        [view addSubview:label];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [label.leftAnchor constraintEqualToAnchor:view.leftAnchor].active = YES;
        [label.centerYAnchor constraintEqualToAnchor:view.centerYAnchor].active = YES;
    }
    NSString *string = [kind stringByReplacingOccurrencesOfString:@"UICollectionElementKindSection" withString:@""];
    label.text = [NSString stringWithFormat:@"%@\nsection:%ld",string,indexPath.section];
    view.backgroundColor = UIColor.greenColor;
    if (kind == UICollectionElementKindSectionHeader) {
        view.backgroundColor = UIColor.brownColor;
    }
    return view;
}
#pragma mark UICollectionViewDelegateTagStyleLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(BLCollectionViewTagLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(80 + indexPath.item * (indexPath.section + 5), collectionViewLayout.itemSize.height);
}
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(BLCollectionViewTagLayout *)collectionViewLayout insetForSection:(NSInteger)section
{
    return UIEdgeInsetsMake(50, section, 50, section);
}

@end
