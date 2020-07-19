//
//  BLCollectionViewTagLayout.m
//  BLCollectionViewTagLayout
//
//  Created by Bluelich on 2019/9/26.
//

#import "BLCollectionViewTagLayout.h"

NSString *const BLCollectionElementKindSectionDecoration = @"BLCollectionElementKindSectionDecoration";

#pragma mark - UICollectionViewTagStyleLayoutSectionAttributes Declare
#pragma mark -
@interface UICollectionViewTagStyleLayoutSectionAttributes : NSObject<NSCopying>
@property (nonatomic,strong) UICollectionViewLayoutAttributes            *header;
@property (nonatomic,strong) NSArray<UICollectionViewLayoutAttributes *> *items;
@property (nonatomic,strong) UICollectionViewLayoutAttributes            *footer;
@property (nonatomic,strong) UICollectionViewLayoutAttributes            *decoration;
+ (instancetype)layoutAttributesWithHeader:(UICollectionViewLayoutAttributes *)header
                                     items:(NSArray<UICollectionViewLayoutAttributes *> *)items
                                    footer:(UICollectionViewLayoutAttributes *)footer
                                decoration:(UICollectionViewLayoutAttributes *)decoration;
@end
#pragma mark - UICollectionViewTagStyleLayoutSectionAttributes Implementation
#pragma mark -
@implementation UICollectionViewTagStyleLayoutSectionAttributes
+ (instancetype)layoutAttributesWithHeader:(UICollectionViewLayoutAttributes *)header
                                     items:(NSArray<UICollectionViewLayoutAttributes *> *)items
                                    footer:(UICollectionViewLayoutAttributes *)footer
                                decoration:(UICollectionViewLayoutAttributes *)decoration
{
    UICollectionViewTagStyleLayoutSectionAttributes *obj =
    UICollectionViewTagStyleLayoutSectionAttributes.new;
    obj.header = header;
    obj.items  = items;
    obj.footer = footer;
    obj.decoration = decoration;
    return obj;
}
- (id)copyWithZone:(NSZone *)zone
{
    UICollectionViewTagStyleLayoutSectionAttributes *obj =
    UICollectionViewTagStyleLayoutSectionAttributes.new;
    obj.header = self.header.copy;
    obj.items  = [[NSArray alloc] initWithArray:self.items copyItems:YES];
    obj.footer = self.footer.copy;
    obj.decoration = self.decoration.copy;
    return obj;
}
@end

#pragma mark - UICollectionViewTagStyleLayoutSectionItemSorter Declare
#pragma mark -
@interface UICollectionViewTagStyleLayoutSectionItemSorter : NSObject
+ (NSArray<UICollectionViewLayoutAttributes *> *)sorted:(NSArray<UICollectionViewLayoutAttributes *> *)attributes
                                            usingPolicy:(BLCollectionViewTagLayoutItemRenderPolicy)policy
                                           boundingRect:(CGRect )boundingRect
                                     minimumLineSpacing:(CGFloat)minimumLineSpacing
                                minimumInteritemSpacing:(CGFloat)minimumInteritemSpacing;
@end

#pragma mark - UICollectionViewTagStyleLayoutSectionItemSorter Implementation
#pragma mark -
@implementation UICollectionViewTagStyleLayoutSectionItemSorter

+ (NSArray<UICollectionViewLayoutAttributes *> *)sorted:(NSArray<UICollectionViewLayoutAttributes *> *)attributes
                                            usingPolicy:(BLCollectionViewTagLayoutItemRenderPolicy)policy
                                           boundingRect:(CGRect )boundingRect
                                     minimumLineSpacing:(CGFloat)minimumLineSpacing
                                minimumInteritemSpacing:(CGFloat)minimumInteritemSpacing
{
    switch (policy) {
        case BLCollectionViewTagLayoutItemRenderDefault:
        case BLCollectionViewTagLayoutItemRenderShortestFirst:
            return [self sortedAttributesWithPolicy:policy
                                         attributes:attributes
                                       boundingRect:boundingRect
                                 minimumLineSpacing:minimumLineSpacing
                            minimumInteritemSpacing:minimumInteritemSpacing];
        case BLCollectionViewTagLayoutItemRenderFullFill:
            return [self sortedForFullFill:attributes
                              boundingRect:boundingRect
                        minimumLineSpacing:minimumLineSpacing
                   minimumInteritemSpacing:minimumInteritemSpacing];
        case BLCollectionViewTagLayoutItemRenderCustom:
            return nil;
    }
}
+ (NSArray *)sortedAttributesWithPolicy:(BLCollectionViewTagLayoutItemRenderPolicy)policy
                             attributes:(NSArray<UICollectionViewLayoutAttributes *> *)attributes
                           boundingRect:(CGRect )boundingRect
                     minimumLineSpacing:(CGFloat)minimumLineSpacing
                minimumInteritemSpacing:(CGFloat)minimumInteritemSpacing
{
    NSParameterAssert(policy == BLCollectionViewTagLayoutItemRenderDefault ||
                      policy == BLCollectionViewTagLayoutItemRenderShortestFirst);
    NSMutableArray<UICollectionViewLayoutAttributes *> *attributesForItems = @[].mutableCopy;
    NSMutableArray<UICollectionViewLayoutAttributes *> *rightmostItems = @[].mutableCopy;
    [attributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *obj, NSUInteger idx, BOOL *stop) {
        CGPoint itemOrigin = CGPointZero;
        obj.frame = (CGRect){
            .origin = obj.frame.origin,
            .size = {
                .width = MIN(obj.size.width, CGRectGetWidth(boundingRect)),
                .height = obj.size.height
            }
        };
        
        if (idx == 0) {
            itemOrigin = boundingRect.origin;
        }else{
            UICollectionViewLayoutAttributes *rightmostItem = nil;
            for (UICollectionViewLayoutAttributes *obj in rightmostItems) {
                if (CGRectGetMaxX(obj.frame) + minimumInteritemSpacing + CGRectGetWidth(obj.frame)
                    > CGRectGetWidth(boundingRect)) continue;//cannot place the new item here
                rightmostItem = obj;
                break;
            }
            if (rightmostItem) {
                //place the item here
                itemOrigin = CGPointMake(CGRectGetMaxX(rightmostItem.frame) + minimumInteritemSpacing, CGRectGetMinY(rightmostItem.frame));
                //update the rightmost item of this line
                [rightmostItems removeObject:rightmostItem];
            }else{
                //start on a new line
                itemOrigin = CGPointMake(CGRectGetMinX(boundingRect), CGRectGetMaxY(attributesForItems.lastObject.frame) + minimumLineSpacing);
                //beyond the max rect of the limit size
                if (itemOrigin.y + CGRectGetHeight(obj.frame) > CGRectGetMaxY(boundingRect)) {
                    return (void)(*stop = YES);
                }
            }
        }
        obj.frame = (CGRect){
            .origin = itemOrigin,
            .size   = {
                .width  = MIN(CGRectGetWidth(obj.frame), CGRectGetWidth(boundingRect)),
                .height = CGRectGetHeight(obj.frame)
            }
        };
        /*
         Default       ：Only keep the last item alaways
         ShortestFirst : Keep last items of every lines
         */
        if (policy == BLCollectionViewTagLayoutItemRenderDefault) {
            [rightmostItems removeAllObjects];
        }
        [rightmostItems addObject:obj];
        [attributesForItems addObject:obj];
    }];
    return attributesForItems.copy;
}
+ (NSArray *)sortedForFullFill:(NSArray<UICollectionViewLayoutAttributes *> *)attributes
                  boundingRect:(CGRect )boundingRect
            minimumLineSpacing:(CGFloat)minimumLineSpacing
       minimumInteritemSpacing:(CGFloat)minimumInteritemSpacing
{
    //sort by items width
    NSArray<UICollectionViewLayoutAttributes *> *attributesForItems = [attributes sortedArrayUsingComparator:^NSComparisonResult(UICollectionViewLayoutAttributes *obj1, UICollectionViewLayoutAttributes *obj2) {
        return CGRectGetWidth(obj1.frame) < CGRectGetWidth(obj2.frame);
    }];
    attributesForItems = nil;
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Not a valid implementation, unfinished" userInfo:nil];
}
@end

#pragma mark - UICollectionViewTagStyleLayout
#pragma mark -
@interface BLCollectionViewTagLayout ()

@property (nonatomic,strong) NSMutableArray<UICollectionViewTagStyleLayoutSectionAttributes *>  *sectionAttributes;
@property (nonatomic,strong) NSMutableArray<UICollectionViewTagStyleLayoutSectionAttributes *>  *originSectionAttributes;
@property (nonatomic,assign) BOOL  invalidatedForPinSectionHeaderFootersToVisibleBounds;
/*
 * Additional adjusted contentInset by system
 */
@property (nonatomic,assign) UIEdgeInsets  additionalAdjustedContentInset;
/*
 *
 * For additionalAdjustedContentInset customized
 *
 * If this property is not zeroed, the `additionalAdjustedContentInset` will be filled in with it's value.
 *
 */
@property (nonatomic,assign) UIEdgeInsets  systemAdditionalAdjustedContentInset;

//Convenience values for usage
@property (nonatomic,assign,readonly) NSInteger  zIndexForHeaderFooter;
@property (nonatomic,  weak,readonly) id<BLCollectionViewDelegateTagStyleLayout> delegate;

@end

@implementation BLCollectionViewTagLayout
#pragma mark - Initialization
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}
- (void)setup
{
    _itemSize                = CGSizeMake(50, 50);
    _minimumLineSpacing      = 10;
    _minimumInteritemSpacing = 10;
    _maximumSectionHeight    = CGFLOAT_MAX;
    _headerReferenceSize     = CGSizeZero;
    _footerReferenceSize     = CGSizeZero;
    _sectionInset            = UIEdgeInsetsZero;
    _scrollDirection         = UICollectionViewScrollDirectionVertical;
    _itemRenderPolicy        = BLCollectionViewTagLayoutItemRenderDefault;
    _sectionHeadersPinToVisibleBounds = NO;
    _sectionFootersPinToVisibleBounds = NO;
    _sectionDecorationVisiable        = NO;
    _invalidatedForPinSectionHeaderFootersToVisibleBounds = NO;
    _additionalAdjustedContentInset = UIEdgeInsetsZero;
}
- (void)registerNib:(UINib *)nib forDecorationViewOfKind:(NSString *)elementKind
{
    NSAssert([elementKind isEqualToString:BLCollectionElementKindSectionDecoration],@"Kind of %@ current unsupported",elementKind);
    if (![elementKind isEqualToString:BLCollectionElementKindSectionDecoration]) return;
    [super registerNib:nib forDecorationViewOfKind:elementKind];
}
- (void)registerClass:(Class)viewClass forDecorationViewOfKind:(NSString *)elementKind
{
    NSAssert([elementKind isEqualToString:BLCollectionElementKindSectionDecoration],@"Kind of %@ current unsupported",elementKind);
    if (![elementKind isEqualToString:BLCollectionElementKindSectionDecoration]) return;
    [super registerClass:viewClass forDecorationViewOfKind:elementKind];
}
- (void)invalidateLayoutWithContext:(UICollectionViewLayoutInvalidationContext *)context
{
    [super invalidateLayoutWithContext:context];
}
#pragma mark - Setter
- (void)setItemSize:(CGSize)itemSize
{
    if (CGSizeEqualToSize(_itemSize, itemSize)) return;
    _itemSize = itemSize;
    [self invalidateLayout];
}
- (void)setMinimumLineSpacing:(CGFloat)lineSpacing
{
    if (_minimumLineSpacing == lineSpacing) return;
    _minimumLineSpacing = lineSpacing;
    [self invalidateLayout];
}
- (void)setMinimumInteritemSpacing:(CGFloat)itemSpacing
{
    if (_minimumInteritemSpacing == itemSpacing) return;
    _minimumInteritemSpacing = itemSpacing;
    [self invalidateLayout];
}
- (void)setHeaderReferenceSize:(CGSize)headerReferenceSize
{
    if (CGSizeEqualToSize(_headerReferenceSize, headerReferenceSize)) return;
    _headerReferenceSize = headerReferenceSize;
    [self invalidateLayout];
}
- (void)setFooterReferenceSize:(CGSize)footerReferenceSize
{
    if (CGSizeEqualToSize(_footerReferenceSize, footerReferenceSize)) return;
    _footerReferenceSize = footerReferenceSize;
    [self invalidateLayout];
}
- (void)setSectionInset:(UIEdgeInsets)sectionInset
{
    if (UIEdgeInsetsEqualToEdgeInsets(_sectionInset, sectionInset)) return;
    _sectionInset = sectionInset;
    [self invalidateLayout];
}
- (void)setScrollDirection:(UICollectionViewScrollDirection)scrollDirection
{
    NSAssert(scrollDirection == UICollectionViewScrollDirectionVertical,
             @"Only UICollectionViewScrollDirectionVertical is supported .");
    if (_scrollDirection == scrollDirection) return;
    _scrollDirection = scrollDirection;
    [self invalidateLayout];
}
- (void)setItemRenderPolicy:(BLCollectionViewTagLayoutItemRenderPolicy)itemRenderPolicy
{
    NSAssert(itemRenderPolicy != BLCollectionViewTagLayoutItemRenderFullFill,
             @"BLCollectionViewTagLayoutItemRenderFullFill is unsupported .");
    if (_itemRenderPolicy == itemRenderPolicy) return;
    _itemRenderPolicy = itemRenderPolicy;
    [self invalidateLayout];
}
- (void)setSectionHeadersPinToVisibleBounds:(BOOL)sectionHeadersPinToVisibleBounds
{
    if (_sectionHeadersPinToVisibleBounds == sectionHeadersPinToVisibleBounds) return;
    _sectionHeadersPinToVisibleBounds = sectionHeadersPinToVisibleBounds;
    [self invalidateLayout];
}
- (void)setSectionFootersPinToVisibleBounds:(BOOL)sectionFootersPinToVisibleBounds
{
    if (_sectionFootersPinToVisibleBounds == sectionFootersPinToVisibleBounds) return;
    _sectionFootersPinToVisibleBounds = sectionFootersPinToVisibleBounds;
    [self invalidateLayout];
}
- (void)setSectionDecorationVisiable:(BOOL)sectionDecorationVisiable
{
    if (_sectionDecorationVisiable == sectionDecorationVisiable) return;
    _sectionDecorationVisiable = sectionDecorationVisiable;
    [self invalidateLayout];
}
#pragma mark -
- (id<BLCollectionViewDelegateTagStyleLayout>)delegate
{
    return (id<BLCollectionViewDelegateTagStyleLayout>)self.collectionView.delegate;
}
- (NSInteger)zIndexForHeaderFooter
{
    return 10;
}
#pragma mark -
- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect   )rect
                                                                 sectionAttributes:(NSArray *)sectionAttributes
{
    NSMutableArray<UICollectionViewLayoutAttributes *> *layoutAttributes = @[].mutableCopy;
    for (UICollectionViewTagStyleLayoutSectionAttributes *obj in sectionAttributes) {
        if (CGRectIntersectsRect(rect, obj.header.frame) && obj.header.frame.size.height > 0) {
            [layoutAttributes addObject:obj.header];
        }
        for (UICollectionViewLayoutAttributes *item in obj.items) {
            if (CGRectIntersectsRect(rect, item.frame) && item.frame.size.height > 0) {
                [layoutAttributes addObject:item];
            }
        }
        if (CGRectIntersectsRect(rect, obj.footer.frame) && obj.footer.frame.size.height > 0) {
            [layoutAttributes addObject:obj.footer];
        }
        if (self.sectionDecorationVisiable) {
            if (CGRectIntersectsRect(rect, obj.decoration.frame) && obj.decoration.frame.size.height > 0) {
                [layoutAttributes addObject:obj.decoration];
            }
        }
    }
    return layoutAttributes.copy;
}
#pragma mark -
- (void)setupLayoutAttributes
{
    self.originSectionAttributes = @[].mutableCopy;
    
    /*
     Similar as UICollectionViewFlowLayout
     headerAttributes.zIndex = 10 -> header.layer.zIndex = 1,// 10 ÷ 10 = 1
     footerAttributes.zIndex = 10 -> footer.layer.zIndex = 0,// ignored by system
     */
    CGFloat maxContentWidth = UIEdgeInsetsInsetRect(self.collectionView.bounds, self.collectionView.contentInset).size.width;
    
    CGFloat maxY = 0;
    for (NSInteger section = 0; section < self.collectionView.numberOfSections; section++) {
        //
        CGSize       headerReferenceSize     = self.headerReferenceSize;
        CGSize       footerReferenceSize     = self.footerReferenceSize;
        UIEdgeInsets sectionInset            = self.sectionInset;
        CGFloat      minimumInteritemSpacing = self.minimumInteritemSpacing;
        CGFloat      minimumLineSpacing      = self.minimumLineSpacing;
        
        if ([self.delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForHeaderInSection:)]) {
            headerReferenceSize = [self.delegate collectionView:self.collectionView layout:self referenceSizeForHeaderInSection:section];
        }
        if ([self.delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForFooterInSection:)]) {
            footerReferenceSize = [self.delegate collectionView:self.collectionView layout:self referenceSizeForFooterInSection:section];
        }
        if ([self.delegate respondsToSelector:@selector(collectionView:layout:insetForSection:)]) {
            sectionInset = [self.delegate collectionView:self.collectionView layout:self insetForSection:section];
        }
        if ([self.delegate respondsToSelector:@selector(collectionView:layout:minimumInteritemSpacingForSection:)]) {
            minimumInteritemSpacing = [self.delegate collectionView:self.collectionView layout:self minimumInteritemSpacingForSection:section];
        }
        if ([self.delegate respondsToSelector:@selector(collectionView:layout:minimumLineSpacingForSection:)]) {
            minimumLineSpacing = [self.delegate collectionView:self.collectionView layout:self minimumLineSpacingForSection:section];
        }
        
        NSIndexPath *indexPathForHeaderFooter = [NSIndexPath indexPathForItem:0 inSection:section];
        //section header
        UICollectionViewLayoutAttributes *attributesForHeader =
        [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:indexPathForHeaderFooter];
        attributesForHeader.frame = CGRectMake(0, maxY, maxContentWidth, headerReferenceSize.height);
        attributesForHeader.zIndex = self.zIndexForHeaderFooter;
        
        CGFloat maximumSectionHeight = self.maximumSectionHeight;
        if ([self.delegate respondsToSelector:@selector(collectionView:layout:maximumHeightForSection:)]) {
            maximumSectionHeight = [self.delegate collectionView:self.collectionView layout:self maximumHeightForSection:section];
        }
        CGRect boundingRectForItems = (CGRect){
            .origin = {
                .x = sectionInset.left,
                .y = CGRectGetMaxY(attributesForHeader.frame) + sectionInset.top
            },
            .size = {
                .width = maxContentWidth - sectionInset.left - sectionInset.right,
                .height = maximumSectionHeight
            }
        };
        NSArray<UICollectionViewLayoutAttributes *> *sortedAttributesForItems = nil;
        if (_itemRenderPolicy == BLCollectionViewTagLayoutItemRenderCustom) {
            NSAssert([self.delegate respondsToSelector:@selector(collectionView:layout:attributesInSection:boundingRect:)], @"You must implement `-[BLCollectionViewDelegateTagStyleLayout collectionView:layout:attributesInSection:boundingRect:]` if you prefer a custom layout item render policy");
            sortedAttributesForItems = [self.delegate collectionView:self.collectionView layout:self attributesInSection:section boundingRect:boundingRectForItems];
        }else{
            //items
            NSMutableArray<UICollectionViewLayoutAttributes *> *attributesForItems = @[].mutableCopy;
            for (NSInteger item = 0; item < [self.collectionView numberOfItemsInSection:section]; item++) {
                NSIndexPath *indexPathForItem = [NSIndexPath indexPathForItem:item inSection:section];
                CGSize itemSize = self.itemSize;
                if ([self.delegate respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)]) {
                    itemSize = [self.delegate collectionView:self.collectionView layout:self sizeForItemAtIndexPath:indexPathForItem];
                }
                itemSize.width = MIN(itemSize.width, CGRectGetWidth(boundingRectForItems));
                UICollectionViewLayoutAttributes *attributesForItem = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPathForItem];
                attributesForItem.size = itemSize;
                [attributesForItems addObject:attributesForItem];
            }
            sortedAttributesForItems =
            [UICollectionViewTagStyleLayoutSectionItemSorter sorted:attributesForItems
                                                        usingPolicy:_itemRenderPolicy
                                                       boundingRect:boundingRectForItems
                                                 minimumLineSpacing:minimumLineSpacing
                                            minimumInteritemSpacing:minimumInteritemSpacing];
        }
        
        //section footer
        if (sortedAttributesForItems.count > 0) {
            maxY = CGRectGetMaxY(sortedAttributesForItems.lastObject.frame) + sectionInset.bottom;
        }else{
            maxY = CGRectGetMaxY(attributesForHeader.frame);
        }
        
        UICollectionViewLayoutAttributes *attributesForFooter = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter withIndexPath:indexPathForHeaderFooter];
        attributesForFooter.frame = CGRectMake(0, maxY, maxContentWidth, footerReferenceSize.height);
        attributesForFooter.zIndex = self.zIndexForHeaderFooter;
        
        //section decoration
        UICollectionViewLayoutAttributes *attrubuteForDecoration = [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:BLCollectionElementKindSectionDecoration withIndexPath:indexPathForHeaderFooter];
        attrubuteForDecoration.frame = CGRectMake(-sectionInset.left, CGRectGetMinY(attributesForHeader.frame), maxContentWidth + sectionInset.left + sectionInset.right, CGRectGetMaxY(attributesForFooter.frame) - CGRectGetMinY(attributesForHeader.frame));
        attrubuteForDecoration.zIndex = -self.zIndexForHeaderFooter;
        
        //
        [self.originSectionAttributes addObject:[UICollectionViewTagStyleLayoutSectionAttributes layoutAttributesWithHeader:attributesForHeader items:sortedAttributesForItems footer:attributesForFooter decoration:attrubuteForDecoration]];
        
        maxY = CGRectGetMaxY(attributesForFooter.frame);
    }
    self.sectionAttributes = self.originSectionAttributes;
    [self updateAttributesForPinSectionHeaderFootersToVisibleBounds:self.collectionView.bounds];
}
- (void)updateAttributesForPinSectionHeaderFootersToVisibleBounds:(CGRect)newBounds
{
    if (self.originSectionAttributes.count == 0) return;
    if (!self.sectionHeadersPinToVisibleBounds && !self.sectionFootersPinToVisibleBounds) return;
    
    CGFloat topOffset = self.additionalAdjustedContentInset.top;
    CGFloat bottomOffset = self.additionalAdjustedContentInset.bottom;
    
    //For recover from pin state， the equal (=) condition is required
    
    //pin header : contentOffset > topOffset
    BOOL sectionHeadersShouldPinToVisibleBounds = self.sectionHeadersPinToVisibleBounds && self.collectionView.contentOffset.y >= -topOffset;
    //pin footer : contentOffset < contentSize.height - collectionView.height
    BOOL sectionFootersShouldPinToVisibleBounds = self.sectionFootersPinToVisibleBounds && self.collectionView.contentOffset.y <= self.collectionViewContentSize.height - CGRectGetHeight(self.collectionView.bounds) + bottomOffset;
    
    if (!sectionHeadersShouldPinToVisibleBounds && !sectionFootersShouldPinToVisibleBounds) return;
    CGRect visibleRectForPinHeaderFooter = newBounds;
    visibleRectForPinHeaderFooter.origin.y += topOffset;
    visibleRectForPinHeaderFooter.size.height -= topOffset;
    visibleRectForPinHeaderFooter.size.height -= bottomOffset;
    if (self.collectionViewContentSize.height <= CGRectGetHeight(visibleRectForPinHeaderFooter)) {
        //does no need to pin header or footer to visible bounds any more.
        return;
    }
    // copy items
    self.sectionAttributes = [[NSMutableArray alloc] initWithArray:self.originSectionAttributes copyItems:YES];
    NSArray<UICollectionViewLayoutAttributes *> *attributes = [self layoutAttributesForElementsInRect:visibleRectForPinHeaderFooter sectionAttributes:self.originSectionAttributes];
    if (sectionHeadersShouldPinToVisibleBounds) {
        UICollectionViewLayoutAttributes *header =
        [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                             atIndexPath:attributes.firstObject.indexPath];
        CGRect frame = header.frame;
        frame.origin.y = CGRectGetMinY(visibleRectForPinHeaderFooter);
        // header.boottom <= footer.top
        UICollectionViewLayoutAttributes *footer =
        [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                             atIndexPath:header.indexPath];
        frame.origin.y = MIN(frame.origin.y, CGRectGetMinY(footer.frame) - CGRectGetHeight(header.frame));
        frame.origin.y = MAX(0, frame.origin.y);
        header.frame = frame;
    }
    if(sectionFootersShouldPinToVisibleBounds){
        UICollectionViewLayoutAttributes *footer =
        [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                             atIndexPath:attributes.lastObject.indexPath];
        CGRect frame = footer.frame;
        frame.origin.y = CGRectGetMaxY(visibleRectForPinHeaderFooter) - CGRectGetHeight(footer.frame);
        UICollectionViewLayoutAttributes *header =
        [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                             atIndexPath:footer.indexPath];
        // footer.top >= header.bottom
        frame.origin.y = MAX(frame.origin.y, CGRectGetMaxY(header.frame));
        footer.frame = frame;
    }
}
@end

@implementation BLCollectionViewTagLayout (UISubclassingHooks)
- (void)prepareLayout
{
    [super prepareLayout];
    
    if (@available(iOS 11.0, *)) {
        self.additionalAdjustedContentInset = (UIEdgeInsets){
            .top = self.collectionView.adjustedContentInset.top - self.collectionView.contentInset.top,
            .left = 0,
            .bottom = self.collectionView.adjustedContentInset.bottom - self.collectionView.contentInset.bottom,
            .right = 0
        };
    }else{
        if (UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsetsZero, self.systemAdditionalAdjustedContentInset)) {
            self.additionalAdjustedContentInset = self.collectionView.scrollIndicatorInsets;
        }else{
            self.additionalAdjustedContentInset = self.systemAdditionalAdjustedContentInset;
        }
    }
    
    if (self.invalidatedForPinSectionHeaderFootersToVisibleBounds){
        self.invalidatedForPinSectionHeaderFootersToVisibleBounds = NO;
        return;
    }
    [self setupLayoutAttributes];
}
- (CGSize)collectionViewContentSize
{
    /*
     * For UIScrollView, content inset doesn't affect it's content size
     *
     * Similar as UICollectionViewFlowLayout, the area for content doesn‘t contains
     * contentInset.left and content inset.right, to prevent scrollView horizontal scrolling
     *
     */
    return (CGSize){
        .width  = CGRectGetWidth(UIEdgeInsetsInsetRect(self.collectionView.bounds, self.collectionView.contentInset)),
        .height = CGRectGetMaxY(self.originSectionAttributes.lastObject.footer.frame)
    };
}
- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    return [self layoutAttributesForElementsInRect:rect sectionAttributes:self.sectionAttributes];
}
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section >= self.sectionAttributes.count) return nil;
    NSArray<UICollectionViewLayoutAttributes *> *items = self.sectionAttributes[indexPath.section].items;
    if (indexPath.item >= items.count) return nil;
    return items[indexPath.item];
}
- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section >= self.sectionAttributes.count) return nil;
    UICollectionViewTagStyleLayoutSectionAttributes *sectionAttributes = self.sectionAttributes[indexPath.section];
    if (elementKind == UICollectionElementKindSectionHeader) {
        return sectionAttributes.header;
    }else if (elementKind == UICollectionElementKindSectionFooter){
        return sectionAttributes.footer;
    }else{
        NSAssert(NO, @"The kind of %@ for supplementaryView is unsupported",elementKind);
        return nil;
    }
}
- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString*)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section >= self.sectionAttributes.count) return nil;
    UICollectionViewTagStyleLayoutSectionAttributes *sectionAttributes = self.sectionAttributes[indexPath.section];
    if (elementKind == BLCollectionElementKindSectionDecoration) {
        return sectionAttributes.decoration;
    }else{
        return [super layoutAttributesForDecorationViewOfKind:elementKind atIndexPath:indexPath];
    }
}
#pragma mark -
- (UICollectionViewLayoutInvalidationContext *)invalidationContextForBoundsChange:(CGRect)newBounds
{
    return [super invalidationContextForBoundsChange:newBounds];
}

- (BOOL)shouldInvalidateLayoutForPreferredLayoutAttributes:(UICollectionViewLayoutAttributes *)preferredAttributes withOriginalAttributes:(UICollectionViewLayoutAttributes *)originalAttributes
{
    return [super shouldInvalidateLayoutForPreferredLayoutAttributes:preferredAttributes withOriginalAttributes:originalAttributes];
}
- (UICollectionViewLayoutInvalidationContext *)invalidationContextForPreferredLayoutAttributes:(UICollectionViewLayoutAttributes *)preferredAttributes withOriginalAttributes:(UICollectionViewLayoutAttributes *)originalAttributes
{
    return [super invalidationContextForPreferredLayoutAttributes:preferredAttributes withOriginalAttributes:originalAttributes];
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    return [super targetContentOffsetForProposedContentOffset:proposedContentOffset withScrollingVelocity:velocity];
}
- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
{
    return [super targetContentOffsetForProposedContentOffset:proposedContentOffset];
}
#pragma mark - Settings
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    if (!CGSizeEqualToSize(self.collectionView.bounds.size, newBounds.size)) return YES;
    if (self.sectionHeadersPinToVisibleBounds || self.sectionFootersPinToVisibleBounds) {
        self.invalidatedForPinSectionHeaderFootersToVisibleBounds = YES;
        [self updateAttributesForPinSectionHeaderFootersToVisibleBounds:newBounds];
        return YES;
    }
    return NO;
}
- (UIUserInterfaceLayoutDirection)developmentLayoutDirection
{
    return super.developmentLayoutDirection;
}
- (BOOL)flipsHorizontallyInOppositeLayoutDirection
{
    return super.flipsHorizontallyInOppositeLayoutDirection;
}
@end


@implementation BLCollectionViewTagLayout (UICollectionViewContentInsetAdjustment)

- (void)autoConfigSystemAdditionalAdjustedContentInsetWith:(CGRect)statusBarFrame
                                             navigationBar:(UINavigationBar *)navigationBar
                                                    tabbar:(UITabBar *)tabbar
{
    self.systemAdditionalAdjustedContentInset = (UIEdgeInsets){
        .top = navigationBar.isTranslucent ? CGRectGetHeight(statusBarFrame) + CGRectGetHeight(navigationBar.frame) : 0,
        .left = 0,
        .bottom = tabbar.isTranslucent ? CGRectGetHeight(tabbar.frame) : 0,
        .right = 0
    };
}
@end

#pragma mark - IBDESIGNABLE
#pragma mark -
@interface BLCollectionViewTagLayout (IBDESIGNABLE)
@property (nonatomic) IBInspectable CGFloat   lineSpacing;
@property (nonatomic) IBInspectable CGFloat   itemSpacing;
@property (nonatomic) IBInspectable CGFloat   sectionHeight;
@property (nonatomic) IBInspectable CGFloat   sectionTop;
@property (nonatomic) IBInspectable CGFloat   sectionLeft;
@property (nonatomic) IBInspectable CGFloat   sectionBottom;
@property (nonatomic) IBInspectable CGFloat   sectionRight;
@property (nonatomic) IBInspectable CGSize    headerSize;
@property (nonatomic) IBInspectable CGSize    footerSize;
@property (nonatomic) IBInspectable BOOL      pinHeaders;
@property (nonatomic) IBInspectable BOOL      pinFooters;
@property (nonatomic) IBInspectable BOOL      useDecoration;
@end

@implementation BLCollectionViewTagLayout (IBDESIGNABLE)
- (void)setSectionTop:(CGFloat)sectionTop
{
    UIEdgeInsets sectionInset = self.sectionInset;
    sectionInset.top = sectionTop;
    self.sectionInset = sectionInset;
}
- (CGFloat)sectionTop
{
    return self.sectionInset.top;
}
- (void)setSectionLeft:(CGFloat)sectionLeft
{
    UIEdgeInsets sectionInset = self.sectionInset;
    sectionInset.left = sectionLeft;
    self.sectionInset = sectionInset;
}
- (CGFloat)sectionLeft
{
    return self.sectionInset.left;
}
- (void)setSectionBottom:(CGFloat)sectionBottom
{
    UIEdgeInsets sectionInset = self.sectionInset;
    sectionInset.bottom = sectionBottom;
    self.sectionInset = sectionInset;
}
- (CGFloat)sectionBottom
{
    return self.sectionInset.bottom;
}
- (void)setSectionRight:(CGFloat)sectionRight
{
    UIEdgeInsets sectionInset = self.sectionInset;
    sectionInset.right = sectionRight;
    self.sectionInset = sectionInset;
}
- (CGFloat)sectionRight
{
    return self.sectionInset.right;
}
- (void)setLineSpacing:(CGFloat)lineSpacing
{
    self.minimumLineSpacing = lineSpacing;
}
- (CGFloat)lineSpacing
{
    return self.minimumLineSpacing;
}
- (void)setItemSpacing:(CGFloat)itemSpacing
{
    self.minimumInteritemSpacing = itemSpacing;
}
- (CGFloat)itemSpacing
{
    return self.minimumInteritemSpacing;
}
- (void)setSectionHeight:(CGFloat)sectionHeight
{
    self.maximumSectionHeight = sectionHeight;
}
- (CGFloat)sectionHeight
{
    return self.maximumSectionHeight;
}
- (void)setHeaderSize:(CGSize)headerSize
{
    self.headerReferenceSize = headerSize;
}
- (CGSize)headerSize
{
    return self.headerReferenceSize;
}
- (void)setFooterSize:(CGSize)footerSize
{
    self.footerReferenceSize = footerSize;
}
- (CGSize)footerSize
{
    return self.footerReferenceSize;
}
- (void)setPinHeaders:(BOOL)pinHeaders
{
    self.sectionHeadersPinToVisibleBounds = pinHeaders;
}
- (BOOL)pinHeaders
{
    return self.sectionHeadersPinToVisibleBounds;
}
- (void)setPinFooters:(BOOL)pinFooters
{
    self.sectionFootersPinToVisibleBounds = pinFooters;
}
- (BOOL)pinFooters
{
    return self.sectionFootersPinToVisibleBounds;
}
- (void)setUseDecoration:(BOOL)useDecoration
{
    self.sectionDecorationVisiable = useDecoration;
}
- (BOOL)useDecoration
{
    return self.sectionDecorationVisiable;;
}
- (void)setRenderType:(NSInteger)renderType
{
    self.itemRenderPolicy = renderType;
}
- (NSInteger)renderType
{
    return self.itemRenderPolicy;
}
@end


#pragma mark - UIUpdateSupportHooks
#pragma mark -
@implementation BLCollectionViewTagLayout (UIUpdateSupportHooks)
- (void)prepareForCollectionViewUpdates:(NSArray<UICollectionViewUpdateItem *> *)updateItems
{
    /*
     * bugfix: The app may crash when there are no items but supplmementary views in the section.
     */
    @try {
        [super prepareForCollectionViewUpdates:updateItems];
    } @catch (NSException *exception) {
#if DEBUG
        NSLog(@"%@",exception);
#endif
    } @finally {
        
    }
}
- (void)finalizeCollectionViewUpdates
{
    [super finalizeCollectionViewUpdates];
}
- (void)prepareForAnimatedBoundsChange:(CGRect)oldBounds
{
    [super prepareForAnimatedBoundsChange:oldBounds];
}
- (void)finalizeAnimatedBoundsChange
{
    [super finalizeAnimatedBoundsChange];
}
- (void)prepareForTransitionFromLayout:(UICollectionViewLayout *)oldLayout
{
    [super prepareForTransitionFromLayout:oldLayout];
}
- (void)prepareForTransitionToLayout:(UICollectionViewLayout *)newLayout
{
    [super prepareForTransitionToLayout:newLayout];
}
- (void)finalizeLayoutTransition
{
    [super finalizeLayoutTransition];
}

/*
 * These method will be called after  `prepareForCollectionViewUpdates` and
 * before `finalizeCollectionViewUpdates`
 *
 * The attributes of `initialLayoutAttributesForAppearingXXX` will be used as the animation fromValue
 *
 * The attributes of `finalLayoutAttributesForDisappearingXXX` will be used as the animation toValue
 *
 */
- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    if (self.elementAppearingAnimationFromValue) {
        self.elementAppearingAnimationFromValue(itemIndexPath,
                                                nil,
                                                UICollectionElementCategoryCell);
    }
    return [super initialLayoutAttributesForAppearingItemAtIndexPath:itemIndexPath];
}
- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    if (self.elementDisappearingAnimationToValue) {
        self.elementDisappearingAnimationToValue(itemIndexPath,
                                                 nil,
                                                 UICollectionElementCategoryCell);
    }
    return [super finalLayoutAttributesForDisappearingItemAtIndexPath:itemIndexPath];
}
- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingSupplementaryElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)elementIndexPath
{
    if (self.elementAppearingAnimationFromValue) {
        self.elementAppearingAnimationFromValue(elementIndexPath,
                                                elementKind,
                                                UICollectionElementCategorySupplementaryView);
    }
    return [super initialLayoutAttributesForAppearingSupplementaryElementOfKind:elementKind atIndexPath:elementIndexPath];
}
- (nullable UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingSupplementaryElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)elementIndexPath
{
    if (self.elementDisappearingAnimationToValue) {
        self.elementDisappearingAnimationToValue(elementIndexPath,
                                                 elementKind,
                                                 UICollectionElementCategorySupplementaryView);
    }
    return [super finalLayoutAttributesForDisappearingSupplementaryElementOfKind:elementKind atIndexPath:elementIndexPath];
}
- (nullable UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingDecorationElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)decorationIndexPath
{
    if (self.elementAppearingAnimationFromValue) {
        self.elementAppearingAnimationFromValue(decorationIndexPath,
                                                elementKind,
                                                UICollectionElementCategoryDecorationView);
    }
    return [super initialLayoutAttributesForAppearingDecorationElementOfKind:elementKind atIndexPath:decorationIndexPath];
}
- (nullable UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingDecorationElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)decorationIndexPath
{
    if (self.elementDisappearingAnimationToValue) {
        self.elementDisappearingAnimationToValue(decorationIndexPath,
                                                 elementKind,
                                                 UICollectionElementCategoryDecorationView);
    }
    return [super finalLayoutAttributesForDisappearingDecorationElementOfKind:elementKind atIndexPath:decorationIndexPath];
}


// These methods are called by collection view during an update block.
// Return an array of index paths to indicate views that the layout is deleting or inserting in response to the update.
- (NSArray<NSIndexPath *> *)indexPathsToDeleteForSupplementaryViewOfKind:(NSString *)elementKind
{
    return [super indexPathsToDeleteForSupplementaryViewOfKind:elementKind];
}
- (NSArray<NSIndexPath *> *)indexPathsToDeleteForDecorationViewOfKind:(NSString *)elementKind
{
    return [super indexPathsToDeleteForDecorationViewOfKind:elementKind];
}
- (NSArray<NSIndexPath *> *)indexPathsToInsertForSupplementaryViewOfKind:(NSString *)elementKind
{
    return [super indexPathsToInsertForSupplementaryViewOfKind:elementKind];
}
- (NSArray<NSIndexPath *> *)indexPathsToInsertForDecorationViewOfKind:(NSString *)elementKind
{
    return [super indexPathsToInsertForDecorationViewOfKind:elementKind];
}
@end

#pragma mark - UIReorderingSupportHooks
#pragma mark -
@implementation BLCollectionViewTagLayout (UIReorderingSupportHooks)

- (NSIndexPath *)targetIndexPathForInteractivelyMovingItem:(NSIndexPath *)previousIndexPath withPosition:(CGPoint)position
{
    return [super targetIndexPathForInteractivelyMovingItem:previousIndexPath withPosition:position];
}
- (UICollectionViewLayoutAttributes *)layoutAttributesForInteractivelyMovingItemAtIndexPath:(NSIndexPath *)indexPath withTargetPosition:(CGPoint)position
{
    return [super layoutAttributesForInteractivelyMovingItemAtIndexPath:indexPath withTargetPosition:position];
}

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForInteractivelyMovingItems:(NSArray<NSIndexPath *> *)targetIndexPaths withTargetPosition:(CGPoint)targetPosition previousIndexPaths:(NSArray<NSIndexPath *> *)previousIndexPaths previousPosition:(CGPoint)previousPosition
{
    return [super invalidationContextForInteractivelyMovingItems:targetIndexPaths
                                              withTargetPosition:targetPosition previousIndexPaths:previousIndexPaths previousPosition:previousPosition];
}
- (UICollectionViewLayoutInvalidationContext *)invalidationContextForEndingInteractiveMovementOfItemsToFinalIndexPaths:(NSArray<NSIndexPath *> *)indexPaths previousIndexPaths:(NSArray<NSIndexPath *> *)previousIndexPaths movementCancelled:(BOOL)movementCancelled
{
    return [super invalidationContextForEndingInteractiveMovementOfItemsToFinalIndexPaths:indexPaths previousIndexPaths:previousIndexPaths movementCancelled:movementCancelled];
}

@end
