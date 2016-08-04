
#import "SPApiClient.h"
#import "SPConstants.h"
#import "SPNotificationStreamClient.h"
#import <SocketRocket/SRWebSocket.h>

@interface SPNotificationStreamClient() <SRWebSocketDelegate>

@property (nonatomic) SRWebSocket *ws;
@property (nonatomic) NSDate *notificationReceived;

- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code
           reason:(NSString *)reason
         wasClean:(BOOL)wasClean;

@end

@implementation SPNotificationStreamClient

#pragma mark Initialization methods

- (instancetype)initWithAppId:(NSString *)appId andAuthToken:(NSString *)authToken andHost:(NSString *)host andDelegate:(id)delegate {
    if (self = [super init]) {
        _delegate = delegate;
    }
    
    void (^apiError)(NSError *) = ^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate notificationStreamError:error];
        });
    };
    
    void (^retrievedStreamerURL)(NSURL *) = ^(NSURL *streamerURL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.streamerURL = streamerURL;
            SRWebSocket *ws = [[SRWebSocket alloc] initWithURL:streamerURL];
            ws.delegate = self;
            self.ws = ws;
            [self.ws open];
        });
    };
    SPApiClient *apiClient = [[SPApiClient alloc] initWithAppId:appId andAuthToken:authToken andHost:host];
    [apiClient fetchStreamerURLForConnectionType:@"notifications" withSuccess:retrievedStreamerURL andError:apiError];
    return self;
}

- (instancetype)initWithAppId:(NSString *)appId andStreamerURL:(NSURL *)streamerURL andDelegate:(id)delegate {
    if (self = [super init]) {
        _delegate = delegate;
    }
    SRWebSocket *ws = [[SRWebSocket alloc] initWithURL:streamerURL];
    ws.delegate = self;
    self.ws = ws;
    [self.ws open];
    return self;
}

#pragma mark Public API

- (void)close {
    [self.ws close];
}

#pragma mark SRWebsocketDelegate methods


- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    if ([self.delegate respondsToSelector:@selector(notificationStreamDidOpen)]) {
        [self.delegate notificationStreamDidOpen];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    if ([self.delegate respondsToSelector:@selector(notificationStreamClosedWithCode:andReason:)]) {
        [self.delegate notificationStreamClosedWithCode:code andReason:reason];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(notificationStreamError:)]) {
        [self.delegate notificationStreamError:error];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    if ([self.delegate respondsToSelector:@selector(notificationStreamError:)]) {
        // Extract the notification from the message (json) and call the appropriate
        // delegate method
        NSError *jsonError;
        NSData *messageData = [message dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *notification = [NSJSONSerialization JSONObjectWithData:messageData options:NSJSONReadingMutableContainers error:&jsonError];
        
        if (jsonError || !notification[@"type"]) {
            return;
        }
        
        // Limit the update notifications to 1 per second
        if (self.notificationReceived) {
            NSTimeInterval timeSinceLastNotification = -[self.notificationReceived timeIntervalSinceNow];
            if (timeSinceLastNotification > 1) {
                [self.delegate receivedNotification:notification[@"type"]];
                self.notificationReceived = [NSDate date];
            }
        } else {
            self.notificationReceived = [NSDate date];
            [self.delegate receivedNotification:notification[@"type"]];
        }
    }
}

@end