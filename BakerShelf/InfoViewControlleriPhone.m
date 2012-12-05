//
//  InfoViewControlleriPhone.m
//  Baker
//
//  Created by Andrew on 11/23/12.
//
//

#import "InfoViewControlleriPhone.h"
#import "ShelfViewController.h"
#import "UIConstants.h"
#import "UIColor+Extensions.h"

@interface InfoViewControlleriPhone ()

@end

@implementation InfoViewControlleriPhone

@synthesize dismissViewButtonPortrait;
@synthesize dismissViewButtonLandscape;

@synthesize webViewPortrait;
@synthesize webViewLandscape;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)dismissView:(id)sender {
	 NSLog(@"Closing Modal Info View");
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [dismissViewButtonPortrait setBackgroundColor:[UIColor colorWithHexString:INFO_VIEW_BUTTON_COLOR]];
    [dismissViewButtonPortrait setTitleColor:[UIColor colorWithHexString:INFO_VIEW_BUTTON_TEXT_COLOR] forState:UIControlStateNormal];
    [dismissViewButtonLandscape setBackgroundColor:[UIColor colorWithHexString:INFO_VIEW_BUTTON_COLOR]];
    [dismissViewButtonLandscape setTitleColor:[UIColor colorWithHexString:INFO_VIEW_BUTTON_TEXT_COLOR] forState:UIControlStateNormal];
    
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle]pathForResource:@"info.html" ofType:nil]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [webViewLandscape loadRequest:request];
    [webViewPortrait loadRequest:request];
    
    self.webViewPortrait.delegate = self;
    self.webViewLandscape.delegate = self;
    self.webViewPortrait.scrollView.delegate = self;
    self.webViewLandscape.scrollView.delegate = self;
    
    [webViewPortrait.scrollView setShowsHorizontalScrollIndicator:NO];
    [webViewLandscape.scrollView setShowsHorizontalScrollIndicator:NO];
}

-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
    if ( inType == UIWebViewNavigationTypeLinkClicked ) {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }
    
    return YES;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.x > 0)
        scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
	[dismissViewButtonPortrait release];
    [dismissViewButtonLandscape release];
    [webViewLandscape release];
    [webViewPortrait release];
    
    [super dealloc];
}

@end
