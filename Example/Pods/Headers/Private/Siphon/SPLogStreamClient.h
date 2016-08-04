
@protocol SPLogStreamClientDelegate <NSObject>

@optional
- (void)logStreamDidOpen;
- (void)logStreamClosedWithCode:(NSInteger)code andReason:(NSString *)reason;
- (void)logStreamError:(NSError *)error;

@end

@interface SPLogStreamClient : NSObject

@property (weak, nonatomic) id <SPLogStreamClientDelegate> delegate;
@property (nonatomic) NSURL *streamerURL;

- (instancetype)initWithAppId:(NSString *)appId andAuthToken:(NSString *)authToken andHost:(NSString*)host andDelegate:(id)delegate;
- (instancetype)initWithAppId:(NSString *)appId andStreamerURL:(NSURL *)streamerURL andDelegate:(id)delegate;

- (void)close;
- (void)broadcastLog:(NSString *)logMessage;

@end