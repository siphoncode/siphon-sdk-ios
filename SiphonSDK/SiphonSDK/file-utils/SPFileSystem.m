
#import "SPFileSystem.h"
#import "SPConstants.h"

@interface SPFileSystem ()

+ (BOOL)removeFileIfItExists:(NSURL *)file;

@end

@implementation SPFileSystem

+ (BOOL)removeFileIfItExists:(NSURL *)file {
    // Initialize the error's userInfo should an error occur
    
    BOOL fileExists = [[NSFileManager defaultManager]
                       fileExistsAtPath:file.path
                       isDirectory:nil];
    
    if (fileExists) {
        BOOL deleted = [[NSFileManager defaultManager]
                        removeItemAtPath:file.path
                        error:nil];
        if (!deleted) {
            return NO;
        }
    }
    return YES;
}

+ (BOOL)copyFileFrom:(NSURL *)location to:(NSURL *)destination
               error:(NSError **)error{
    
    // Initialize the error's userInfo should an error occur
    NSDictionary *errorInfo = @{
                                NSLocalizedDescriptionKey:
                                    NSLocalizedString(@"An internal error occurred.", nil),
                                NSLocalizedRecoverySuggestionErrorKey:
                                    NSLocalizedString(@"Please contact our team.", nil)
                               };
    
    [SPFileSystem removeFileIfItExists:destination];
    
    NSURL *destinationDirectory = [destination URLByDeletingLastPathComponent];
    BOOL destinationDirectoryExists = [[NSFileManager defaultManager]
                                       fileExistsAtPath:destinationDirectory.path
                                       isDirectory:nil];
    if (!destinationDirectoryExists) {
        BOOL madeDestinationDirectory = [[NSFileManager defaultManager]
                                         createDirectoryAtPath:destinationDirectory.path
                                         withIntermediateDirectories:YES
                                         attributes:nil
                                         error:nil];
        if (!madeDestinationDirectory) {
            *error = [[NSError alloc]
                      initWithDomain:SP_ERROR_DOMAIN
                      code:SPFileSystemCopyError
                      userInfo:errorInfo];
            return NO;
        }
    }
    
    BOOL copied = [[NSFileManager defaultManager]
                   copyItemAtPath:location.path
                   toPath:destination.path
                   error:nil];
    
    if (!copied) {
        *error = [[NSError alloc]
                  initWithDomain:SP_ERROR_DOMAIN
                  code:SPFileSystemCopyError
                  userInfo:errorInfo];
        return NO;
    }
    
    return YES;
    
}

+ (BOOL)createFile:(NSURL *)file containingString:(NSString *)string {
    [SPFileSystem removeFileIfItExists:file];
    [[NSFileManager defaultManager] createFileAtPath:file.path contents:[string dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    return YES;
}

+ (BOOL)appendFileFrom:(NSURL *)file to:(NSURL *)destinationFile andReplaceOccurencesOf:(NSString *)oldString with:newString {
    // TODO
    return NO;
}

+ (BOOL)appendContentsOfFileFrom:(NSURL *)file to:(NSURL *)destinationFile
                           error:(NSError **)error {
    
    // Initialize the error's userInfo should an error occur
    NSDictionary *errorInfo = @{
                                NSLocalizedDescriptionKey:
                                    NSLocalizedString(@"An internal error occurred.", nil),
                                NSLocalizedRecoverySuggestionErrorKey:
                                    NSLocalizedString(@"Please contact our team.", nil)
                                };
    
    NSFileHandle *fromFile = [NSFileHandle
                              fileHandleForReadingFromURL:file
                              error:nil];
    
    if (!fromFile) {
        *error = [[NSError alloc]
                  initWithDomain:SP_ERROR_DOMAIN
                  code:SPFileSystemAppendFileToFileError
                  userInfo:errorInfo];
        return NO;
    }
    
    NSFileHandle *toFile = [NSFileHandle
                            fileHandleForWritingToURL:destinationFile
                            error:nil];
    
    if (!toFile) {
        *error = [[NSError alloc]
                  initWithDomain:SP_ERROR_DOMAIN
                  code:SPFileSystemAppendFileToFileError
                  userInfo:errorInfo];
        return NO;
    }
    
    NSData  *buffer;
    NSUInteger bufferSize = 512;
    NSUInteger offset = 0;
    
    [fromFile seekToFileOffset:0];
    BOOL dataRemaining = YES;
    
    while (dataRemaining) {
        // Go the the end of the to file
        [toFile seekToEndOfFile];
        [fromFile seekToFileOffset:offset];
        buffer = [fromFile readDataOfLength:bufferSize];
        
        if (buffer.length > 0) {
            [toFile writeData:buffer];
            offset = offset + buffer.length;
        } else {
            // Buffer length of zero implies that there is no more data to be
            // read
            dataRemaining = NO;
        }
    }
    
    [fromFile closeFile];
    [toFile closeFile];
    
    return YES;
}

+ (BOOL)appendString:(NSString *)string toFile:(NSURL *)file
               error:(NSError **)error {
    
    NSDictionary *errorInfo = @{
                                NSLocalizedDescriptionKey:
                                    NSLocalizedString(@"An internal error occurred.", nil),
                                NSLocalizedRecoverySuggestionErrorKey:
                                    NSLocalizedString(@"Please contact our team.", nil)
                                };
    
    NSFileHandle *toFile = [NSFileHandle
                            fileHandleForWritingToURL:file
                            error:nil];
    
    if (!toFile) {
        *error = [[NSError alloc]
                  initWithDomain:SP_ERROR_DOMAIN
                  code:SPFileSystemAppendStringToFileError
                  userInfo:errorInfo];
        return NO;
    }
    
    [toFile seekToEndOfFile];
    [toFile writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
    [toFile closeFile];
    
    return YES;
}

+ (BOOL)cleanUp:(NSURL *)directory error:(NSError **)error {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:directory.path]) {
        BOOL removed = [fileManager removeItemAtURL:directory error:nil];
        
        if (!removed) {
            NSDictionary *errorInfo = @{
                                        NSLocalizedDescriptionKey:
                                            NSLocalizedString(@"An internal error occurred.", nil),
                                        NSLocalizedRecoverySuggestionErrorKey:
                                            NSLocalizedString(@"Please contact our team.", nil)
                                        };
            *error = [[NSError alloc]
                      initWithDomain:SP_ERROR_DOMAIN
                      code:SPFileSystemCleanUpDirectoryError
                      userInfo:errorInfo];
            return NO;
        }
    }
    
    return YES;
}

@end