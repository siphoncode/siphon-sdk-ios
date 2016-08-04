
@protocol SPNotificationStreamClientDelegate <NSObject>

@optional
- (void)notificationStreamDidOpen;
- (void)notificationStreamClosedWithCode:(NSInteger)code andReason:(NSString *)reason;
- (void)notificationStreamError:(NSError *)error;

@required
- (void)receivedNotification:(NSString *)notificationType;
@end

@interface SPNotificationStreamClient : NSObject

@property (nonatomic, weak) id <SPNotificationStreamClientDelegate> delegate;
@property (nonatomic) NSURL *streamerURL;

- (instancetype)initWithAppId:(NSString *)appId andAuthToken:(NSString *)authToken andHost:(NSString *)host andDelegate:(id)delegate;
- (instancetype)initWithAppId:(NSString *)appId andStreamerURL:(NSURL *)streamerURL andDelegate:(id)delegate;

- (void)close;

@end