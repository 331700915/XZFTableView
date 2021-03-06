//
//  XZFTableView.m
//  XZFTableView
//
//  Created by anxindeli on 2017/7/26.
//  Copyright © 2017年 anxindeli. All rights reserved.
//

#import "XZFTableView.h"
@interface XZFTableView ()<CellDelegate>
{
    CGFloat currentContent_x;
    NSInteger visibleCount;
    CGSize viewSize;
    NSInteger allCount;

}

@end
@implementation XZFTableView
- (instancetype)initWithFrame:(CGRect)frame{
    
    if (self = [super initWithFrame:frame]) {

        self.showsHorizontalScrollIndicator=NO;
        self.showsVerticalScrollIndicator=NO;
        self.directionalLockEnabled = YES;
        self.delegate = self;
        self.delaysContentTouches = NO;
        self.canCancelContentTouches = YES;
        self.backgroundColor = [UIColor blueColor];
        self.layer.masksToBounds = NO;
        self.visibleViewCells = [NSMutableArray array];
        self.reuseableViewCells = [NSMutableSet set];
        
    }
    return self;
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
    
    if ([view isKindOfClass:[UIControl class]]) {
        return YES;
    }
    return [super touchesShouldCancelInContentView:view];
    
}
- (void)addReuseItem:(ViewCell *)cell {
    
    [self.reuseableViewCells removeAllObjects];
    [self.reuseableViewCells addObject:cell];
    return;
    NSSet *tempSet = [self.reuseableViewCells filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"indentifier == %@", cell.indentifier]];
    // 查询复用池中有没有相同复用符的item
    if (![tempSet isSubsetOfSet:self.reuseableViewCells] || tempSet.count == 0) {
        // 没有则添加item到复用池中
        [self.reuseableViewCells addObject:cell];
    }
}

#pragma mark 自带方法
- (__kindof ViewCell *)dequeueReusableCardViewWithIdentifier:(NSString *)identifier{
    
    if (self.reuseableViewCells.count>0) {
        
        NSSet *set = [self.reuseableViewCells filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"indentifier ==%@",identifier]];
        ViewCell *view = [set anyObject];
        return view;
    }
    return nil;
}
// returns nil if cell is not visible or index is out of range
- (__kindof ViewCell *)cellForItemAtIndex:(NSInteger)index{
    
    ViewCell *cell = [self viewWithTag:index];
    if (cell && [self.visibleViewCells containsObject:cell]) {
        return cell;
    }else{
        return nil;
    }
    
}
- (void)reloadData{
    
    //获取总个数
    allCount = [self.xzfDataSource numberCardScrollView];
    //获取可视个数，根据返回的size计算，当前屏幕宽度可展示的最大个数
    viewSize = [self.xzfDelegate tableView:self];
    visibleCount = ceil(SCREEN_WIDTH/viewSize.width)+1;
    //可滑动距离
    self.contentSize = CGSizeMake(viewSize.width*allCount, 0);
    
    //判断当前可视数组个数和满屏时个数
    if (self.visibleViewCells.count<visibleCount) {
        
        //移除之前的所有子cell,重新创建新的cell
        for (UIView *view in self.subviews) {
            [view removeFromSuperview];
            [self.visibleViewCells removeAllObjects];
        }

        for (int i=0; i<visibleCount; i++) {
            
            ViewCell *cell = [self.xzfDataSource xzfTableview:self cellForRowAtIndex:i];
            [self addSubview:cell];
            [self.visibleViewCells addObject:cell];
            cell.tag = i;
            cell.cellDelegate = self;
//            cell.viewSize = viewSize;
            cell.frame = CGRectMake(i*viewSize.width, 0, viewSize.width, viewSize.height);
            
        }
    }else{
        
        for (ViewCell *cell in self.visibleViewCells) {

            if (self.xzfDataSource&&[self.xzfDataSource respondsToSelector:@selector(xzfTableview:cellForRowAtIndex:)]) {
                [self.xzfDataSource xzfTableview:self cellForRowAtIndex:cell.tag];
            }
            
        }
    }
}
- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated{
    
    
    [self setContentOffset:CGPointMake(viewSize.width*index, 0) animated:animated];
    
}
#pragma mark - UISCrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    //移动
    if (self.xzfDelegate && [self.xzfDelegate respondsToSelector:@selector(xzfTableViewDidScroll:)]) {
        [self.xzfDelegate xzfTableViewDidScroll:self];
    }

    if (scrollView.contentOffset.x<=0||scrollView.contentOffset.x>=scrollView.contentSize.width-SCREEN_WIDTH) {
        
        return;
    }

    if (currentContent_x>=scrollView.contentOffset.x) {//向左
        self.sDirection = ScrollDirectionLeft;
    }else{//向右
        self.sDirection = ScrollDirectionRight;
    }
    [self editItemFrame:self.sDirection withOffSex:scrollView.contentOffset.x];

    currentContent_x = scrollView.contentOffset.x;
    
}
- (void)editItemFrame:(ScrollDirection)direction withOffSex:(CGFloat )offSet{
    
    
    ViewCell *lastCell = [self.visibleViewCells lastObject];
    ViewCell *topCell  = [self.visibleViewCells firstObject];
    
    CGFloat lastMinXOffSet = CGRectGetMinX(lastCell.frame);
    CGFloat lastMaxXOffSet = CGRectGetMaxX(lastCell.frame);

    CGFloat topMaxXOffSet = CGRectGetMaxX(topCell.frame);
    CGFloat topMinXOffSet = CGRectGetMinX(topCell.frame);


    NSInteger nextTag = 0;
    if (self.sDirection == ScrollDirectionLeft) {//向左走
        if (lastMinXOffSet>offSet+SCREEN_WIDTH) {
            nextTag = topCell.tag - 1;
            [self addReuseItem:lastCell];
            [self.visibleViewCells removeObject:lastCell];
            
            while (nextTag > -1) {
                [self getReuseCell:nextTag];
                nextTag--;
                if (topMinXOffSet >offSet - SCREEN_WIDTH) {
                    break;
                }
            }
        }
    }else{
        if (topMaxXOffSet<offSet) {//向右走
            nextTag = lastCell.tag + 1;
            [self addReuseItem:topCell];
            [self.visibleViewCells removeObject:topCell];
            while (nextTag < allCount) {
                [self getReuseCell:nextTag];
                nextTag++;
                if (lastMaxXOffSet > offSet + SCREEN_WIDTH ) {
                    break;
                }
            }
        }
    }
    //按照tag大小排序
    [self.visibleViewCells sortUsingComparator:^NSComparisonResult(UIView *view1, UIView *view2) {
        return view1.tag > view2.tag;
    }];
}
- (void)getReuseCell:(NSInteger)nextTag{
    //去重用池获取重用的cell,没有的话，创建重用cell
    ViewCell *cell = [self.xzfDataSource xzfTableview:self cellForRowAtIndex:nextTag];
    cell.tag = nextTag;
    cell.cellDelegate = self;
    cell.frame = CGRectMake(nextTag * viewSize.width, 0, viewSize.width, viewSize.height);

    //
    if (![self.subviews containsObject:cell]) {
        [self addSubview:cell];
    }
    [self.visibleViewCells addObject:cell];
    if ([self.reuseableViewCells containsObject:cell]) {
        [self.reuseableViewCells removeObject:cell];
    }

}
//取消选中一条
- (void)deselectRowAtIndexPath:(NSInteger)index animated:(BOOL)animated{
    
    if (self.xzfDelegate &&[self.xzfDelegate respondsToSelector:@selector(tableView:didDeselectRowAtIndex:)]) {
        [self.xzfDelegate tableView:self didDeselectRowAtIndex:index];
    }
    
}
#pragma mark - CellDelegate //点击选中一条
- (void)selectCurrentCell:(NSInteger)index{
    
    
    if (self.xzfDelegate &&[self.xzfDelegate respondsToSelector:@selector(tableView:didSelectRowAtIndex:)]) {
        [self.xzfDelegate tableView:self didSelectRowAtIndex:index];
    }
    
}
#pragma mark - SETTer方法
- (void)setXzfDataSource:(id<UIXZFTableViewDataSource>)xzfDataSource{
    _xzfDataSource = xzfDataSource;
    [self reloadData];
}
- (void)setXzfDelegate:(id<UIXZFTableViewDelegate>)xzfDelegate{
    _xzfDelegate = xzfDelegate;
}

@end
