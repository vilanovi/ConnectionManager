ConnectionManager
=================

####Easy management for connections

Here I present a very simple framework to handle connections in a very effitien and easy way. Just give a **NSURLRequest** and you will have in return the result of a **NSURLConnection**. 

The connections are performed asynchronously and the framework allows you to:

* Cancel requests
* Set priorities
* Set a maximum number of concurrent connections 
* Keep tracking of the state of multiple connections runing at same time. 

Also, you can:

* Get feedback of downloading/uploading status (progress)
* Use/define credentials and trusted servers

The framework uses **NSOperationQueue** to perform concurrent connections and manipulate queued calls. 

Also, all the completions blocks are called in the main thread.

##Example of use

###Configuring the Connection Manager

First of all, lets get the instance of the connection manager:

	AMConnectionManager *connectionManager = [AMConnectionManager defaultManager];

Right now, we can configure if we want to display the iOS network activity indicator when some connection is being performed and the maximum number of concurrent connections for queue-based connections. 

    connectionManager.showsNetworkActivityIndicator = YES; 
    connectionManager.maxConcurrentConnectionCount = 10;

###Queue-Based Connections

Lets create a request first:

	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"..."]];

Then, we are going to send this request using a **queue-based operation**:
	
    NSInteger connectionKey = [connectionManager performRequest:urlRequest completionBlock:^(NSURLResponse *response, NSData *data, NSError *error, NSInteger key) {
		// Handle here the connection response
    }];

The `key` in the completionBlock is the key returned while calling the method (in this case `connectionKey`).

Now, we can change the priority of the request doing:

	[connectionManager changeToPriority:AMConnectionPriorityVeryHigh requestWithKey:connectionKey];

Also, we can cancel queued (but not started) connections by doing:

	[connectionManager cancelRequestWithKey:connectionKey]; 

###Simple Asynchronous Connections

If you want to have feedback about your connection (as download/uplaod progress) or use credentials or trusted servers, you can use simple asynchronous connections. A typical call should be:

	[connectionManager performRequest:urlRequest
                       progressStatus:^(NSDictionary *progressStatus) {
							// Get current status from the progressStatus dictionary
                       } completionBlock:^(NSURLResponse *response, NSData *data, NSError *error) {
							// Handle here the connection response
                       }];

From the `progressStatus` dictionary you can get:

* Download progress (float in [0,1]) using the key `AMAsynchronousConnectionStatusDownloadProgressKey`
* Upload progress (float in [0,1]) using the key `AMAsynchronousConnectionStatusUploadProgressKey`
* The headers of the response while availables using the key`AMAsynchronousConnectionStatusReceivedURLHeadersKey`

