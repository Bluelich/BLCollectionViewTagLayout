//
//  BLCollectionViewTagLayout.h
//  BLCollectionViewTagLayout
//
//  Created by Bluelich on 2019/9/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSUInteger, BLCollectionViewTagLayoutItemRenderPolicy) {
    BLCollectionViewTagLayoutItemRenderDefault       = 0,//place section items one by one in order
    BLCollectionViewTagLayoutItemRenderShortestFirst = 1,//place item to shortest row each time
    BLCollectionViewTagLayoutItemRenderFullFill      = 2,//place item to full fill rows of each section, current unsupported
    BLCollectionViewTagLayoutItemRenderCustom        = 3,//place item use custom algorithm
};

#pragma mark - UICollectionViewTagStyleLayout
#pragma mark -
IB_DESIGNABLE NS_CLASS_AVAILABLE_IOS(8_0)
@interface BLCollectionViewTagLayout : UICollectionViewLayout
/**
 * The default size value is (50.0, 50.0).
 */
@property (nonatomic) IBInspectable CGSize itemSize;
/*
 * The default value of this property is 10.0.
 */
@property (nonatomic) CGFloat minimumLineSpacing;
/*
 * The default value of this property is 10.0.
 */
@property (nonatomic) CGFloat minimumInteritemSpacing;
/*
 * The default size values are (0, 0).
 */
@property (nonatomic) CGSize headerReferenceSize;
/*
 * The default size values are (0, 0).
 */
@property (nonatomic) CGSize footerReferenceSize;
/*
 * The default edge insets are all set to 0.
 *
 * It does not affect header footer，but for section items similar as UICollectionViewFlowLayout.
 */
@property (nonatomic) UIEdgeInsets sectionInset;
/*
* The default value is CGFLOAT_MAX
*
* You can specify the value for section items height limitation.
*
* Note : This value is the height of the section elements,except the header footer and section inset.
*/
@property (nonatomic) CGFloat  maximumSectionHeight;
/*
 * The default is UICollectionViewScrollDirectionVertical.
 *
 * Note: UICollectionViewScrollDirectionHorizontal is unimplemented.
 */
@property (nonatomic) UICollectionViewScrollDirection scrollDirection;
/*
 * The default is BLCollectionViewTagLayoutItemRenderDefault.
 */
@property (nonatomic) BLCollectionViewTagLayoutItemRenderPolicy itemRenderPolicy;
/*
 * The default value of this property is NO.
 */
@property (nonatomic) BOOL sectionHeadersPinToVisibleBounds;
/*
 * The default value of this property is NO.
 */
@property (nonatomic) BOOL sectionFootersPinToVisibleBounds;
@end

@interface BLCollectionViewTagLayout (UICollectionViewContentInsetAdjustment)
/*
 * Additional adjusted contentInset by system
 *
 * As usual, you don't need to care about this,the layout will fill in it automatically.
 *
 * Before iOS 11, if you want to pin header or footer of sections to visible bounds,
 * and you want to modify the scrollIndicatorInsets of the collectionView, you need to set the
 * correct value on this property,otherwise it will cause abnormal sense during displaying.
 *
 * Note :
 * 1. You can use autoConfigSystemAdditionalAdjustedContentInsetWith:navigationBar:tabbar:
 *    to do this automatically
 * 2. This property does no effect since iOS 11.
 *
 */
@property (nonatomic,assign) UIEdgeInsets  systemAdditionalAdjustedContentInset;

/*
 * Automatically systemAdditionalAdjustedContentInset configuration
 * by frame and translucent of UINavigationBar and UITabBar (and status bar)
 *
 * @param navigationBar UINavigationBar
 * @param tabbar UITabBar
 */
- (void)autoConfigSystemAdditionalAdjustedContentInsetWith:(CGRect )statusBarFrame
                                             navigationBar:(UINavigationBar *)navigationBar
                                                    tabbar:(UITabBar *)tabbar;
@end

@protocol BLCollectionViewDelegateTagStyleLayout <UICollectionViewDelegate>

@optional

- (CGSize)collectionView:(UICollectionView *)collectionView       layout:(BLCollectionViewTagLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(BLCollectionViewTagLayout *)collectionViewLayout insetForSection:(NSInteger)section;
- (CGFloat)collectionView:(UICollectionView *)collectionView      layout:(BLCollectionViewTagLayout *)collectionViewLayout minimumLineSpacingForSection:(NSInteger)section;
- (CGFloat)collectionView:(UICollectionView *)collectionView      layout:(BLCollectionViewTagLayout *)collectionViewLayout minimumInteritemSpacingForSection:(NSInteger)section;
- (CGFloat)collectionView:(UICollectionView *)collectionView      layout:(BLCollectionViewTagLayout *)collectionViewLayout maximumHeightForSection:(NSInteger)section;
- (CGSize)collectionView:(UICollectionView *)collectionView       layout:(BLCollectionViewTagLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section;
- (CGSize)collectionView:(UICollectionView *)collectionView       layout:(BLCollectionViewTagLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section;
- (NSArray<UICollectionViewLayoutAttributes *> *)collectionView:(UICollectionView *)collectionView layout:(BLCollectionViewTagLayout *)collectionViewLayout attributesInSection:(NSInteger)section boundingRect:(CGRect )boundingRect;
@end


NS_ASSUME_NONNULL_END
