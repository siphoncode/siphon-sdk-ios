
#import "SPBundleUtils.h"

@implementation SPBundleUtils

// Takes an asset path relative to the given assets directory and removes it
// and any remaining empty subdirectories
+ (void)removeAsset:(NSString *)assetName fromAssetsDirectory:(NSURL *)assetsDirectory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Remove the asset itself
    NSURL *assetURL = [NSURL URLWithString:assetName relativeToURL:assetsDirectory];
    [fileManager removeItemAtURL:assetURL error:nil];
    
    // Get the parent directories up to the assets directory root
    NSMutableArray *assetNamePathComponents = [NSMutableArray
                                               arrayWithArray:[assetName componentsSeparatedByString:@"/"]];
    [assetNamePathComponents removeLastObject]; // Get rid of the asset
    
    NSString *directory;
    NSString *relativePath;
    NSURL *directoryURL;
    NSArray *directoryContents;
    
    for (directory in assetNamePathComponents) {
        relativePath= [assetNamePathComponents componentsJoinedByString:@"/"];
        directoryURL = [NSURL URLWithString:relativePath relativeToURL:assetsDirectory];
        directoryContents = [fileManager contentsOfDirectoryAtPath:directoryURL.path error:nil];
        
        if (directoryContents.count > 0) {
            // Stop here and leave the directory alone (it contains something)
            break;
        } else {
            // Remove the directory
            [fileManager removeItemAtURL:directoryURL error:nil];
        }
    }
}

@end