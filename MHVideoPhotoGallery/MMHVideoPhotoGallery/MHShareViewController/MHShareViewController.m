//
//  MHShareViewController.m
//  MHVideoPhotoGallery
//
//  Created by Mario Hahn on 10.01.14.
//  Copyright (c) 2014 Mario Hahn. All rights reserved.
//

#import "MHShareViewController.h"
#import "MHMediaPreviewCollectionViewCell.h"
#import "MHGallery.h"
#import "UIImageView+WebCache.h"
#import "MHTransitionShowShareView.h"
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>


@implementation MHShareItem

- (id)initWithImageName:(NSString*)imageName
                  title:(NSString*)title
   withMaxNumberOfItems:(NSInteger)maxNumberOfItems
           withSelector:(NSString*)selectorName
       onViewController:(id)onViewController{
    self = [super init];
    if (!self)
        return nil;
    self.imageName = imageName;
    self.title = title;
    self.maxNumberOfItems = maxNumberOfItems;
    self.selectorName = selectorName;
    self.onViewController = onViewController;
    return self;
}
@end

@implementation MHCollectionViewTableViewCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (!(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) return nil;
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.sectionInset = UIEdgeInsetsMake(0, 25, 0, 25);
    layout.itemSize = CGSizeMake(270, 210);
    layout.minimumLineSpacing = 15;
    layout.minimumInteritemSpacing = 15;
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    
    _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds
                                         collectionViewLayout:layout];
    
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.showsHorizontalScrollIndicator = NO;
    [self.collectionView registerClass:[MHMediaPreviewCollectionViewCell class] forCellWithReuseIdentifier:@"MHMediaPreviewCollectionViewCell"];
    
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    [[self contentView] addSubview:self.collectionView];
    return self;
}

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds];
        self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        [[self contentView] addSubview:self.collectionView];
    }
    return self;
}
-(void)prepareForReuse{
    
}

@end


@implementation MHShareCell

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        _thumbnailImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.bounds.size.width/2-30, 1, 60, 60)];
        self.thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.thumbnailImageView.clipsToBounds = YES;
        [[self contentView] addSubview:self.thumbnailImageView];
        
        _descriptionLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, self.bounds.size.height-40, self.bounds.size.width, 40)];
        self.descriptionLabel.backgroundColor = [UIColor clearColor];
        self.descriptionLabel.textColor = [UIColor blackColor];
        self.descriptionLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
        [self.descriptionLabel setNumberOfLines:2];
        [[self contentView] addSubview:self.descriptionLabel];
    }
    return self;
}
@end


@interface MHShareViewController ()
@property(nonatomic,strong) NSMutableArray *shareDataSource;
@property(nonatomic,strong) NSArray *shareDataSourceStart;
@property(nonatomic,strong) NSMutableArray *selectedRows;
@property(nonatomic)        CGFloat startPointScroll;
@property(nonatomic,strong) MHShareItem *saveObject;
@property(nonatomic,strong) MHShareItem *mailObject;
@property(nonatomic,strong) MHShareItem *messageObject;
@property(nonatomic,strong) MHShareItem *twitterObject;
@property(nonatomic,strong) MHShareItem *faceBookObject;
@property(nonatomic,getter = isShowingShareViewInLandscapeMode) BOOL showingShareViewInLandscapeMode;
@property (nonatomic, strong) NSNumberFormatter *numberFormatter;
@property (nonatomic)         NSInteger saveCount;
@property (nonatomic,strong)  NSMutableArray *dataDownload;
@property (nonatomic,strong)  UILabel *downloadDataLabel;
@property (nonatomic,strong)  UIToolbar *blurBackgroundToolbar;
@property (nonatomic,strong)  UIButton *cancelDownloadButton;
@property (nonatomic,strong)  NSMutableArray *sessions;

@end

@implementation MHShareViewController

-(void)initShareObjects{
    
    
    self.saveObject = [[MHShareItem alloc]initWithImageName:@"activtyMH"
                                                      title:MHGalleryLocalizedString(@"shareview.save.cameraRoll")
                                       withMaxNumberOfItems:MAXFLOAT
                                               withSelector:@"saveImages:"
                                           onViewController:self];
    
    self.mailObject = [[MHShareItem alloc]initWithImageName:@"mailMH"
                                                      title:MHGalleryLocalizedString(@"shareview.mail")
                                       withMaxNumberOfItems:10
                                               withSelector:@"mailImages:"
                                           onViewController:self];
    
    self.messageObject = [[MHShareItem alloc]initWithImageName:@"messageMH"
                                                         title:MHGalleryLocalizedString(@"shareview.message")
                                          withMaxNumberOfItems:15
                                                  withSelector:@"smsImages:"
                                              onViewController:self];
    
    self.twitterObject = [[MHShareItem alloc]initWithImageName:@"twitterMH"
                                                         title:@"Twitter"
                                          withMaxNumberOfItems:2
                                                  withSelector:@"twShareImages:"
                                              onViewController:self] ;
    
    self.faceBookObject = [[MHShareItem alloc]initWithImageName:@"facebookMH"
                                                          title:@"Facebook"
                                           withMaxNumberOfItems:10
                                                   withSelector:@"fbShareImages:"
                                               onViewController:self];
}

-(void)cancelPressed{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationController.delegate = self;
    [self.collectionView.delegate scrollViewDidScroll:self.collectionView];
    
}

-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView{
    self.startPointScroll = scrollView.contentOffset.x;
}

-(void) scrollViewWillEndDragging:(UIScrollView*)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint*)targetContentOffset {
    
    NSArray *visibleCells = [self sortObjectsWithFrame:self.collectionView.visibleCells];
    MHMediaPreviewCollectionViewCell *cell;
    if ((self.startPointScroll <  targetContentOffset->x) && (visibleCells.count >1)) {
        cell = visibleCells[1];
    }else{
        cell = [visibleCells firstObject];
    }
    if (MHISIPAD) {
        *targetContentOffset = CGPointMake((cell.tag * 330+20), targetContentOffset->y);
    }else{
        *targetContentOffset = CGPointMake((cell.tag * 250+20), targetContentOffset->y);
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.navigationController.delegate == self) {
        self.navigationController.delegate = nil;
    }
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController *)fromVC
                                                 toViewController:(UIViewController *)toVC {
    return [MHTransitionShowShareView new];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.numberFormatter = [NSNumberFormatter new];
    [self.numberFormatter setMinimumIntegerDigits:2];
    
    
    
    self.selectedRows = [NSMutableArray new];
    self.view.backgroundColor =[UIColor whiteColor];
    self.navigationItem.hidesBackButton =YES;
    
    UIBarButtonItem *cancelBarButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                    target:self
                                                                                    action:@selector(cancelPressed)];
    
    self.navigationItem.leftBarButtonItem = cancelBarButton;
    
    UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    if (MHISIPAD) {
        flowLayout.itemSize = CGSizeMake(320, self.view.frame.size.height-330);
    }else{
        flowLayout.itemSize = CGSizeMake(240, self.view.frame.size.height-330);
    }
    flowLayout.minimumInteritemSpacing =20;
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 60, 0, 0);
    self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-240)
                                            collectionViewLayout:flowLayout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.allowsMultipleSelection=YES;
    self.collectionView.contentInset =UIEdgeInsetsMake(0, 0, 0, 0);
    self.collectionView.showsHorizontalScrollIndicator =NO;
    self.collectionView.backgroundColor =[UIColor whiteColor];
    [self.collectionView registerClass:[MHMediaPreviewCollectionViewCell class]
            forCellWithReuseIdentifier:@"MHMediaPreviewCollectionViewCell"];
    
    self.collectionView.decelerationRate = UIScrollViewDecelerationRateNormal;
    [self.view addSubview:self.collectionView];
    
    
    [self.selectedRows addObject:[NSIndexPath indexPathForRow:self.pageIndex inSection:0]];
    
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.pageIndex inSection:0]
                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                        animated:NO];
    
    self.gradientView= [[UIView alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height-240, self.view.frame.size.width,240)];
    
    self.toolbar = [[UIToolbar alloc]initWithFrame:self.gradientView.frame];
    [self.view addSubview:self.toolbar];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.gradientView.bounds;
    gradient.colors = @[(id)[[UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:1] CGColor],
                        (id)[[UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:1] CGColor]];
    
    [self.gradientView.layer insertSublayer:gradient atIndex:0];
    [self.view addSubview:self.gradientView];
    
    self.tableViewShare = [[UITableView alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height-230, self.view.frame.size.width, 240)];
    self.tableViewShare.delegate =self;
    self.tableViewShare.separatorStyle =UITableViewCellSeparatorStyleNone;
    self.tableViewShare.dataSource =self;
    self.tableViewShare.backgroundColor =[UIColor clearColor];
    self.tableViewShare.scrollEnabled =NO;
    [self.tableViewShare registerClass:[MHCollectionViewTableViewCell class]
                forCellReuseIdentifier:@"MHCollectionViewTableViewCell"];
    [self.view addSubview:self.tableViewShare];
    
    UIView *sep = [[UIView alloc]initWithFrame:CGRectMake(0,115, self.view.frame.size.width, 1)];
    sep.backgroundColor = [UIColor colorWithRed:0.63 green:0.63 blue:0.63 alpha:1];
    sep.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.tableViewShare addSubview:sep];
    
    [self initShareObjects];
    [self updateTitle];
    
    NSMutableArray *shareObjectAvailable = [NSMutableArray arrayWithArray:@[self.messageObject,
                                                                            self.mailObject,
                                                                            self.twitterObject,
                                                                            self.faceBookObject]];
    
    
    if(![SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]){
        [shareObjectAvailable removeObject:self.faceBookObject];
    }
    if(![SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]){
        [shareObjectAvailable removeObject:self.twitterObject];
    }
    
    self.shareDataSource = [NSMutableArray arrayWithArray:@[shareObjectAvailable,
                                                            @[[self saveObject]]
                                                            ]];
    
    self.shareDataSourceStart = [NSArray arrayWithArray:self.shareDataSource];
    if([UIApplication sharedApplication].statusBarOrientation != UIInterfaceOrientationPortrait){
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Next"
                                                                                 style:UIBarButtonItemStyleBordered
                                                                                target:self
                                                                                action:@selector(showShareSheet)];
    }
    self.startPointScroll = self.collectionView.contentOffset.x;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 119;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = nil;
    cellIdentifier = @"MHCollectionViewTableViewCell";
    
    MHCollectionViewTableViewCell *cell = (MHCollectionViewTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell){
        cell = [[MHCollectionViewTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.backgroundColor = [UIColor clearColor];
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 10);
    layout.itemSize = CGSizeMake(70, 100);
    layout.minimumLineSpacing = 10;
    layout.minimumInteritemSpacing = 10;
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    cell.collectionView.collectionViewLayout = layout;
    
    [cell.collectionView registerClass:[MHShareCell class]
            forCellWithReuseIdentifier:@"MHShareCell"];
    [cell.collectionView setShowsHorizontalScrollIndicator:NO];
    [cell.collectionView setDelegate:self];
    [cell.collectionView setDataSource:self];
    [cell.collectionView setBackgroundColor:[UIColor clearColor]];
    [cell.collectionView setTag:indexPath.section];
    [cell.collectionView reloadData];
    
    return cell;
}
-(void)updateTitle{
    NSString *localizedTitle =  MHGalleryLocalizedString(@"shareview.title.select.singular");
    self.title = [NSString stringWithFormat:localizedTitle, @(self.selectedRows.count)];
    if (self.selectedRows.count >1) {
        NSString *localizedTitle =  MHGalleryLocalizedString(@"shareview.title.select.plural");
        self.title = [NSString stringWithFormat:localizedTitle, @(self.selectedRows.count)];
    }
}

-(MHGalleryController*)gallerViewController{
    return  (MHGalleryController*)self.navigationController;
}
-(MHGalleryItem*)itemForIndex:(NSInteger)index{
    return [self.gallerViewController.dataSource itemForIndex:index];
}
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if ([collectionView isEqual:self.collectionView]) {
        return [self.gallerViewController.dataSource numberOfItemsInGallery:self.gallerViewController];
    }
    return [self.shareDataSource[collectionView.tag] count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell =nil;
    if ([collectionView isEqual:self.collectionView]) {
        NSString *cellIdentifier = @"MHMediaPreviewCollectionViewCell";
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        [self makeOverViewDetailCell:(MHMediaPreviewCollectionViewCell*)cell atIndexPath:indexPath];
    }else{
        NSString *cellIdentifier = @"MHShareCell";
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        NSIndexPath *indexPathNew = [NSIndexPath indexPathForRow:indexPath.row inSection:collectionView.tag];
        [self makeMHShareCell:(MHShareCell*)cell atIndexPath:indexPathNew];
    }
    return cell;
}
-(void)makeMHShareCell:(MHShareCell*)cell atIndexPath:(NSIndexPath*)indexPath{
    
    MHShareItem *shareItem = self.shareDataSource[indexPath.section][indexPath.row];
    
    cell.thumbnailImageView.image = [UIImage imageNamed:shareItem.imageName];
    [cell.thumbnailImageView setContentMode:UIViewContentModeCenter];
    if (indexPath.section ==0) {
        cell.thumbnailImageView.layer.cornerRadius =15;
    }
    cell.descriptionLabel.adjustsFontSizeToFitWidth =YES;
    cell.thumbnailImageView.clipsToBounds = YES;
    
    cell.descriptionLabel.textAlignment = NSTextAlignmentCenter;
    cell.descriptionLabel.text = shareItem.title;
    cell.backgroundColor = [UIColor clearColor];
}

-(void)makeOverViewDetailCell:(MHMediaPreviewCollectionViewCell*)cell atIndexPath:(NSIndexPath*)indexPath{
    __block MHMediaPreviewCollectionViewCell *blockCell = cell;
    
    MHGalleryItem *item = [self itemForIndex:indexPath.row];
    cell.videoDurationLength.text = @"";
    cell.videoIcon.hidden = YES;
    cell.videoGradient.hidden = YES;
    
    if (item.galleryType == MHGalleryTypeImage) {
        if ([item.URLString rangeOfString:@"assets-library"].location != NSNotFound && item.URLString) {
            [[MHGallerySharedManager sharedManager] getImageFromAssetLibrary:item.URLString assetType:MHAssetImageTypeThumb successBlock:^(UIImage *image, NSError *error) {
                cell.thumbnail.image = image;
            }];
        }else if(item.image){
            cell.thumbnail.image = item.image;
        }else{
            [cell.thumbnail setImageWithURL:[NSURL URLWithString:item.URLString] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                if (!image) {
                    blockCell.thumbnail.image = [UIImage imageNamed:@"error"];
                }
            }];
        }
    }else{
        [[MHGallerySharedManager sharedManager] startDownloadingThumbImage:item.URLString
                                                              successBlock:^(UIImage *image,NSUInteger videoDuration,NSError *error,NSString *newURL) {
                                                                  if (error) {
                                                                      cell.thumbnail.image = [UIImage imageNamed:@"error"];
                                                                  }else{
                                                                      
                                                                      NSNumber *minutes = @(videoDuration / 60);
                                                                      NSNumber *seconds = @(videoDuration % 60);
                                                                      
                                                                      blockCell.videoDurationLength.text = [NSString stringWithFormat:@"%@:%@",
                                                                                                            [self.numberFormatter stringFromNumber:minutes] ,[self.numberFormatter stringFromNumber:seconds]];
                                                                      blockCell.thumbnail.image =image;
                                                                      blockCell.videoIcon.hidden =NO;
                                                                      blockCell.videoGradient.hidden =NO;
                                                                  }
                                                              }];
    }
    
    cell.thumbnail.contentMode = UIViewContentModeScaleAspectFill;
    cell.selectionImageView.hidden =NO;
    
    cell.selectionImageView.layer.borderWidth =1;
    cell.selectionImageView.layer.cornerRadius =11;
    cell.selectionImageView.layer.borderColor =[UIColor whiteColor].CGColor;
    cell.selectionImageView.image =  nil;
    cell.selectionImageView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.45];
    
    if ([self.selectedRows containsObject:indexPath]) {
        cell.selectionImageView.backgroundColor = [UIColor whiteColor];
        cell.selectionImageView.tintColor = [UIColor colorWithRed:0 green:0.46 blue:1 alpha:1];
        cell.selectionImageView.image =  [[UIImage imageNamed:@"EditControlSelected"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    
    cell.tag = indexPath.row;
    
}
-(NSArray*)sortObjectsWithFrame:(NSArray*)objects{
    NSComparator comparatorBlock = ^(id obj1, id obj2) {
        if ([obj1 frame].origin.x > [obj2 frame].origin.x) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        if ([obj1 frame].origin.x < [obj2 frame].origin.x) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        return (NSComparisonResult)NSOrderedSame;
    };
    NSMutableArray *fieldsSort = [[NSMutableArray alloc]initWithArray:objects];
    [fieldsSort sortUsingComparator:comparatorBlock];
    return [NSArray arrayWithArray:fieldsSort];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if ([scrollView isEqual:self.collectionView]) {
        NSArray *visibleCells = [self sortObjectsWithFrame:self.collectionView.visibleCells];
        for (MHMediaPreviewCollectionViewCell *cellOther in visibleCells) {
            if (!cellOther.videoIcon.isHidden){
                cellOther.selectionImageView.frame = CGRectMake(cellOther.bounds.size.width-30,  cellOther.bounds.size.height-50, 22, 22);
            }else{
                cellOther.selectionImageView.frame = CGRectMake(cellOther.bounds.size.width-30,  cellOther.bounds.size.height-30, 22, 22);
            }
        }
        
        MHMediaPreviewCollectionViewCell *cell = [visibleCells lastObject];
        CGRect rect = [self.view convertRect:cell.thumbnail.frame
                                    fromView:cell.thumbnail.superview];
        
        NSInteger valueToAddYForVideoType =0;
        if (!cell.videoIcon.isHidden){
            valueToAddYForVideoType+=20;
        }
        
        cell.selectionImageView.frame = CGRectMake(self.view.frame.size.width-rect.origin.x-30, cell.bounds.size.height-(30+valueToAddYForVideoType), 22, 22);
        if (cell.selectionImageView.frame.origin.x < 5) {
            cell.selectionImageView.frame = CGRectMake(5,  cell.bounds.size.height-(30+valueToAddYForVideoType), 22, 22);
        }
        
        if (cell.selectionImageView.frame.origin.x > cell.bounds.size.width-30 ) {
            cell.selectionImageView.frame = CGRectMake(cell.bounds.size.width-30,  cell.bounds.size.height-(30+valueToAddYForVideoType), 22, 22);
        }
    }
}

-(void)updateCollectionView{
    
    NSInteger index =0;
    NSArray *storedData = [NSArray arrayWithArray:self.shareDataSource];
    
    self.shareDataSource = [NSMutableArray new];
    
    for (NSArray *array in self.shareDataSourceStart) {
        NSMutableArray *newObjects  = [NSMutableArray new];
        
        for (MHShareItem *item in array) {
            if (self.selectedRows.count <= item.maxNumberOfItems) {
                if (![storedData[index] containsObject:item]) {
                    [newObjects addObject:item];
                }else{
                    [newObjects addObject:item];
                }
            }
        }
        [self.shareDataSource addObject:newObjects];
        MHCollectionViewTableViewCell *cell = (MHCollectionViewTableViewCell*)[self.tableViewShare cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index]];
        [cell.collectionView reloadData];
        index++;
    }
}
-(void)presentSLComposeForServiceType:(NSString*)serviceType{
    
    [self getAllImagesForSelectedRows:^(NSArray *images){
        SLComposeViewController *shareconntroller=[SLComposeViewController composeViewControllerForServiceType:serviceType];
        SLComposeViewControllerCompletionHandler __block completionHandler=^(SLComposeViewControllerResult result){
            
            [shareconntroller dismissViewControllerAnimated:YES
                                                 completion:nil];
        };
        NSString *videoURLS = [NSString new];
        for (id data in images) {
            if ([data isKindOfClass:[UIImage class]]) {
                [shareconntroller addImage:data];
            }else{
                videoURLS = [videoURLS stringByAppendingString:[NSString stringWithFormat: @"%@ \n",data]];
            }
        }
        [shareconntroller setInitialText:videoURLS];
        [shareconntroller setCompletionHandler:completionHandler];
        [self presentViewController:shareconntroller
                           animated:YES
                         completion:nil];
    } saveDataToCameraRoll:NO];
}
-(void)twShareImages:(NSArray*)object{
    [self presentSLComposeForServiceType:SLServiceTypeTwitter];
}

-(void)fbShareImages:(NSArray*)object{
    [self presentSLComposeForServiceType:SLServiceTypeFacebook];
}

-(void)smsImages:(NSArray*)object{
    [self getAllImagesForSelectedRows:^(NSArray *images) {
        MFMessageComposeViewController *picker = [MFMessageComposeViewController new];
        picker.messageComposeDelegate = self;
        NSString *videoURLS = [NSString new];
        
        for (id data in images) {
            if ([data isKindOfClass:[UIImage class]]) {
                
                [picker addAttachmentData:UIImageJPEGRepresentation(data, 1.0)
                           typeIdentifier:@"public.image"
                                 filename:@"image.JPG"];
            }else{
                videoURLS = [videoURLS stringByAppendingString:[NSString stringWithFormat: @"%@ \n",data]];
            }
        }
        picker.body = videoURLS;
        
        
        [self presentViewController:picker
                           animated:YES
                         completion:nil];
    } saveDataToCameraRoll:NO];
}

-(void)mailImages:(NSArray*)object{
    [self getAllImagesForSelectedRows:^(NSArray *images) {
        MFMailComposeViewController *picker = [MFMailComposeViewController new];
        picker.mailComposeDelegate = self;
        NSString *videoURLS = [NSString new];
        
        for (id data in images) {
            if ([data isKindOfClass:[UIImage class]]) {
                [picker addAttachmentData:UIImageJPEGRepresentation(data, 1.0)
                                 mimeType:@"image/jpeg"
                                 fileName:@"image"];
            }else{
                videoURLS = [videoURLS stringByAppendingString:[NSString stringWithFormat: @"%@ \n",data]];
            }
        }
        [picker setMessageBody:videoURLS isHTML:NO];
        
        if([MFMailComposeViewController canSendMail]){
            [self presentViewController:picker
                               animated:YES
                             completion:nil];
        }
    } saveDataToCameraRoll:NO];
}
-(void)messageComposeViewController:(MFMessageComposeViewController *)controller
                didFinishWithResult:(MessageComposeResult)result{
    [controller dismissViewControllerAnimated:YES
                                   completion:^{
                                       [self cancelPressed];
                                   }];
}
-(void)mailComposeController:(MFMailComposeViewController *)controller
         didFinishWithResult:(MFMailComposeResult)result
                       error:(NSError *)error{
    [controller dismissViewControllerAnimated:YES
                                   completion:^{
                                       [self cancelPressed];
                                   }];
}

-(void)setSaveCount:(NSInteger)saveCount{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (saveCount == self.selectedRows.count) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            if (self.blurBackgroundToolbar) {
                [self removeBlurBlurBackgorundToolbarFromSuperView:^(BOOL complition) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        self.finishedCallbackDownloadData(self.dataDownload);
                    });
                }];
            }else{
                self.finishedCallbackDownloadData(self.dataDownload);
            }
        }
        self.downloadDataLabel.attributedText =[self attributedStringForDownloadLabelWithDownloadedDataNumber:@(saveCount)];
    });
    _saveCount = saveCount;
}
-(void)removeBlurBlurBackgorundToolbarFromSuperView:(void(^)(BOOL complition))SuccessBlock{
    [UIView animateWithDuration:0.3 animations:^{
        self.blurBackgroundToolbar.alpha =0;
    } completion:^(BOOL finished) {
        [self.blurBackgroundToolbar removeFromSuperview];
        if (SuccessBlock) {
            SuccessBlock(YES);
        }
    }];
}
-(void)addDataToDownloadArray:(id)data{
    [self.dataDownload addObject:data];
    self.saveCount++;
}

-(NSMutableAttributedString*)attributedStringForDownloadLabelWithDownloadedDataNumber:(NSNumber*)downloaded{
    
    NSString *downloadDataString = MHGalleryLocalizedString(@"shareview.download");
    NSString *numberTitle = [NSString stringWithFormat:MHGalleryLocalizedString(@"imagedetail.title.current"),downloaded,@(self.selectedRows.count)];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]initWithString:[NSString stringWithFormat:@"%@%@",downloadDataString,numberTitle]];
    [attributedString setAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:30]} range:NSMakeRange(0, downloadDataString.length)];
    
    [attributedString setAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Bold" size:20]} range:NSMakeRange(downloadDataString.length, numberTitle.length)];
    return attributedString;
}

-(void)cancelDownload{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    for (NSURLSession *session in self.sessions) {
        [session invalidateAndCancel];
    }
    [self removeBlurBlurBackgorundToolbarFromSuperView:nil];
}

-(void)getAllImagesForSelectedRows:(void(^)(NSArray *images))SuccessBlock
              saveDataToCameraRoll:(BOOL)saveToCameraRoll{
    
    BOOL containsVideo = NO;
    for (NSIndexPath *indexPath in self.selectedRows) {
        MHGalleryItem *item = [self itemForIndex:indexPath.row];
        
        if (item.galleryType == MHGalleryTypeVideo) {
            containsVideo = YES;
        }
    }
    self.sessions =[NSMutableArray new];

    if (saveToCameraRoll && containsVideo) {
        self.blurBackgroundToolbar = [[UIToolbar alloc]initWithFrame:self.view.bounds];
        self.blurBackgroundToolbar.alpha =0;
        self.blurBackgroundToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self.navigationController.view addSubview:self.blurBackgroundToolbar];
        
        UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(0, -35, self.blurBackgroundToolbar.frame.size.width, self.blurBackgroundToolbar.frame.size.height-35)];
        activityIndicatorView.color = [UIColor blackColor];
        activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [activityIndicatorView startAnimating];
        
        [self.blurBackgroundToolbar addSubview:activityIndicatorView];
        
        
        self.downloadDataLabel = [[UILabel alloc]initWithFrame:self.blurBackgroundToolbar.bounds];
        self.downloadDataLabel.textAlignment = NSTextAlignmentCenter;
        self.downloadDataLabel.numberOfLines = MAXFLOAT;
        self.downloadDataLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        self.downloadDataLabel.attributedText = [self attributedStringForDownloadLabelWithDownloadedDataNumber:@(0)];
        [self.blurBackgroundToolbar addSubview:self.downloadDataLabel];
        
        self.cancelDownloadButton = [[UIButton alloc]initWithFrame:CGRectMake(0, self.blurBackgroundToolbar.frame.size.height-50, self.view.frame.size.width, 44)];
        [self.cancelDownloadButton setTitle:MHGalleryLocalizedString(@"shareview.download.cancel") forState:UIControlStateNormal];
        [self.cancelDownloadButton setTitleColor:[UIColor colorWithRed:1 green:0.18 blue:0.33 alpha:1] forState:UIControlStateNormal];
        self.cancelDownloadButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
        [self.cancelDownloadButton addTarget:self action:@selector(cancelDownload) forControlEvents:UIControlEventTouchUpInside];
        [self.blurBackgroundToolbar addSubview:self.cancelDownloadButton];
        [UIView animateWithDuration:0.3 animations:^{
            self.blurBackgroundToolbar.alpha =1;
        }];
    }
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    self.dataDownload = [NSMutableArray new];
    
    self.finishedCallbackDownloadData = SuccessBlock;
    
    self.saveCount =0;
    
    __weak typeof(self) weakSelf = self;
    
    for (NSIndexPath *indexPath in self.selectedRows) {
        MHGalleryItem *item = [self itemForIndex:indexPath.row];
        
        if (item.galleryType == MHGalleryTypeVideo) {
            if (!saveToCameraRoll) {
                [self addDataToDownloadArray:item.URLString];
            }else{
                [[MHGallerySharedManager sharedManager] getURLForMediaPlayer:item.URLString successBlock:^(NSURL *URL, NSError *error) {
                    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
                    
                    __block NSURLSession *blockSession = session;
                    [self.sessions addObject:session];
                    [[session downloadTaskWithURL:URL completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                        if (error){
                            weakSelf.saveCount++;
                            return;
                        }
                        NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
                        NSURL *tempURL = [documentsURL URLByAppendingPathComponent:@"storeForShare.mp4"];
                        
                        NSError *moveItemError = nil;
                        [[NSFileManager defaultManager] moveItemAtURL:location toURL:tempURL error:&moveItemError];
                        
                        if (moveItemError) {
                            weakSelf.saveCount++;
                            return;
                        }
                        ALAssetsLibrary* library = [ALAssetsLibrary new];
                        [library writeVideoAtPathToSavedPhotosAlbum:tempURL
                                                    completionBlock:^(NSURL *assetURL, NSError *error){
                                                        NSError *removeError =nil;
                                                        [[NSFileManager defaultManager] removeItemAtURL:tempURL error:&removeError];
                                                        
                                                        [weakSelf.sessions removeObject:blockSession];
                                                        weakSelf.saveCount++;
                                                    }];
                    }] resume];
                }];
            }
            
        }
        
        if (item.galleryType == MHGalleryTypeImage) {
            if ([item.URLString rangeOfString:@"assets-library"].location != NSNotFound && item.URLString) {
                [[MHGallerySharedManager sharedManager] getImageFromAssetLibrary:item.URLString
                                                                       assetType:MHAssetImageTypeFull
                                                                    successBlock:^(UIImage *image, NSError *error) {
                                                                        [weakSelf addDataToDownloadArray:image];
                                                                    }];
            }else if (item.image) {
                [self addDataToDownloadArray:item.image];
            }else{
                [[SDWebImageManager sharedManager] downloadWithURL:[NSURL URLWithString:item.URLString]
                                                           options:SDWebImageContinueInBackground
                                                          progress:nil
                                                         completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                                                             [weakSelf addDataToDownloadArray:image];
                                                         }];
            }
        }
    }
}
-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                        duration:(NSTimeInterval)duration{
    if (toInterfaceOrientation == UIInterfaceOrientationPortrait) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                             target:self
                                                                                             action:@selector(cancelPressed)];
        self.navigationItem.rightBarButtonItem = nil;
        self.collectionView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-240);
        self.toolbar.frame = CGRectMake(0, self.view.frame.size.height-240, self.view.frame.size.width,240);
        self.tableViewShare.frame = CGRectMake(0, self.view.frame.size.height-230, self.view.frame.size.width, 240);
        self.gradientView.frame = CGRectMake(0, self.view.frame.size.height-240, self.view.frame.size.width,240);
    }else{
        self.tableViewShare.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 240);
        self.toolbar.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width,240);
        self.collectionView.frame = self.view.bounds;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Next"
                                                                                 style:UIBarButtonItemStyleBordered
                                                                                target:self
                                                                                action:@selector(showShareSheet)];
    }
    self.downloadDataLabel.frame = self.blurBackgroundToolbar.bounds;
    self.cancelDownloadButton.frame= CGRectMake(0, self.blurBackgroundToolbar.frame.size.height-50, self.view.frame.size.width, 44);

    [self.collectionView.collectionViewLayout invalidateLayout];
}
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    
    NSArray *visibleCells = [self sortObjectsWithFrame:self.collectionView.visibleCells];
    NSInteger numberToScrollTo =  visibleCells.count/2;
    MHMediaPreviewCollectionViewCell *cell =  (MHMediaPreviewCollectionViewCell*)visibleCells[numberToScrollTo];
    
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:cell.tag inSection:0]
                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                        animated:YES];
    
    if (self.isShowingShareViewInLandscapeMode) {
        self.showingShareViewInLandscapeMode = NO;
    }
    
}
-(void)cancelShareSheet{
    self.showingShareViewInLandscapeMode = NO;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                         target:self
                                                                                         action:@selector(cancelPressed)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Next"
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:self
                                                                            action:@selector(showShareSheet)];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.toolbar.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width,240);
        self.tableViewShare.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 240);
    }];
}
-(void)showShareSheet{
    self.showingShareViewInLandscapeMode = YES;
    self.navigationItem.rightBarButtonItem = nil;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                         target:self
                                                                                         action:@selector(cancelShareSheet)];
    
    self.toolbar.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width,240);
    self.tableViewShare.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 240);
    
    [UIView animateWithDuration:0.3 animations:^{
        self.toolbar.frame = CGRectMake(0, self.view.frame.size.height-240, self.view.frame.size.width,240);
        self.tableViewShare.frame = CGRectMake(0, self.view.frame.size.height-230, self.view.frame.size.width, 240);
    }];
    
}
-(void)saveImages:(NSArray*)object{
    [self getAllImagesForSelectedRows:^(NSArray *images) {
        for (UIImage *image in images) {
            if ([image isKindOfClass:[UIImage class]]) {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            }
        }
        [self cancelPressed];
    } saveDataToCameraRoll:YES];
}



-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if ([collectionView isEqual:self.collectionView]) {
        [collectionView deselectItemAtIndexPath:indexPath animated:NO];
        if ([self.selectedRows containsObject:indexPath]) {
            [self.selectedRows removeObject:indexPath];
        }else{
            [self.selectedRows addObject:indexPath];
        }
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
        
        [self.collectionView.delegate scrollViewDidScroll:self.collectionView];
        [UIView animateWithDuration:0.35 animations:^{
            [self.collectionView scrollToItemAtIndexPath:indexPath
                                        atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                animated:NO];
        } completion:^(BOOL finished) {
            [self.collectionView.delegate scrollViewDidScroll:self.collectionView];
        }];
        
        [self updateCollectionView];
        [self updateTitle];
    }else{
        MHShareItem *item = self.shareDataSource[collectionView.tag][indexPath.row];
        
        SEL selector = NSSelectorFromString(item.selectorName);
        
        SuppressPerformSelectorLeakWarning(
                                           [item.onViewController performSelector:selector
                                                                       withObject:self.selectedRows];
                                           );
        
        
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
