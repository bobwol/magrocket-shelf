//
//  ShelfViewController.m
//  Baker
//
//  ==========================================================================================
//
//  Copyright (c) 2010-2012, Davide Casali, Marco Colombo, Alessandro Morandi
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this list of
//  conditions and the following disclaimer.
//  Redistributions in binary form must reproduce the above copyright notice, this list of
//  conditions and the following disclaimer in the documentation and/or other materials
//  provided with the distribution.
//  Neither the name of the Baker Framework nor the names of its contributors may be used to
//  endorse or promote products derived from this software without specific prior written
//  permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
//  SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
//  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "ShelfViewController.h"
#import "ShelfManager.h"
#import "UICustomNavigationBar.h"
#import "UIConstants.h"
#import "UIColor+Extensions.h"
#import "Constants.h"
#import "InfoViewControlleriPad.h"
#import "InfoViewControlleriPhone.h"
#import "Reachability.h"

#import "BakerViewController.h"
#import "IssueViewController.h"

#import "JSONKit.h"
#import "NSData+Base64.h"

#ifdef GOOGLE_ANALYTICS
#import "GAI.h"
#endif

@implementation ShelfViewController

@synthesize issues;
@synthesize issueViewControllers;
@synthesize gridView;
@synthesize issuesManager;
@synthesize subscribeButton;
@synthesize refreshButton;
@synthesize infoButton;
@synthesize responseData = _responseData;

#pragma mark - Init

- (id)init
{
    self = [super init];
    if (self) {
        self.issues = [ShelfManager localBooksList];
    }
    return self;
}
- (id)initWithBooks:(NSArray *)currentBooks
{
    self = [super init];
    if (self) {
        self.issues = currentBooks;
        NSMutableArray *controllers = [NSMutableArray array];
        for (BakerIssue *issue in self.issues) {
            IssueViewController *controller = [self createIssueViewControllerWithIssue:issue];
            [controllers addObject:controller];
        }
        self.issueViewControllers = [NSMutableArray arrayWithArray:controllers];
    }
    return self;
}

#pragma mark - Memory management

- (void)dealloc
{
    [gridView release];
    [issueViewControllers release];
    [issues release];
    [subscribeButton release];
    [refreshButton release];
    [infoButton release];
    [_responseData release];

    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.responseData = [NSMutableData data];
    
    self.navigationItem.title = NSLocalizedString(@"SHELF_NAVIGATION_TITLE", nil);

    self.background = [[UIImageView alloc] init];

    self.gridView = [[AQGridView alloc] init];
    self.gridView.dataSource = self;
    self.gridView.delegate = self;
    self.gridView.backgroundColor = [UIColor clearColor];

    [self.view addSubview:self.background];
    [self.view addSubview:self.gridView];

    [self willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];
    [self.gridView reloadData];

    #ifdef BAKER_NEWSSTAND
    self.refreshButton = [[[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                       target:self
                                       action:@selector(handleRefresh:)]
                                      autorelease];

    self.subscribeButton = [[[UIBarButtonItem alloc]
                             initWithTitle: NSLocalizedString(@"SUBSCRIBE_BUTTON_TEXT", nil)
                             style:UIBarButtonItemStylePlain
                             target:self
                             action:@selector(handleFreeSubscription:)]
                            autorelease];
    
    if ([PRODUCT_ID_FREE_SUBSCRIPTION length] == 0) {
        self.subscribeButton.enabled = NO;
        NSLog(@"Subscription not enabled: constant PRODUCT_ID_FREE_SUBSCRIPTION not set");
    }
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:
                                              self.refreshButton,
                                              self.subscribeButton,
                                              nil];
    
        #ifdef INFO_VIEW
            UIImage *infoButtonImage = [UIImage imageNamed:@"info-icon.png"];
            
            self.infoButton = [[[UIBarButtonItem alloc]
                                initWithImage:infoButtonImage
                                style: UIBarButtonItemStylePlain
                                target:self
                                action:@selector(handleInfo:)]
                               autorelease];
            
            self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:
                                                       self.infoButton,
                                                       nil];
        #endif
    
    #endif
    
    //#ifdef GOOGLE_ANALYTICS
    //    [[GAI sharedInstance].defaultTracker track:@"Shelf Load"
    //                                                     withAction:nil
    //                                                      withLabel:NSLocalizedString(@"SHELF_NAVIGATION_TITLE", nil)
    //                                                      withValue:nil];
    //#endif
    
    #ifdef GOOGLE_ANALYTICS
        [[GAI sharedInstance].defaultTracker trackView:@"Shelf View"];
    #endif

}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setTranslucent:NO];
    [self willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];

    #ifdef BAKER_NEWSSTAND
    [self handleRefresh:nil];
    #endif

    for (IssueViewController *controller in self.issueViewControllers) {
        [controller refresh];
    }
}
- (NSInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}
- (BOOL)shouldAutorotate
{
    return YES;
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    int width  = 0;
    int height = 0;

    NSString *image = @"";
    CGSize size = [UIScreen mainScreen].bounds.size;

    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        width  = size.width;
        height = size.height - 64;
        image  = @"shelf-bg-portrait";
    } else if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        width  = size.height;
        height = size.width - 64;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            height = height + 12;
        }
        image  = @"shelf-bg-landscape";
    }

    if (size.height == 568) {
        image = [NSString stringWithFormat:@"%@-568h.png", image];
    } else {
        image = [NSString stringWithFormat:@"%@.png", image];
    }

    int bannerHeight = [ShelfViewController getBannerHeight];

    self.background.frame = CGRectMake(0, 0, width, height);
    self.background.image = [UIImage imageNamed:image];

    self.gridView.frame = CGRectMake(0, bannerHeight, width, height - bannerHeight);
}
- (IssueViewController *)createIssueViewControllerWithIssue:(BakerIssue *)issue
{
    IssueViewController *controller = [[[IssueViewController alloc] initWithBakerIssue:issue] autorelease];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleReadIssue:) name:@"read_issue_request" object:controller];
    return controller;
}

#pragma mark - Shelf data source

- (NSUInteger)numberOfItemsInGridView:(AQGridView *)aGridView
{
    return [issueViewControllers count];
}
- (AQGridViewCell *)gridView:(AQGridView *)aGridView cellForItemAtIndex:(NSUInteger)index
{
    CGSize cellSize = [IssueViewController getIssueCellSize];
    CGRect cellFrame = CGRectMake(0, 0, cellSize.width, cellSize.height);

    static NSString *cellIdentifier = @"cellIdentifier";
    AQGridViewCell *cell = (AQGridViewCell *)[self.gridView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
		cell = [[[AQGridViewCell alloc] initWithFrame:cellFrame reuseIdentifier:cellIdentifier] autorelease];
		cell.selectionStyle = AQGridViewCellSelectionStyleNone;

        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.backgroundColor = [UIColor clearColor];
	}

    IssueViewController *controller = [self.issueViewControllers objectAtIndex:index];
    UIView *removableIssueView = [cell.contentView viewWithTag:42];
    if (removableIssueView) {
        [removableIssueView removeFromSuperview];
    }
    [cell.contentView addSubview:controller.view];

    return cell;
}
- (CGSize)portraitGridCellSizeForGridView:(AQGridView *)aGridView
{
    return [IssueViewController getIssueCellSize];
}

#ifdef BAKER_NEWSSTAND
- (void)handleRefresh:(NSNotification *)notification {
    [self setrefreshButtonEnabled:NO];
    
    if (!self.issuesManager) {
        self.issuesManager = [[[IssuesManager alloc] initWithURL:NEWSSTAND_MANIFEST_URL] autorelease];
    }
    if([self.issuesManager refresh]) {
        self.issues = issuesManager.issues;
        
        [self.issues enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
            // NOTE: this block changes the issueViewController array while looping
            
            IssueViewController *existingIvc = nil;
            if (idx < [self.issueViewControllers count]) {
                existingIvc = [self.issueViewControllers objectAtIndex:idx];
            }
            
            BakerIssue *issue = (BakerIssue*)object;
            if (!existingIvc || ![[existingIvc issue].ID isEqualToString:issue.ID]) {
                IssueViewController *ivc = [self createIssueViewControllerWithIssue:issue];
                [self.issueViewControllers insertObject:ivc atIndex:idx];
                [self.gridView insertItemsAtIndices:[NSIndexSet indexSetWithIndex:idx] withAnimation:AQGridViewItemAnimationNone];
            }
        }];
    }
    else{
        Reachability *reach = [Reachability reachabilityWithHostname:@"www.google.com"];
        NetworkStatus internetStatus = [reach currentReachabilityStatus];
        
        if ((internetStatus != ReachableViaWiFi) && (internetStatus != ReachableViaWWAN))
        {
            UIAlertView *connAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"INTERNET_CONNECTION_UNAVAILABLE_TITLE", nil)
                                                                message:NSLocalizedString(@"INTERNET_CONNECTION_UNAVAILABLE_MESSAGE", nil)
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"INTERNET_CONNECTION_UNAVAILABLE_CLOSE", nil)
                                                      otherButtonTitles:nil];
            [connAlert show];
            [connAlert release];
        }
    }
    [self setrefreshButtonEnabled:YES];
}



- (IBAction)handleInfo:(id)sender {
    [self setInfoButtonEnabled:NO];
    
    NSLog(@"Opening Modal Info View");
    
    // We need to handle various different displays for the information modal views.  The iPad is much easier than the iPhone. 
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        InfoViewControlleriPad *infoViewController = [[InfoViewControlleriPad alloc]
                                                      initWithNibName:@"InfoViewControlleriPad"
                                                      bundle:nil];
        
        // Show View Controller as a Presentation Form Sheet for iPad
        // For iPhone, you cannot show as a Form Sheet, only a full page view.
        infoViewController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentModalViewController:infoViewController animated:YES];
        [infoViewController release];
        
    } else {
            // Because we need to deal with multiple types of iPhone Displays: Retina 3.5 Inch, Retina 4.0 Inch, Non Retina 3.5 Inch
            if ([UIScreen mainScreen].scale == 2.0f) {
                CGSize result = [[UIScreen mainScreen] bounds].size;
                CGFloat scale = [UIScreen mainScreen].scale;
                result = CGSizeMake(result.width * scale, result.height * scale);
                
                if(result.height == 960){
                    InfoViewControlleriPhone *infoViewController = [[InfoViewControlleriPhone alloc]
                                                                    initWithNibName:@"InfoViewControlleriPhone"
                                                                    bundle:nil];
                    
                    [self presentModalViewController:infoViewController animated:YES];
                    [infoViewController release];
                }
                if(result.height == 1136){
                    InfoViewControlleriPhone *infoViewController = [[InfoViewControlleriPhone alloc]
                                                                    initWithNibName:@"InfoViewControlleriPhone5"
                                                                    bundle:nil];
                    
                    [self presentModalViewController:infoViewController animated:YES];
                    [infoViewController release];
                }
            } else {
                InfoViewControlleriPhone *infoViewController = [[InfoViewControlleriPhone alloc]
                                                                initWithNibName:@"InfoViewControlleriPhone"
                                                                bundle:nil];
                
                [self presentModalViewController:infoViewController animated:YES];
                [infoViewController release];
            }
    }
    
    #ifdef GOOGLE_ANALYTICS
        [[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Shelf View"
                                                         withAction:nil
                                                          withLabel:@"View App Info"
                                                          withValue:nil];
    #endif
    
    [self setInfoButtonEnabled:YES];
}
#pragma mark - Store Kit

- (void)handleFreeSubscription:(NSNotification *)notification {
    if ([PRODUCT_ID_FREE_SUBSCRIPTION length] > 0) {
        [self setSubscribeButtonEnabled:NO];

        // Request "free subscription" product from App Store
        SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:PRODUCT_ID_FREE_SUBSCRIPTION]];
        productsRequest.delegate = self;
        [productsRequest start];
    } else {
        NSLog(@"Cannot subscribe: constant PRODUCT_ID_FREE_SUBSCRIPTION not set");
    }
}

-(void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    // Create a "payment" for the specified product (i.e. our free subscription)
    for(SKProduct *product in response.products) {
        SKPayment *payment = [SKPayment paymentWithProduct:product];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
    if ([response.invalidProductIdentifiers count] > 0) {
        NSLog(@"Invalid product identifiers: %@", response.invalidProductIdentifiers);
        [self setSubscribeButtonEnabled:YES];
    }
}

-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    // Verify whether store transactions (i.e. free subscription) were successful
    for(SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStateFailed:
                [self setSubscribeButtonEnabled:YES];
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStatePurchasing:
                break;
            case SKPaymentTransactionStatePurchased:
            case SKPaymentTransactionStateRestored:
                [self setSubscribeButtonEnabled:YES];
                [self completeTransaction:transaction];
                break;
            default:
                break;
        }
    }
}

-(void)completeTransaction:(SKPaymentTransaction *)transaction {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SUBSCRIPTION_SUCCESSFUL_TITLE", nil)
                                                    message:NSLocalizedString(@"SUBSCRIPTION_SUCCESSFUL_MESSAGE", nil)
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"SUBSCRIPTION_SUCCESSFUL_CLOSE", nil)
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];

    [self recordTransaction:transaction];

    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    #ifdef GOOGLE_ANALYTICS
        [[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Shelf View"
                                                         withAction:nil
                                                          withLabel:@"Completed Free Subscription"
                                                          withValue:nil];
    #endif
}

-(void)recordTransaction:(SKPaymentTransaction *)transaction {
    [[NSUserDefaults standardUserDefaults] setObject:transaction.transactionIdentifier forKey:@"receipt"];

    if ([PURCHASE_CONFIRMATION_URL length] > 0) {
        NSString *receiptData = [transaction.transactionReceipt base64EncodedString];
        NSDictionary *jsonDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  receiptData, @"receipt-data",
                                  nil];
        NSError *error = nil;
        
        NSString *jsonRequest = [jsonDict JSONString];
        
        NSLog(@"jsonRequest is %@", jsonRequest);       
        
        NSData *requestData = [NSData dataWithBytes:[jsonRequest UTF8String] length:[jsonRequest length]];
        
        if (error) {
            NSLog(@"Error generating receipt JSON: %@", error);
        } else {
            NSURL *requestURL = [NSURL URLWithString:PURCHASE_CONFIRMATION_URL];
            NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:requestURL];
            
            [req setHTTPMethod:@"POST"];
            [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [req setHTTPBody:requestData];

            NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
            if (conn) {
                NSLog(@"Posting App Store transaction receipt to %@", PURCHASE_CONFIRMATION_URL);
            } else {
                NSLog(@"Cannot connect to %@", PURCHASE_CONFIRMATION_URL);
            }
        }
        
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
        NSLog(@"didReceiveResponse");
        [self.responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"didFailWithError");
        NSLog([NSString stringWithFormat:@"Connection failed: %@", [error description]]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
        NSLog(@"connectionDidFinishLoading");
        NSLog(@"Succeeded! Received %d bytes of data",[self.responseData length]);

        NSString *data = [[[NSString alloc] initWithData:self.responseData encoding:NSASCIIStringEncoding] autorelease];
        NSLog(@"%@", data);
    
        // convert to JSON
        NSError *myError = nil;
        NSDictionary *res = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingMutableLeaves error:&myError];

        // show all values
        for(id key in res) {
    
                id value = [res objectForKey:key];
    
                NSString *keyAsString = (NSString *)key;
                NSString *valueAsString = (NSString *)value;
    
                NSLog(@"key: %@", keyAsString);
                NSLog(@"value: %@", valueAsString);
            }

        // extract specific value...
        //NSArray *results = [res objectForKey:@"success"];

        //for (NSDictionary *result in results) {
        //        NSString *message = [result objectForKey:@"message"];
        //        NSLog(@"message: %@", message);
        //}
     
}

-(void)failedTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"Payment transaction failure: %@", transaction.error);

    // Show an error, unless it was the user who cancelled the transaction
    if (transaction.error.code != SKErrorPaymentCancelled) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SUBSCRIPTION_FAILED_TITLE", nil)
                                                        message:[transaction.error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"SUBSCRIPTION_FAILED_CLOSE", nil)
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }

    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

#endif

#pragma mark - Navigation management

- (void)gridView:(AQGridView *)myGridView didSelectItemAtIndex:(NSUInteger)index
{
    [myGridView deselectItemAtIndex:index animated:NO];
}
- (void)readIssue:(BakerIssue *)issue
{
    BakerBook *book = nil;
    NSString *status = [issue getStatus];

    #ifdef BAKER_NEWSSTAND
    if (status == @"downloaded") {
        book = [[[BakerBook alloc] initWithBookPath:issue.path bundled:NO] autorelease];
        [self pushViewControllerWithBook:book];
    }
    #else
    if (status == @"bundled") {
        book = [issue bakerBook];
        [self pushViewControllerWithBook:book];
    }
    #endif
}
- (void)handleReadIssue:(NSNotification *)notification
{
    IssueViewController *controller = notification.object;
    [self readIssue:controller.issue];
}
-(void)pushViewControllerWithBook:(BakerBook *)book
{
    BakerViewController *bakerViewController = [[BakerViewController alloc] initWithBook:book];
    [self.navigationController pushViewController:bakerViewController animated:YES];
    [bakerViewController release];
}

#pragma mark - Buttons management

-(void)setrefreshButtonEnabled:(BOOL)enabled {
    self.refreshButton.enabled = enabled;
}

-(void)setInfoButtonEnabled:(BOOL)enabled {
    self.infoButton.enabled = enabled;
}

-(void)setSubscribeButtonEnabled:(BOOL)enabled {
    self.subscribeButton.enabled = enabled;
    if (enabled) {
        self.subscribeButton.title = NSLocalizedString(@"SUBSCRIBE_BUTTON_TEXT", nil);
    } else {
        self.subscribeButton.title = NSLocalizedString(@"SUBSCRIBE_BUTTON_DISABLED_TEXT", nil);
    }
}

#pragma mark - Helper methods

+ (int)getBannerHeight
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return 240;
    } else {
        return 104;
    }
}

@end
