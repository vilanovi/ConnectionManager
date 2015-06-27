//
//  AMViewController.m
//  SampleProject
//
//  Created by Joan Martin on 11/15/12.
//  Copyright (c) 2012 AugiaMobile. All rights reserved.
//

#import "AMViewController.h"

#import "AMConnectionManager.h"

@interface AMViewController ()

@end

@implementation AMViewController
{
    NSArray *_imagesToDownload;
    
    NSInteger _oldConnectionKey;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        _imagesToDownload = @[@"http://i.huffpost.com/gen/1860407/images/o-BLACK-FOOTED-CAT-KITTENS-facebook.jpg",
                              @"http://upload.wikimedia.org/wikipedia/commons/9/97/The_Earth_seen_from_Apollo_17.jpg",
                              @"http://www.diamondlantern.com/wp-content/uploads/2011/05/SXC-953432_13476061-No-Restr-EARTH.jpg",
                              @"http://storiesofcreativeecology.files.wordpress.com/2012/05/mother-earth-myspace-photobucket.jpg"
                              ];
        
        _oldConnectionKey = NSNotFound;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _progressBar.progress = 0.0f;
    
    AMConnectionManager *connectionManager = [AMConnectionManager defaultManager];
    _stepper.stepValue = 1;
    _stepper.value = connectionManager.maxConcurrentConnectionCount;
    _stepper.minimumValue = 1;
    _stepper.maximumValue = 1000000;
    
    [self am_refreshViewsData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark IBActions

- (IBAction)asynchornousAction:(id)sender
{
    NSURLRequest *urlRequest = [self am_randomRequest];
    
    AMConnectionManager *connectionManager = [AMConnectionManager defaultManager];
    
    _oldConnectionKey = [connectionManager performRequest:urlRequest
                                                 priority:AMConnectionPriorityNormal
                                           progressStatus:^(NSDictionary *progressStatus) {
                                               
                                               CGFloat downloadProgress = [[progressStatus valueForKey:AMAsynchronousConnectionStatusDownloadProgressKey] floatValue];
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   _progressBar.progress = downloadProgress;
                                               });
                                               
                                           } completionBlock:^(NSURLResponse *response, NSData *data, NSError *error, NSInteger key) {
                                               
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   if (!error)
                                                       [self am_setImageFromData:data];
                                                   
                                                   [self am_refreshViewsData];
                                               });
                                           }];

    [self am_refreshViewsData];
}

- (IBAction)cancelLastConnection:(id)sender
{
    AMConnectionManager *connectionManager = [AMConnectionManager defaultManager];
    [connectionManager cancelRequestWithKey:_oldConnectionKey];
    
    [self performSelector:@selector(am_refreshViewsData) withObject:nil afterDelay:0.1];
}

- (IBAction)stepperValueDidChange:(id)sender
{
    NSInteger value = _stepper.value;
    
    AMConnectionManager *connectionManager = [AMConnectionManager defaultManager];
    connectionManager.maxConcurrentConnectionCount = value;
    
    [self am_refreshViewsData];
}

#pragma mark Private Method

- (NSURLRequest*)am_randomRequest
{
    NSString *urlPath = [_imagesToDownload objectAtIndex:arc4random()%_imagesToDownload.count];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlPath] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30];
    return urlRequest;
}

- (void)am_setImageFromData:(NSData*)data
{
    UIImage *image = [[UIImage alloc] initWithData:data];
    _imageView.image = image;
}

- (void)am_refreshViewsData
{
    AMConnectionManager *connectionManager = [AMConnectionManager defaultManager];
    
    _maxConcurrentConnectionCountLabel.text = [NSString stringWithFormat:@"%ld", (long)connectionManager.maxConcurrentConnectionCount];
    _activeOperationsLabel.text = [NSString stringWithFormat:@"%ld", (long)[[connectionManager operationQueueForIdentifier:nil] operationCount]];
}

@end
