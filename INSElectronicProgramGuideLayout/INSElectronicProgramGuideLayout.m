//
//  INSElectronicProgramGuideLayout.m
//  INSElectronicProgramGuideLayout
//
//  Created by Michał Zaborowski on 29.09.2014.
//  Copyright (c) 2014 inspace.io. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "INSElectronicProgramGuideLayout.h"
#import "INSTimerWeakTarget.h"

NSString *const INSEPGLayoutElementKindSectionHeader = @"INSEPGLayoutElementKindSectionHeader";
NSString *const INSEPGLayoutElementKindHourHeader = @"INSEPGLayoutElementKindHourHeader";
NSString *const INSEPGLayoutElementKindHalfHourHeader = @"INSEPGLayoutElementKindHalfHourHeader";
NSString *const INSEPGLayoutElementKindSectionHeaderBackground = @"INSEPGLayoutElementKindSectionHeaderBackground";
NSString *const INSEPGLayoutElementKindHourHeaderBackground = @"INSEPGLayoutElementKindHourHeaderBackground";
NSString *const INSEPGLayoutElementKindCurrentTimeIndicator = @"INSEPGLayoutElementKindCurrentTimeIndicator";
NSString *const INSEPGLayoutElementKindCurrentTimeIndicatorVerticalGridline = @"INSEPGLayoutElementKindCurrentTimeIndicatorVerticalGridline";

NSUInteger const INSEPGLayoutMinOverlayZ = 1000.0; // Allows for 900 items in a section without z overlap issues
NSUInteger const INSEPGLayoutMinCellZ = 100.0;  // Allows for 100 items in a section's background
NSUInteger const INSEPGLayoutMinBackgroundZ = 0.0;

@interface INSElectronicProgramGuideLayout ()
@property (nonatomic, strong) NSTimer *minuteTimer;
@property (nonatomic, readonly) CGFloat minuteWidth;

// Cache
@property (nonatomic, assign) BOOL needsToPopulateAttributesForAllSections;

@property (nonatomic, strong) NSDate *cachedEarliestDate;
@property (nonatomic, strong) NSDate *cachedLatestDate;
@property (nonatomic, strong) NSDate *cachedCurrentDate;

@property (nonatomic, strong) NSMutableDictionary *cachedEarliestDates;
@property (nonatomic, strong) NSMutableDictionary *cachedLatestDates;

@property (nonatomic, strong) NSCache *cachedHours;
@property (nonatomic, strong) NSCache *cachedHalfHours;

@property (nonatomic, strong) NSCache *cachedStartTimeDate;
@property (nonatomic, strong) NSCache *cachedEndTimeDate;
@property (nonatomic, assign) CGFloat cachedMaxSectionWidth;

// Registered Decoration Classes
@property (nonatomic, strong) NSMutableDictionary *registeredDecorationClasses;

// Attributes
@property (nonatomic, strong) NSMutableArray *allAttributes;
@property (nonatomic, strong) NSMutableDictionary *itemAttributes;
@property (nonatomic, strong) NSMutableDictionary *sectionHeaderAttributes;
@property (nonatomic, strong) NSMutableDictionary *sectionHeaderBackgroundAttributes;
@property (nonatomic, strong) NSMutableDictionary *hourHeaderAttributes;
@property (nonatomic, strong) NSMutableDictionary *halfHourHeaderAttributes;
@property (nonatomic, strong) NSMutableDictionary *hourHeaderBackgroundAttributes;
@property (nonatomic, strong) NSMutableDictionary *verticalGridlineAttributes;
@property (nonatomic, strong) NSMutableDictionary *verticalHalfHourGridlineAttributes;
@property (nonatomic, strong) NSMutableDictionary *currentTimeIndicatorAttributes;
@property (nonatomic, strong) NSMutableDictionary *currentTimeVerticalGridlineAttributes;
@end

@implementation INSElectronicProgramGuideLayout

#pragma mark - <INSElectronicProgramGuideLayoutDataSource>

- (id <INSElectronicProgramGuideLayoutDataSource>)dataSource
{
    return (id <INSElectronicProgramGuideLayoutDataSource>)self.collectionView.dataSource;
}

- (void)setDataSource:(id<INSElectronicProgramGuideLayoutDataSource>)dataSource
{
    self.collectionView.dataSource = dataSource;
}

#pragma mark - Getters

- (CGFloat)minuteWidth
{
    return self.hourWidth / 60.0;
}

#pragma mark - NSObject

- (void)dealloc
{
    [self invalidateLayoutCache];
    [self.minuteTimer invalidate];
    self.minuteTimer = nil;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.needsToPopulateAttributesForAllSections = YES;

    self.cachedStartTimeDate = [NSCache new];
    self.cachedEndTimeDate = [NSCache new];
    self.cachedHours = [NSCache new];
    self.cachedHalfHours = [NSCache new];
    self.cachedMaxSectionWidth = CGFLOAT_MIN;

    self.registeredDecorationClasses = [NSMutableDictionary new];

    self.allAttributes = [NSMutableArray new];
    self.itemAttributes = [NSMutableDictionary new];
    self.sectionHeaderAttributes = [NSMutableDictionary new];
    self.sectionHeaderBackgroundAttributes = [NSMutableDictionary new];
    self.hourHeaderAttributes = [NSMutableDictionary new];
    self.halfHourHeaderAttributes = [NSMutableDictionary new];
    self.hourHeaderBackgroundAttributes = [NSMutableDictionary new];
    self.verticalGridlineAttributes = [NSMutableDictionary new];
    self.currentTimeIndicatorAttributes = [NSMutableDictionary new];
    self.currentTimeVerticalGridlineAttributes = [NSMutableDictionary new];
    self.verticalHalfHourGridlineAttributes = [NSMutableDictionary new];

    self.contentMargin = UIEdgeInsetsMake(0, 0, 0, 0);
    self.cellMargin = UIEdgeInsetsMake(0, 0, 0, 5);
    self.sectionHeight = 60;
    self.sectionHeaderWidth = 50;
    self.hourHeaderHeight = 50;
    self.hourWidth = 300;
    self.currentTimeIndicatorSize = CGSizeMake(self.sectionHeaderWidth, 10.0);
    self.currentTimeVerticalGridlineWidth = 1.0;
    self.sectionGap = 5;

    // Set CurrentTime Behind cell
    self.currentTimeIndicatorShouldBeBehind = NO;

    // Invalidate layout on minute ticks (to update the position of the current time indicator)
    NSDate *oneMinuteInFuture = [[NSDate date] dateByAddingTimeInterval:60];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:oneMinuteInFuture];
    NSDate *nextMinuteBoundary = [[NSCalendar currentCalendar] dateFromComponents:components];

    // This needs to be a weak reference, otherwise we get a retain cycle
    INSTimerWeakTarget *timerWeakTarget = [[INSTimerWeakTarget alloc] initWithTarget:self selector:@selector(minuteTick:)];
    self.minuteTimer = [[NSTimer alloc] initWithFireDate:nextMinuteBoundary interval:60 target:timerWeakTarget selector:timerWeakTarget.fireSelector userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.minuteTimer forMode:NSDefaultRunLoopMode];
}

#pragma mark - Public

- (NSDate *)dateForHourHeaderAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.cachedHours objectForKey:indexPath];
}

- (NSDate *)dateForHalfHourHeaderAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.cachedHalfHours objectForKey:indexPath];
}

- (void)scrollToCurrentTimeAnimated:(BOOL)animated
{
    if (self.collectionView.numberOfSections > 0) {
        CGRect currentTimeHorizontalGridlineattributesFrame = [self.currentTimeVerticalGridlineAttributes[[NSIndexPath indexPathForItem:0 inSection:0]] frame];
        CGFloat xOffset;
        if (!CGRectEqualToRect(currentTimeHorizontalGridlineattributesFrame, CGRectZero)) {
            xOffset = nearbyintf(CGRectGetMinX(currentTimeHorizontalGridlineattributesFrame) - (CGRectGetWidth(self.collectionView.frame) / 2.0));
        } else {
            xOffset = 0.0;
        }
        CGPoint contentOffset = CGPointMake(xOffset, self.collectionView.contentOffset.y - self.collectionView.contentInset.top);

        // Prevent the content offset from forcing the scroll view content off its bounds
        if (contentOffset.y > (self.collectionView.contentSize.height - self.collectionView.frame.size.height)) {
            contentOffset.y = (self.collectionView.contentSize.height - self.collectionView.frame.size.height);
        }
        if (contentOffset.y < -self.collectionView.contentInset.top) {
            contentOffset.y = -self.collectionView.contentInset.top;
        }
        if (contentOffset.x > (self.collectionView.contentSize.width - self.collectionView.frame.size.width)) {
            contentOffset.x = (self.collectionView.contentSize.width - self.collectionView.frame.size.width);
        }
        if (contentOffset.x < 0.0) {
            contentOffset.x = 0.0;
        }

        [self.collectionView setContentOffset:contentOffset animated:animated];
    }
}

- (void)invalidateLayoutCache
{
    self.needsToPopulateAttributesForAllSections = YES;

    // Invalidate cached Components
    self.cachedEarliestDate = nil;
    self.cachedLatestDate = nil;
    self.cachedCurrentDate = nil;

    [self.cachedEarliestDates removeAllObjects];
    [self.cachedLatestDates removeAllObjects];


    [self.cachedHours removeAllObjects];
    [self.cachedHalfHours removeAllObjects];

    [self.cachedStartTimeDate removeAllObjects];
    [self.cachedEndTimeDate removeAllObjects];
    self.cachedMaxSectionWidth = CGFLOAT_MIN;

    [self.verticalGridlineAttributes removeAllObjects];
    [self.itemAttributes removeAllObjects];
    [self.sectionHeaderAttributes removeAllObjects];
    [self.sectionHeaderBackgroundAttributes removeAllObjects];
    [self.hourHeaderAttributes removeAllObjects];
    [self.halfHourHeaderAttributes removeAllObjects];
    [self.hourHeaderBackgroundAttributes removeAllObjects];
    [self.currentTimeIndicatorAttributes removeAllObjects];
    [self.currentTimeVerticalGridlineAttributes removeAllObjects];
    [self.verticalHalfHourGridlineAttributes removeAllObjects];
    [self.allAttributes removeAllObjects];
}


#pragma mark Minute Updates

- (void)minuteTick:(id)sender
{
    // Invalidate cached current date componets (since the minute's changed!)
    self.cachedCurrentDate = nil;
    [self invalidateLayout];
}

#pragma mark - UICollectionViewLayout


- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewAtIndexPath:(NSIndexPath *)indexPath ofKind:(NSString *)kind withItemCache:(NSMutableDictionary *)itemCache
{
    NSIndexPath *indexPathKey = [self keyForIndexPath:indexPath];
    UICollectionViewLayoutAttributes *layoutAttributes;
    if (self.registeredDecorationClasses[kind] && !(layoutAttributes = itemCache[indexPathKey])) {
        layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:kind withIndexPath:indexPathKey];
        itemCache[indexPathKey] = layoutAttributes;
    }
    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewAtIndexPath:(NSIndexPath *)indexPath ofKind:(NSString *)kind withItemCache:(NSMutableDictionary *)itemCache
{
    NSIndexPath *indexPathKey = [self keyForIndexPath:indexPath];
    UICollectionViewLayoutAttributes *layoutAttributes;
    if (!(layoutAttributes = itemCache[indexPathKey])) {
        layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:kind withIndexPath:indexPathKey];
        itemCache[indexPathKey] = layoutAttributes;
    }
    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForCellAtIndexPath:(NSIndexPath *)indexPath withItemCache:(NSMutableDictionary *)itemCache
{
    NSIndexPath *indexPathKey = [self keyForIndexPath:indexPath];
    UICollectionViewLayoutAttributes *layoutAttributes;
    if (!(layoutAttributes = itemCache[indexPathKey])) {
        layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPathKey];
        itemCache[indexPathKey] = layoutAttributes;
    }
    return layoutAttributes;
}

- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems
{
    [self invalidateLayoutCache];

    // Update the layout with the new items
    [self prepareLayout];

    [super prepareForCollectionViewUpdates:updateItems];
}

- (void)finalizeCollectionViewUpdates
{
    // This is a hack to prevent the error detailed in :
    // http://stackoverflow.com/questions/12857301/uicollectionview-decoration-and-supplementary-views-can-not-be-moved
    // If this doesn't happen, whenever the collection view has batch updates performed on it, we get multiple instantiations of decoration classes
    for (UIView *subview in self.collectionView.subviews) {
        for (Class decorationViewClass in self.registeredDecorationClasses.allValues) {
            if ([subview isKindOfClass:decorationViewClass]) {
                [subview removeFromSuperview];
            }
        }
    }
    [self.collectionView reloadData];
}

- (void)registerClass:(Class)viewClass forDecorationViewOfKind:(NSString *)decorationViewKind
{
    [super registerClass:viewClass forDecorationViewOfKind:decorationViewKind];
    self.registeredDecorationClasses[decorationViewKind] = viewClass;
}

- (void)registerNib:(UINib *)nib forDecorationViewOfKind:(NSString *)elementKind
{
    [super registerNib:nib forDecorationViewOfKind:elementKind];

    NSArray *topLevelObjects = [nib instantiateWithOwner:nil options:nil];

    NSAssert(topLevelObjects.count == 1 && [[topLevelObjects firstObject] isKindOfClass:UICollectionReusableView.class], @"must contain exactly 1 top level object which is a UICollectionReusableView");

    self.registeredDecorationClasses[elementKind] = [[topLevelObjects firstObject] class];
}

- (void)prepareLayout
{
    [super prepareLayout];

    if (self.needsToPopulateAttributesForAllSections) {
        [self prepareSectionLayoutForSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.collectionView.numberOfSections)]];
        self.needsToPopulateAttributesForAllSections = NO;
    }

    BOOL needsToPopulateAllAttribtues = (self.allAttributes.count == 0);
    if (needsToPopulateAllAttribtues) {
        [self.allAttributes addObjectsFromArray:[self.itemAttributes allValues]];
        [self.allAttributes addObjectsFromArray:[self.sectionHeaderAttributes allValues]];
        [self.allAttributes addObjectsFromArray:[self.sectionHeaderBackgroundAttributes allValues]];
        [self.allAttributes addObjectsFromArray:[self.hourHeaderBackgroundAttributes allValues]];
        [self.allAttributes addObjectsFromArray:[self.hourHeaderAttributes allValues]];
        [self.allAttributes addObjectsFromArray:[self.halfHourHeaderAttributes allValues]];
        [self.allAttributes addObjectsFromArray:[self.verticalGridlineAttributes allValues]];
        [self.allAttributes addObjectsFromArray:[self.currentTimeIndicatorAttributes allValues]];
        [self.allAttributes addObjectsFromArray:[self.verticalHalfHourGridlineAttributes allValues]];
        [self.allAttributes addObjectsFromArray:[self.currentTimeVerticalGridlineAttributes allValues]];
    }
}

#pragma mark - Preparing Layout Helpers

- (CGFloat)maximumSectionWidth
{
    if (self.cachedMaxSectionWidth != CGFLOAT_MIN) {
        return self.cachedMaxSectionWidth;
    }

    CGFloat maxSectionWidth = self.sectionHeaderWidth + ([self latestDate].timeIntervalSince1970 - [self earliestDate].timeIntervalSince1970) / 60.0 * self.minuteWidth + self.contentMargin.left + self.contentMargin.right;

    self.cachedMaxSectionWidth = maxSectionWidth;

    return maxSectionWidth;
}

- (CGFloat)xCoordinateForDate:(NSDate *)date
{
    return nearbyintf(self.collectionViewContentSize.width - ((fabs([self latestDate].timeIntervalSince1970 - date.timeIntervalSince1970)) / 60 * self.minuteWidth) - self.contentMargin.right);
}

- (NSDate *)dateForXCoordinate:(CGFloat)position
{
    if (position > self.collectionViewContentSize.width || position < 0) {
        return nil;
    }

    NSDate *earliestDate = [self earliestDate];

    CGFloat timeInSeconds = position / self.minuteWidth * 60;
    return [earliestDate dateByAddingTimeInterval:timeInSeconds];
}

- (CGFloat)minimumGridX
{
    return self.sectionHeaderWidth + self.contentMargin.left;
}

- (CGFloat)minimumGridY
{
    return self.hourHeaderHeight + self.contentMargin.top + self.collectionView.contentInset.top;
}

#pragma mark - Preparing Layout

- (void)prepareSectionLayoutForSections:(NSIndexSet *)sectionIndexes
{
    if (self.collectionView.numberOfSections == 0) {
        return;
    }

    BOOL needsToPopulateItemAttributes = (self.itemAttributes.count == 0);

    [self prepareSectionHeaderBackgroundAttributes];
    [self prepareHourHeaderBackgroundAttributes];

    [self prepareCurrentIndicatorAttributes];

    [self prepareVerticalGridlineAttributes];

    [sectionIndexes enumerateIndexesUsingBlock:^(NSUInteger section, BOOL *stop) {
        [self prepareSectionAttributes:section needsToPopulateItemAttributes:needsToPopulateItemAttributes];
    }];
}

- (void)prepareItemAttributesForSection:(NSUInteger)section sectionFrame:(CGRect)rect
{
    for (NSUInteger item = 0; item < [self.collectionView numberOfItemsInSection:section]; item++) {
        NSIndexPath *itemIndexPath = [NSIndexPath indexPathForItem:item inSection:section];
        
        NSDate *itemEndTime = [self endDateForIndexPath:itemIndexPath];
        
        if ([itemEndTime ins_isLaterThan:[self latestDate]] || [itemEndTime ins_isEarlierThan:[self earliestDate]]) {
            continue;
        }
        
        NSDate *itemStartTime = [self startDateForIndexPath:itemIndexPath];
        
        CGFloat itemStartTimePositionX = [self xCoordinateForDate:itemStartTime];
        CGFloat itemEndTimePositionX = [self xCoordinateForDate:itemEndTime];
        CGFloat itemWidth = itemEndTimePositionX - itemStartTimePositionX;
        
        UICollectionViewLayoutAttributes *itemAttributes = [self layoutAttributesForCellAtIndexPath:itemIndexPath withItemCache:self.itemAttributes];
        itemAttributes.frame = CGRectMake(itemStartTimePositionX + self.cellMargin.left, rect.origin.y + self.cellMargin.top, itemWidth - self.cellMargin.left - self.cellMargin.right, rect.size.height - self.cellMargin.top - self.cellMargin.bottom);
        itemAttributes.zIndex = [self zIndexForElementKind:nil];

    }
}

- (void)prepareSectionAttributes:(NSUInteger)section needsToPopulateItemAttributes:(BOOL)needsToPopulateItemAttributes
{
    CGFloat sectionMinY = self.hourHeaderHeight + self.contentMargin.top;

    CGFloat sectionMinX = self.collectionView.contentOffset.x;

    CGFloat sectionY = sectionMinY + ((self.sectionHeight + self.sectionGap) * section);
    NSIndexPath *sectionIndexPath = [NSIndexPath indexPathForItem:0 inSection:section];
    UICollectionViewLayoutAttributes *sectionAttributes = [self layoutAttributesForSupplementaryViewAtIndexPath:sectionIndexPath ofKind:INSEPGLayoutElementKindSectionHeader withItemCache:self.sectionHeaderAttributes];
    sectionAttributes.frame = CGRectMake(sectionMinX, sectionY, self.sectionHeaderWidth, self.sectionHeight);
    sectionAttributes.zIndex = [self zIndexForElementKind:INSEPGLayoutElementKindSectionHeader];

    if (needsToPopulateItemAttributes) {
        [self prepareItemAttributesForSection:section sectionFrame:sectionAttributes.frame];
    }
}

- (void)prepareVerticalGridlineAttributes
{
    CGFloat gridMinX = [self minimumGridX];
    CGFloat gridMaxWidth = [self maximumSectionWidth] - gridMinX;
    CGFloat hourWidth = [self hourWidth];

    CGFloat hourMinY = (self.collectionView.contentOffset.y + self.collectionView.contentInset.top);

    NSDate *startDate = [[self earliestDate] ins_dateWithoutMinutesAndSeconds];
    CGFloat startDatePosition = [self xCoordinateForDate:startDate];

    NSUInteger verticalGridlineIndex = 0;
    for (CGFloat hourX = startDatePosition; hourX <= gridMaxWidth; hourX += hourWidth) {
        NSIndexPath *hourHeaderIndexPath = [NSIndexPath indexPathForItem:verticalGridlineIndex inSection:0];

        CGFloat hourTimeInterval = 3600;
        if (![self.cachedHours objectForKey:hourHeaderIndexPath]) {
            [self.cachedHours setObject:[startDate dateByAddingTimeInterval: hourTimeInterval * verticalGridlineIndex] forKey:hourHeaderIndexPath];
        }

        UICollectionViewLayoutAttributes *hourHeaderAttributes = [self layoutAttributesForSupplementaryViewAtIndexPath:hourHeaderIndexPath ofKind:INSEPGLayoutElementKindHourHeader withItemCache:self.hourHeaderAttributes];
        CGFloat hourHeaderMinX = hourX - nearbyintf(self.hourWidth / 2.0);

        hourHeaderAttributes.frame = (CGRect){ {hourHeaderMinX, hourMinY}, {self.hourWidth, self.hourHeaderHeight} };
        hourHeaderAttributes.zIndex = [self zIndexForElementKind:INSEPGLayoutElementKindHourHeader];

        verticalGridlineIndex++;
    }

    NSInteger verticalHalfHourGridlineIndex = 0;
    for (CGFloat halfHourX = startDatePosition + hourWidth/2; halfHourX <= gridMaxWidth + hourWidth/2; halfHourX += hourWidth) {
        NSIndexPath *halfHourHeaderIndexPath = [NSIndexPath indexPathForItem:verticalHalfHourGridlineIndex inSection:0];

        CGFloat hourTimeInterval = 3600;
        if (![self.cachedHalfHours objectForKey:halfHourHeaderIndexPath]) {
            [self.cachedHalfHours setObject:[startDate dateByAddingTimeInterval:hourTimeInterval * verticalHalfHourGridlineIndex + hourTimeInterval/2] forKey:halfHourHeaderIndexPath];
        }

        UICollectionViewLayoutAttributes *halfHourHeaderAttributes = [self layoutAttributesForSupplementaryViewAtIndexPath:halfHourHeaderIndexPath ofKind:INSEPGLayoutElementKindHalfHourHeader withItemCache:self.halfHourHeaderAttributes];
        CGFloat hourHeaderMinX = halfHourX - nearbyintf(self.hourWidth / 2.0);
        halfHourHeaderAttributes.frame = (CGRect){ {hourHeaderMinX, hourMinY}, {self.hourWidth, self.hourHeaderHeight} };
        halfHourHeaderAttributes.zIndex = [self zIndexForElementKind:INSEPGLayoutElementKindHalfHourHeader];

        verticalHalfHourGridlineIndex++;
    }
}

- (void)prepareCurrentIndicatorAttributes
{
    NSIndexPath *currentTimeIndicatorIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    UICollectionViewLayoutAttributes *currentTimeIndicatorAttributes = [self layoutAttributesForDecorationViewAtIndexPath:currentTimeIndicatorIndexPath ofKind:INSEPGLayoutElementKindCurrentTimeIndicator withItemCache:self.currentTimeIndicatorAttributes];

    NSIndexPath *currentTimeHorizontalGridlineIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    UICollectionViewLayoutAttributes *currentTimeHorizontalGridlineAttributes = [self layoutAttributesForDecorationViewAtIndexPath:currentTimeHorizontalGridlineIndexPath ofKind:INSEPGLayoutElementKindCurrentTimeIndicatorVerticalGridline withItemCache:self.currentTimeVerticalGridlineAttributes];

    NSDate *currentDate = [self currentDate];
    BOOL currentTimeIndicatorVisible = ([currentDate ins_isLaterThanOrEqualTo:[self earliestDate]] && [currentDate ins_isEarlierThan:[self latestDate]]);
    currentTimeIndicatorAttributes.hidden = !currentTimeIndicatorVisible;
    currentTimeHorizontalGridlineAttributes.hidden = !currentTimeIndicatorVisible;

    if (currentTimeIndicatorVisible) {

        CGFloat xPositionToCurrentDate = [self xCoordinateForDate:currentDate];

        CGFloat currentTimeIndicatorMinX = xPositionToCurrentDate - nearbyintf(self.currentTimeIndicatorSize.width / 2.0);
        CGFloat currentTimeIndicatorMinY = (self.collectionView.contentOffset.y + (self.hourHeaderHeight - self.currentTimeIndicatorSize.height)) + self.collectionView.contentInset.top;
        currentTimeIndicatorAttributes.frame = (CGRect){ {currentTimeIndicatorMinX, currentTimeIndicatorMinY}, self.currentTimeIndicatorSize };
        currentTimeIndicatorAttributes.zIndex = [self zIndexForElementKind:INSEPGLayoutElementKindCurrentTimeIndicator];

        CGFloat currentTimeVerticalGridlineMinY = (self.collectionView.contentOffset.y + [self minimumGridY]);

        CGFloat gridHeight = (self.collectionViewContentSize.height + currentTimeVerticalGridlineMinY);

        currentTimeHorizontalGridlineAttributes.frame = (CGRect){ {xPositionToCurrentDate - self.currentTimeVerticalGridlineWidth/2, currentTimeVerticalGridlineMinY}, {self.currentTimeVerticalGridlineWidth, gridHeight} };
        currentTimeHorizontalGridlineAttributes.zIndex = [self zIndexForElementKind:INSEPGLayoutElementKindCurrentTimeIndicatorVerticalGridline];
    }
}

- (void)prepareSectionHeaderBackgroundAttributes
{
    CGFloat sectionHeaderMinX = self.collectionView.contentOffset.x;

    NSIndexPath *sectionHeaderBackgroundIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    UICollectionViewLayoutAttributes *sectionHeaderBackgroundAttributes = [self layoutAttributesForDecorationViewAtIndexPath:sectionHeaderBackgroundIndexPath ofKind:INSEPGLayoutElementKindSectionHeaderBackground withItemCache:self.sectionHeaderBackgroundAttributes];

    CGFloat sectionHeaderBackgroundHeight = self.collectionView.frame.size.height - self.collectionView.contentInset.top;
    CGFloat sectionHeaderBackgroundWidth = self.collectionView.frame.size.width;
    CGFloat sectionHeaderBackgroundMinX = (sectionHeaderMinX - sectionHeaderBackgroundWidth + self.sectionHeaderWidth);

    CGFloat sectionHeaderBackgroundMinY = self.collectionView.contentOffset.y + self.collectionView.contentInset.top;
    sectionHeaderBackgroundAttributes.frame = CGRectMake(sectionHeaderBackgroundMinX, sectionHeaderBackgroundMinY, sectionHeaderBackgroundWidth, sectionHeaderBackgroundHeight);

    sectionHeaderBackgroundAttributes.hidden = NO;
    sectionHeaderBackgroundAttributes.zIndex = [self zIndexForElementKind:INSEPGLayoutElementKindSectionHeaderBackground];
}

- (void)prepareHourHeaderBackgroundAttributes
{
    NSIndexPath *hourHeaderBackgroundIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    UICollectionViewLayoutAttributes *hourHeaderBackgroundAttributes = [self layoutAttributesForDecorationViewAtIndexPath:hourHeaderBackgroundIndexPath ofKind:INSEPGLayoutElementKindHourHeaderBackground withItemCache:self.hourHeaderBackgroundAttributes];
    // Frame
    CGFloat hourHeaderBackgroundHeight = self.hourHeaderHeight;

    hourHeaderBackgroundAttributes.frame = (CGRect){{self.collectionView.contentOffset.x, self.collectionView.contentOffset.y + self.collectionView.contentInset.top}, {self.collectionView.frame.size.width, hourHeaderBackgroundHeight}};

    hourHeaderBackgroundAttributes.hidden = NO;
    hourHeaderBackgroundAttributes.zIndex = [self zIndexForElementKind:INSEPGLayoutElementKindHourHeaderBackground];
}

#pragma mark - Layout


- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *indexPathKey = [self keyForIndexPath:indexPath];
    return self.itemAttributes[indexPathKey];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *indexPathKey = [self keyForIndexPath:indexPath];

    if (kind == INSEPGLayoutElementKindSectionHeader) {
        return self.sectionHeaderAttributes[indexPathKey];

    }else if (kind == INSEPGLayoutElementKindHourHeader) {
        return self.hourHeaderAttributes[indexPathKey];

    } else if (kind == INSEPGLayoutElementKindHalfHourHeader) {
        return self.halfHourHeaderAttributes[indexPathKey];

    }

    return nil;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)decorationViewKind atIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *indexPathKey = [self keyForIndexPath:indexPath];

    if (decorationViewKind == INSEPGLayoutElementKindCurrentTimeIndicator) {
        return self.currentTimeIndicatorAttributes[indexPathKey];
    }
    else if (decorationViewKind == INSEPGLayoutElementKindCurrentTimeIndicatorVerticalGridline) {
        return self.currentTimeVerticalGridlineAttributes[indexPathKey];
    }
    else if (decorationViewKind == INSEPGLayoutElementKindHourHeaderBackground) {
        return self.hourHeaderBackgroundAttributes[indexPathKey];
    }
    else if (decorationViewKind == INSEPGLayoutElementKindSectionHeaderBackground) {
        return self.hourHeaderBackgroundAttributes[indexPathKey];

    }
    return nil;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableIndexSet *visibleSections = [NSMutableIndexSet indexSet];
    [[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.collectionView.numberOfSections)] enumerateIndexesUsingBlock:^(NSUInteger section, BOOL *stop) {
        CGRect sectionRect = [self rectForSection:section];
        if (CGRectIntersectsRect(sectionRect, rect)) {
            [visibleSections addIndex:section];
        }
    }];

    // Update layout for only the visible sections
    [self prepareSectionLayoutForSections:visibleSections];

    // Return the visible attributes (rect intersection)
    return [self.allAttributes filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UICollectionViewLayoutAttributes *layoutAttributes, NSDictionary *bindings) {
        return CGRectIntersectsRect(layoutAttributes.frame,rect);
    }]];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    // Required for sticky headers
    return YES;
}

- (CGSize)collectionViewContentSize
{
    CGFloat width = [self maximumSectionWidth];
    CGFloat height = self.hourHeaderHeight + (((self.sectionHeight + self.sectionGap) * self.collectionView.numberOfSections)) + self.contentMargin.top + self.contentMargin.bottom - self.sectionGap;

    return CGSizeMake(width >= self.collectionView.frame.size.width ? width : self.collectionView.frame.size.width, height >= self.collectionView.frame.size.height ? height : self.collectionView.frame.size.height);
}

#pragma mark Section Sizing

- (CGRect)rectForSection:(NSInteger)section
{
    CGFloat sectionHeight = self.sectionHeight;
    CGFloat sectionY = self.contentMargin.top + self.hourHeaderHeight + ((sectionHeight + self.sectionGap) * section);
    return CGRectMake(0.0, sectionY, self.collectionViewContentSize.width, sectionHeight);
}

#pragma mark Z Index

- (CGFloat)zIndexForElementKind:(NSString *)elementKind
{
    if (elementKind == INSEPGLayoutElementKindCurrentTimeIndicator) {
        return (INSEPGLayoutMinOverlayZ + 4.0);
    }
    else if (elementKind == INSEPGLayoutElementKindHourHeader || elementKind == INSEPGLayoutElementKindHalfHourHeader) {
        return (INSEPGLayoutMinOverlayZ + 3.0);
    }
    else if (elementKind == INSEPGLayoutElementKindHourHeaderBackground) {
        return (INSEPGLayoutMinOverlayZ + 2.0);
    }
    else if (elementKind == INSEPGLayoutElementKindSectionHeader) {
        return (INSEPGLayoutMinOverlayZ + 1.0);
    }
    else if (elementKind == INSEPGLayoutElementKindSectionHeaderBackground) {
        return (INSEPGLayoutMinOverlayZ + 0.0);
    }
    // Cell
    else if (elementKind == nil) {
        return INSEPGLayoutMinCellZ;
    }
    // Current Time Vertical Gridline
    else if (elementKind == INSEPGLayoutElementKindCurrentTimeIndicatorVerticalGridline) {
        if (self.currentTimeIndicatorShouldBeBehind) {
            return (INSEPGLayoutMinBackgroundZ + 2.0);
        }
        
        // Place currentTimeGridLine just behind Section Header and above cell
        return (INSEPGLayoutMinOverlayZ + 0.9);
    }

    return CGFLOAT_MIN;
}

#pragma mark - Dates

- (NSDate *)earliestDate
{
    if (self.cachedEarliestDate) {
        return self.cachedEarliestDate;
    }
    NSDate *earliestDate = nil;
    
    if ([self.dataSource respondsToSelector:@selector(collectionView:startTimeForLayout:)]) {
        earliestDate = [self.dataSource collectionView:self.collectionView startTimeForLayout:self];
    } else {
        for (NSInteger section = 0; section < self.collectionView.numberOfSections; section++) {
            NSDate *earliestDateForSection = [self earliestDateForSection:section];
            if ((earliestDateForSection && [earliestDateForSection ins_isEarlierThan:earliestDate]) || !earliestDate) {
                earliestDate = earliestDateForSection;
            }
        }
    }

    if (earliestDate) {
        self.cachedEarliestDate = earliestDate;
        return self.cachedEarliestDate;
    }

    return [NSDate date];
}

- (NSDate *)earliestDateForSection:(NSInteger)section
{
    if (self.cachedEarliestDates[@(section)]) {
        return self.cachedEarliestDates[@(section)];
    }

    NSDate *earliestDate = nil;

    if ([self.dataSource respondsToSelector:@selector(collectionView:startTimeForLayout:)]) {
        earliestDate = [self.dataSource collectionView:self.collectionView startTimeForLayout:self];
    } else {
        for (NSInteger item = 0; item < [self.collectionView numberOfItemsInSection:section]; item++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            NSDate *itemStartDate = [self startDateForIndexPath:indexPath];
            if ((itemStartDate && [itemStartDate ins_isEarlierThan:earliestDate]) || !earliestDate) {
                earliestDate = itemStartDate;
            }
        }
    }

    if (earliestDate) {
        self.cachedEarliestDates[@(section)] = earliestDate;
        return earliestDate;
    }
    
    return nil;
}

- (NSDate *)latestDate
{
    if (self.cachedLatestDate) {
        return self.cachedLatestDate;
    }
    NSDate *latestDate = nil;

    if ([self.dataSource respondsToSelector:@selector(collectionView:endTimeForlayout:)]) {
        latestDate = [self.dataSource collectionView:self.collectionView endTimeForlayout:self];
    } else {
        for (NSInteger section = 0; section < self.collectionView.numberOfSections; section++) {
            NSDate *latestDateForSection = [self latestDateForSection:section];
            if ((latestDateForSection && [latestDateForSection ins_isLaterThan:latestDate]) || !latestDate) {
                latestDate = latestDateForSection;
            }
        }
    }

    if (latestDate) {
        self.cachedLatestDate = latestDate;
        return self.cachedLatestDate;
    }

    return [NSDate date];
}

- (NSDate *)latestDateForSection:(NSInteger)section
{
    if (self.cachedLatestDates[@(section)]) {
        return self.cachedLatestDates[@(section)];
    }

    NSDate *latestDate = nil;

    if ([self.dataSource respondsToSelector:@selector(collectionView:endTimeForlayout:)]) {
        latestDate = [self.dataSource collectionView:self.collectionView endTimeForlayout:self];
    } else {
        for (NSInteger item = 0; item < [self.collectionView numberOfItemsInSection:section]; item++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            NSDate *itemEndDate = [self endDateForIndexPath:indexPath];
            if ((itemEndDate && [itemEndDate ins_isLaterThan:latestDate]) || !latestDate) {
                latestDate = itemEndDate;
            }
        }
    }

    if (latestDate) {
        self.cachedLatestDates[@(section)] = latestDate;
        return latestDate;
    }

    return nil;
}

#pragma mark Delegate Wrappers

- (NSDate *)startDateForIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *indexPathKey = [self keyForIndexPath:indexPath];

    if ([self.cachedStartTimeDate objectForKey:indexPathKey]) {
        return [self.cachedStartTimeDate objectForKey:indexPathKey];
    }

    NSDate *date = [self.dataSource collectionView:self.collectionView layout:self startTimeForItemAtIndexPath:indexPathKey];

    [self.cachedStartTimeDate setObject:date forKey:indexPathKey];
    return date;
}

- (NSDate *)endDateForIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *indexPathKey = [self keyForIndexPath:indexPath];

    if ([self.cachedEndTimeDate objectForKey:indexPathKey]) {
        return [self.cachedEndTimeDate objectForKey:indexPathKey];
    }

    NSDate *date = [self.dataSource collectionView:self.collectionView layout:self endTimeForItemAtIndexPath:indexPathKey];

    [self.cachedEndTimeDate setObject:date forKey:indexPathKey];
    return date;
}

- (NSDate *)currentDate
{
    if (self.cachedCurrentDate) {
        return self.cachedCurrentDate;
    }

    NSDate *date = [self.dataSource currentTimeForCollectionView:self.collectionView layout:self];

    self.cachedCurrentDate = date;
    return date;
}

#pragma mark - Helpers
// Issues using NSIndexPath as key in NSMutableDictionary
// http://stackoverflow.com/questions/19613927/issues-using-nsindexpath-as-key-in-nsmutabledictionary

- (NSIndexPath *)keyForIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath class] == [NSIndexPath class]) {
        return indexPath;
    }
    return [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
}

@end
