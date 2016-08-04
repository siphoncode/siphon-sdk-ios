
#import <Foundation/Foundation.h>

@interface FileHash : NSObject

+ (NSString *)sha256HashOfFileWithURL:(NSURL *)file;

@end