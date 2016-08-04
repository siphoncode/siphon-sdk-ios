
#import "SPLogStreamClient.h"
#import "SPApiClient.h"
#import <SocketRocket/SRWebSocket.h>

@interface SPLogStreamClient() <SRWebSocketDelegate>

@property (nonatomic) SRWebSocket *ws;
@property (nonatomic) NSMutableArray *logBuffer;

- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code
           reason:(NSString *)reason
         wasClean:(BOOL)wasClean;

- (void)broadcastBufferedLogs;

- (NSString *)processLogMessage:(NSString *)logMessage;

@end

@implementation SPLogStreamClient

#pragma mark Initialization methods

- (instancetype)initWithAppId:(NSString *)appId andAuthToken:(NSString *)authToken andHost:(NSString *)host andDelegate:(id)delegate {
    if (self = [super init]) {
        _delegate = delegate;
        _logBuffer = [[NSMutableArray alloc] init];
    }
    
    void (^apiError)(NSError *) = ^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(logStreamError:)]) {
                [self.delegate logStreamError:error];
            }
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
    [apiClient fetchStreamerURLForConnectionType:@"log_writer" withSuccess:retrievedStreamerURL andError:apiError];
    
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

- (void)broadcastLog:(NSString *)logMessage {
    NSString *processedLogMessage = [self processLogMessage:logMessage];
    [self.logBuffer addObject:processedLogMessage];
    [self broadcastBufferedLogs];
}

- (void)close {
    [self.ws close];
}

#pragma mark SRWebsocketDelegate methods

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    [self broadcastBufferedLogs];
    if ([self.delegate respondsToSelector:@selector(logStreamDidOpen)]) {
        [self.delegate logStreamDidOpen];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    if ([self.delegate respondsToSelector:@selector(logStreamClosedWithCode:andReason:)]) {
        [self.delegate logStreamClosedWithCode:code andReason:reason];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(logStreamError:)]) {
        [self.delegate logStreamError:error];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    return;
}

#pragma mark Helpers

- (NSString *)processLogMessage:(NSString *)logMessage {
    // Add a timestamp [hh:mm:ss dd/mm/yyyy] and truncate the message
    // if it needs to be.
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *currentTime = [dateFormatter stringFromDate:now];
    
    // Lose the single quote marks that RN puts around messages (first and
    // last characters).
    NSString *firstChar = [logMessage substringToIndex:1];
    NSString *lastChar = [logMessage substringFromIndex:[logMessage length] - 1];
    
    if ([firstChar isEqualToString:@"'"] && [lastChar isEqualToString:@"'"]) {
        logMessage = [logMessage substringFromIndex:1];
        logMessage = [logMessage substringToIndex:[logMessage length] - 1];
    }
    
    // Stick the timestamp on the front.
    logMessage = [NSString stringWithFormat:@"[%@] %@", currentTime, logMessage];
    
    int maxLength = 1024 * 25;
    if (logMessage.length > maxLength) {
        logMessage = [logMessage substringToIndex:maxLength];
        logMessage = [logMessage stringByAppendingString:@" ... [LOG TRUNCATED]\n"];
    }
    return logMessage;
}

- (void)broadcastBufferedLogs {
    if (self.ws.readyState == 1) {
        NSString *logMessage;
        //NSString *appendString;
        // Flush the buffer
        NSUInteger bufferSize = self.logBuffer.count;
        for (int i = 0; i < bufferSize; i++) {
            logMessage = self.logBuffer[0];
            [self.logBuffer removeObjectAtIndex:0];
            [self.ws send:logMessage];
        }
    }
}

@end