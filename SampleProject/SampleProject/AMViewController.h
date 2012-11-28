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

@property (weak, nonatomic) IBOutlet UILabel *activeOperationsLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxConcurrentConnectionCountLabel;
@property (weak, nonatomic) IBOutlet UIStepper *stepper;

- (IBAction)asynchornousAction:(id)sender;
- (IBAction)cancelLastConnection:(id)sender;
- (IBAction)stepperValueDidChange:(id)sender;

@end
