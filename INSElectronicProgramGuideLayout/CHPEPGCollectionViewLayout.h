//
//  CHPEPGCollectionViewLayout.h
//  INSElectronicProgramGuideLayout
//
//  Created by Andreas Astlind on 2016-02-18.
//  Copyright © 2016 inspace.io. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const CHPEPGLayoutElementKindSectionHeader;
extern NSString *const CHPEPGLayoutElementKindHourHeader;
extern NSString *const CHPEPGLayoutElementKindHalfHourHeader;

extern NSString *const CHPEPGLayoutElementKindSectionHeaderBackground;
extern NSString *const CHPEPGLayoutElementKindHourHeaderBackground;

extern NSString *const CHPEPGLayoutElementKindCurrentTimeIndicator;
extern NSString *const CHPEPGLayoutElementKindCurrentTimeIndicatorVerticalGridline;

extern NSUInteger const CHPEPGLayoutMinOverlayZ;
extern NSUInteger const CHPEPGLayoutMinCellZ;
extern NSUInteger const CHPEPGLayoutMinBackgroundZ;

@protocol CHPEPGCollectionViewLayoutDataSource;

@interface CHPEPGCollectionViewLayout : UICollectionViewLayout

/**
 *  Vertical space between sections (channels)
 */
@property (nonatomic, assign) CGFloat sectionGap;

/**
 *  Section size
 */
@property (nonatomic, assign) CGFloat sectionHeight;
@property (nonatomic, assign) CGFloat sectionHeaderWidth;

/**
 *  Current time indicator and gridline size
 */
@property (nonatomic, assign) CGSize currentTimeIndicatorSize;
@property (nonatomic, assign) CGFloat currentTimeVerticalGridlineWidth;

/**
 *  Current time indicator zIndex
 */
@property (nonatomic, assign) BOOL currentTimeIndicatorShouldBeBehindCells;


/**
 *  Gridlines size
 */
@property (nonatomic, assign) CGFloat verticalGridlineWidth;

/**
 *  Hour width and hour header height
 */
@property (nonatomic, assign) CGFloat hourWidth;
@property (nonatomic, assign) CGFloat hourHeaderHeight;

/**
 * Distances between the border and the layout content view.
 * Default value is UIEdgeInsetsMake(0, 0, 0, 0)
 */
@property (nonatomic, assign) UIEdgeInsets contentMargin;

/**
 *  Margin between cells.
 *  Default value is UIEdgeInsetsMake(0, 0, 0, 10)
 */
@property (nonatomic, assign) UIEdgeInsets cellMargin;

@property (nonatomic, weak) id <CHPEPGCollectionViewLayoutDataSource> dataSource;

/**
 *  Returns the x-axis position on collection view content view for date.
 */
- (CGFloat)xCoordinateForDate:(NSDate *)date;

/**
 * Returns date for x-axis position on collection view content view.
 */
- (NSDate *)dateForXCoordinate:(CGFloat)position;

- (NSDate *)dateForHourHeaderAtIndexPath:(NSIndexPath *)indexPath;
- (NSDate *)dateForHalfHourHeaderAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  Scrolling to current time on timeline
 */
- (void)scrollToCurrentTimeAnimated:(BOOL)animated;

// Since a "reloadData" on the UICollectionView doesn't call "prepareForCollectionViewUpdates:", this method must be called first to flush the internal caches
- (void)invalidateLayoutCache;

@end


@protocol CHPEPGCollectionViewLayoutDataSource <UICollectionViewDataSource>
@required
- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(CHPEPGCollectionViewLayout *)electronicProgramGuideLayout startTimeForItemAtIndexPath:(NSIndexPath *)indexPath;

- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(CHPEPGCollectionViewLayout *)electronicProgramGuideLayout endTimeForItemAtIndexPath:(NSIndexPath *)indexPath;

- (NSDate *)currentTimeForCollectionView:(UICollectionView *)collectionView layout:(CHPEPGCollectionViewLayout *)collectionViewLayout;

@optional
/**
 *  By Default start and end date is calculated using collectionView:layout:startTimeForItemAtIndexPath: and collectionView:layout:endTimeForItemAtIndexPath:,
 *  if you want to force layout timeline use these delegate methods.
 */
- (NSDate *)collectionView:(UICollectionView *)collectionView startTimeForLayout:(CHPEPGCollectionViewLayout *)electronicProgramGuideLayout;
- (NSDate *)collectionView:(UICollectionView *)collectionView endTimeForlayout:(CHPEPGCollectionViewLayout *)electronicProgramGuideLayout;
@end
