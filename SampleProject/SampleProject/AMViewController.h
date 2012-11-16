//
//  AMViewController.h
//  SampleProject
//
//  Created by Joan Martin on 11/15/12.
//  Copyright (c) 2012 AugiaMobile. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AMViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;

- (IBAction)operationBasedAction:(id)sender;
- (IBAction)asynchornousAction:(id)sender;

@end
