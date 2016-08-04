// Generic file system helpers

@interface SPFileSystem : NSObject

// Copy a file from one location to another, replacing an existent one if it
// exists and creating the intermediate directories if necessary.
+ (BOOL)copyFileFrom:(NSURL *)location to:(NSURL *)destination
               error:(NSError **)error;

// Creates or replaces the file with the given path with one containing the
// given string
+ (BOOL)createFile:(NSURL *)file containingString:(NSString *)string;

+ (BOOL)appendFileFrom:(NSURL *)file to:(NSURL *)destinationFile andReplaceOccurencesOf:(NSString *)oldString with:newString;

// Append the contents of a file at a given URL to another at a given URL.
+ (BOOL)appendContentsOfFileFrom:(NSURL *)file to:(NSURL *)destination
                           error:(NSError **)error;

// Takes a string and appends it to the file at the supplied URL
+ (BOOL)appendString:(NSString *)string toFile:(NSURL *)file
               error:(NSError **)error;

// Removes the directory at a given URL and all of its contents
+ (BOOL)cleanUp:(NSURL *)directory error:(NSError **)error;

@end