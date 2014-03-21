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
        _imagesToDownload = @[
        @"http://ocj.com/wp-content/uploads/2011/04/planetearth1.jpg",
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
    
    [self _refreshViewsData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark IBActions

- (IBAction)asynchornousAction:(id)sender
{
    NSURLRequest *urlRequest = [self _randomRequest];
    
    AMConnectionManager *connectionManager = [AMConnectionManager defaultManager];
    
    _oldConnectionKey = [connectionManager performRequest:urlRequest
                                                 priority:AMConnectionPriorityNormal
                                           progressStatus:^(NSDictionary *progressStatus) {
                                               
                                               CGFloat downloadProgress = [[progressStatus valueForKey:AMAsynchronousConnectionStatusDownloadProgressKey] floatValue];
                                               _progressBar.progress = downloadProgress;
                                               
                                           } completionBlock:^(NSURLResponse *response, NSData *data, NSError *error, NSInteger key) {
                                               
                                               if (!error)
                                                   [self _setImageFromData:data];
                                               
                                               [self _refreshViewsData];                                               
                                           }];

    [self _refreshViewsData];
}

- (IBAction)cancelLastConnection:(id)sender
{
    AMConnectionManager *connectionManager = [AMConnectionManager defaultManager];
    [connectionManager cancelRequestWithKey:_oldConnectionKey];
    
    [self performSelector:@selector(_refreshViewsData) withObject:nil afterDelay:0.1];
}

- (IBAction)stepperValueDidChange:(id)sender
{
    NSInteger value = _stepper.value;
    
    AMConnectionManager *connectionManager = [AMConnectionManager defaultManager];
    connectionManager.maxConcurrentConnectionCount = value;
    
    [self _refreshViewsData];
}

#pragma mark Private Method

- (NSURLRequest*)_randomRequest
{
    NSString *urlPath = [_imagesToDownload objectAtIndex:abs(arc4random())%_imagesToDownload.count];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlPath] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30];
    return urlRequest;
}

- (void)_setImageFromData:(NSData*)data
{
    UIImage *image = [[UIImage alloc] initWithData:data];
    _imageView.image = image;
}

- (void)_refreshViewsData
{
    AMConnectionManager *connectionManager = [AMConnectionManager defaultManager];
    
    _maxConcurrentConnectionCountLabel.text = [NSString stringWithFormat:@"%ld", (long)connectionManager.maxConcurrentConnectionCount];
    _activeOperationsLabel.text = [NSString stringWithFormat:@"%ld", (long)[[connectionManager operationQueueForIdentifier:nil] operationCount]];
}

@end
