//
//  INSElectronicProgramGuideLayout.h
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

#import <UIKit/UIKit.h>
#import "NSDate+INSUtils.h"

extern NSString *const INSEPGLayoutElementKindSectionHeader;
extern NSString *const INSEPGLayoutElementKindHourHeader;
extern NSString *const INSEPGLayoutElementKindHalfHourHeader;

extern NSString *const INSEPGLayoutElementKindSectionHeaderBackground;
extern NSString *const INSEPGLayoutElementKindHourHeaderBackground;

extern NSString *const INSEPGLayoutElementKindCurrentTimeIndicator;
extern NSString *const INSEPGLayoutElementKindCurrentTimeIndicatorVerticalGridline;

extern NSUInteger const INSEPGLayoutMinOverlayZ;
extern NSUInteger const INSEPGLayoutMinCellZ;
extern NSUInteger const INSEPGLayoutMinBackgroundZ;

@protocol INSElectronicProgramGuideLayoutDataSource;

@interface INSElectronicProgramGuideLayout : UICollectionViewLayout

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
@property (nonatomic, assign) BOOL currentTimeIndicatorShouldBeBehind;


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

@property (nonatomic, weak) id <INSElectronicProgramGuideLayoutDataSource> dataSource;

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

@protocol INSElectronicProgramGuideLayoutDataSource <UICollectionViewDataSource>
@required
- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(INSElectronicProgramGuideLayout *)electronicProgramGuideLayout startTimeForItemAtIndexPath:(NSIndexPath *)indexPath;

- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(INSElectronicProgramGuideLayout *)electronicProgramGuideLayout endTimeForItemAtIndexPath:(NSIndexPath *)indexPath;

- (NSDate *)currentTimeForCollectionView:(UICollectionView *)collectionView layout:(INSElectronicProgramGuideLayout *)collectionViewLayout;

@optional
/**
 *  By Default start and end date is calculated using collectionView:layout:startTimeForItemAtIndexPath: and collectionView:layout:endTimeForItemAtIndexPath:,
 *  if you want to force layout timeline use these delegate methods.
 */
- (NSDate *)collectionView:(UICollectionView *)collectionView startTimeForLayout:(INSElectronicProgramGuideLayout *)electronicProgramGuideLayout;
- (NSDate *)collectionView:(UICollectionView *)collectionView endTimeForlayout:(INSElectronicProgramGuideLayout *)electronicProgramGuideLayout;
@end
