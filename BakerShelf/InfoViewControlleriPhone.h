//
//  InfoViewControlleriPhone.h
//  Baker
//
//  Created by Andrew on 11/23/12.
//
//

#import <UIKit/UIKit.h>
#import "TPMultiLayoutViewController.h"

@interface InfoViewControlleriPhone : TPMultiLayoutViewController <UIWebViewDelegate,UIScrollViewDelegate>{
    UIButton *dismissViewButtonPortrait;
    UIButton *dismissViewButtonLandscape;
}

@property (nonatomic, retain) IBOutlet UIButton *dismissViewButtonPortrait;
@property (nonatomic, retain) IBOutlet UIButton *dismissViewButtonLandscape;

@property (nonatomic, strong) IBOutlet UIWebView *webViewPortrait;
@property (nonatomic, strong) IBOutlet UIWebView *webViewLandscape;

- (IBAction)dismissView:(id)sender;


@end
