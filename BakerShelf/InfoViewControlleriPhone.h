//
//  InfoViewControlleriPhone.h
//  Baker
//
//  Created by Andrew on 11/23/12.
//
//

#import <UIKit/UIKit.h>
#import "TPMultiLayoutViewController.h"

@interface InfoViewControlleriPhone : TPMultiLayoutViewController{
    UIButton *dismissViewButtonPortrait;
    UIButton *dismissViewButtonLandscape;
}

@property (nonatomic, retain) IBOutlet UIButton *dismissViewButtonPortrait;
@property (nonatomic, retain) IBOutlet UIButton *dismissViewButtonLandscape;

- (IBAction)dismissView:(id)sender;


@end
