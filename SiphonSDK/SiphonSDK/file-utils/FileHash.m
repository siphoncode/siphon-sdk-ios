
#import "FileHash.h"

#import <CommonCrypto/CommonDigest.h>
#include <CoreFoundation/CoreFoundation.h>
#include <stdint.h>
#include <stdio.h>

static const size_t FileHashDefaultChunkSizeForReadingData = 4096;

@implementation FileHash

+ (NSString *)sha256HashOfFileWithURL:(NSURL *)file {
    
    NSString *result;
    
    CFURLRef fileURL = (__bridge CFURLRef)file;
    CFReadStreamRef readStream = fileURL ?
        CFReadStreamCreateWithFile(kCFAllocatorDefault, fileURL) : NULL;
    BOOL didOpenStream = readStream ? (BOOL)CFReadStreamOpen(readStream) : NO;
    
    if (didOpenStream) {
        // Set the chunk size
        const size_t chunkSizeForReadingData = FileHashDefaultChunkSizeForReadingData;
        // Declare and initialise a hashObj (struct)
        CC_SHA256_CTX hashObj;
        CC_SHA256_Init(&hashObj);
        
        // Feed the data to the hash object
        BOOL hasMoreData = YES;
        
        while (hasMoreData) {
            uint8_t buffer[chunkSizeForReadingData];
            CFIndex readBytesCount = CFReadStreamRead(readStream,
                                                      (UInt8 *)buffer,
                                                      (CFIndex)sizeof(buffer));
            if (readBytesCount == -1) {
                // We're done here so break
                break;
            } else if (readBytesCount == 0) {
                // No more data
                hasMoreData = NO;
            } else {
                CC_SHA256_Update(&hashObj, (const void*)buffer,
                                 (CC_LONG)readBytesCount);
            }
        }
        
        unsigned char digest[CC_SHA256_DIGEST_LENGTH];
        CC_SHA256_Final(digest, &hashObj);
        
        // Close the read stream.
        CFReadStreamClose(readStream);
        
        if (!hasMoreData) {
            char hash[2 * sizeof(digest) + 1];
            for (size_t i = 0; i < sizeof(digest); ++i) {
                snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
            }
            result = [NSString stringWithUTF8String:(char *)hash];
        }
    }
    
    if (readStream) {
        CFRelease(readStream);
    }
    return result;
}

@end