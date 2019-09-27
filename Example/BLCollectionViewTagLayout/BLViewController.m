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
    [self.collectionView registerClass:UICollectionReusableView.class
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:UICollectionElementKindSectionHeader];
    [self.collectionView registerClass:UICollectionReusableView.class
            forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:UICollectionElementKindSectionFooter];
    self.collectionView.contentOffset = CGPointZero;
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
- (BLCollectionViewTagLayout *)blCollectionViewLayout
{
    return (BLCollectionViewTagLayout *)self.collectionViewLayout;
}
#pragma mark <UICollectionViewDataSource>
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 10;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 10;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(UICollectionViewCell.class) forIndexPath:indexPath];
    UILabel *label = cell.contentView.subviews.firstObject;
    label.text = [NSString stringWithFormat:@"Section:%ld\nItem:%ld",indexPath.section,indexPath.item];
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
@end
