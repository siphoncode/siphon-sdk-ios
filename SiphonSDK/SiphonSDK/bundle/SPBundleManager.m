
#import "SPBundleManager.h"
#import "SPBundleUtils.h"
#import "SPApiClient.h"
#import "SPFileSystem.h"
#import "SPConstants.h"
#import "SSZipArchive.h"
#import "FileHash.h"

#define TICK   NSDate *startTime = [NSDate date]
#define TOCK   NSLog(@"Time: %f", -[startTime timeIntervalSinceNow])

@interface SPBundleManager()

@property (nonatomic) NSString *appId;
@property (nonatomic) NSURL *appDirectory;
@property (nonatomic) NSURL *assetsDirectory;
@property (nonatomic) NSString *header;
@property (nonatomic) BOOL forSandbox;

@property (nonatomic) SPApiClient *apiClient;

- (instancetype)initWithAppId:(NSString *)appId andDelegate:(id)delegate forSandbox:(BOOL)forSandbox withDev:(BOOL)dev;

- (BOOL)processAssets:(NSData *)rawAssetData error:(NSError **)error;
- (BOOL)extractAssetDataFromRawAssetData:(NSURL *)rawDataURL andSaveInDirectory:(NSURL *)directory error:(NSError **)error;
- (void)replaceFooterWithFooter:(NSURL *)newFooterURL;
- (BOOL)resolveAssetsWithAssetFile:(NSURL *)assetListingFile andAssetDirectory:(NSURL *)assetsDirectory error:(NSError **)error;
- (BOOL)buildBundleFromHeader:(NSURL *)headerURL andFooter:(NSURL *)footerURL error:(NSError **)error;
- (BOOL)buildBundleWithError:(NSError **)error;
- (NSDictionary *)generateHashesForAssets;
- (NSArray *)getCurrentAssets;

@end

@implementation SPBundleManager

#pragma mark Factory Methods

+ (void)createBundleManagerWithAppId:(NSString *)appId andDelegate:(id)delegate forSandbox:(BOOL)forSandbox withDev:(BOOL)dev success:(void (^)(SPBundleManager *))success error:(void (^)(NSError *))error {
    
    if ([delegate respondsToSelector:@selector(bundleManagerIsInitializing)]) {
        [delegate bundleManagerIsInitializing];
    }
    // Run the corresponding initialization method and asynchronously
    // initialize the app directory
    SPBundleManager *bundleManager = [[SPBundleManager alloc]
                                      initWithAppId:appId
                                      andDelegate:delegate
                                      forSandbox:forSandbox
                                      withDev:dev];
    
    dispatch_queue_t bundleManagerQueue = dispatch_queue_create("Bundle Manager Queue", NULL);
    dispatch_async(bundleManagerQueue, ^{
        NSError *err;
        BOOL initialized = [bundleManager
                            initializeAppDirectoryAndReturnError:&err];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (initialized) {
                success(bundleManager);
            } else {
                error(err);
            }
        });
        
    });
    
}


#pragma mark Class Methods

+ (void)cleanAppDirectory:(NSString *)appId {
    NSArray *dirArray = [[NSFileManager defaultManager]
                         URLsForDirectory:NSApplicationSupportDirectory
                         inDomains:NSUserDomainMask];
    NSURL *appSupportDirectory = [dirArray firstObject];
    NSString *appDirectoryName = [NSString
                                  stringWithFormat:@"app_%@/", appId];
    NSURL *appDirectory = [NSURL URLWithString:appDirectoryName
                                 relativeToURL:appSupportDirectory];
    [SPFileSystem cleanUp:appDirectory error:nil];
}

#pragma mark Initializers

- (instancetype)initWithAppId:(NSString *)appId andDelegate:(id)delegate forSandbox:(BOOL)forSandbox withDev:(BOOL)dev {
    
    if (self = [super init]) {
        _appId = appId;
        _delegate = delegate;
        _forSandbox = forSandbox;
        _header = forSandbox ? @"sandbox-header" : @"header";
        _header = dev ? [NSString stringWithFormat:@"%@-dev", _header] : _header;
        // Construct the app directory name
        NSArray *dirArray = [[NSFileManager defaultManager]
                             URLsForDirectory:NSApplicationSupportDirectory
                             inDomains:NSUserDomainMask];
        NSURL *appSupportDirectory = [dirArray firstObject];
        NSString *appDirectoryName = [NSString
                                      stringWithFormat:@"app_%@/", self.appId];
        _appDirectory = [NSURL URLWithString:appDirectoryName
                               relativeToURL:appSupportDirectory];
        // Assets directory
        _assetsDirectory = [NSURL URLWithString:@"__siphon_assets/"
                                  relativeToURL:self.appDirectory];
        
        _bundleURL = [NSURL URLWithString:@"bundle"
                            relativeToURL:self.appDirectory];
    }
    return self;
}

- (BOOL)initializeAppDirectoryAndReturnError:(NSError **)error{
    // Checks if the app directory exists; if it doesn't, create it.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL appDirectoryExists = [fileManager fileExistsAtPath:self.appDirectory.path isDirectory:nil];
    NSString *bundledAssetsPath = [[NSBundle mainBundle] pathForResource:@"assets.zip" ofType:nil];
    BOOL bundledAssetsExist = [fileManager fileExistsAtPath:bundledAssetsPath isDirectory:nil];
    
    if (!appDirectoryExists) {
        // Will make an empty app directory
        [[NSFileManager defaultManager] createDirectoryAtURL:self.appDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    if (bundledAssetsExist && !self.forSandbox) {
        // Extract asset data, if it exists, and process the footer
        NSURL *bundledAssetsURL = [NSURL URLWithString:bundledAssetsPath];
        BOOL extracted = [self extractAssetDataFromRawAssetData:bundledAssetsURL
                                             andSaveInDirectory:self.appDirectory
                                                          error:error];
        if (!extracted) {
            return NO;
        }
        NSURL *footer = [NSURL URLWithString:@"bundle-footer" relativeToURL:self.appDirectory];
        [self replaceFooterWithFooter:footer];
    }
    
    // Succeeded in initializing the app directory (we created it or
    // it already exists)
    return YES;
}

#pragma mark Public API

- (void)loadLocalBundleWithSuccess:(void (^)(NSURL *bundleURL))successCallback andError:(void (^)(NSError *error))errorCallback; {
    
    dispatch_queue_t bundleManagerQueue = dispatch_queue_create("Bundle Manager Queue", NULL);
    
    dispatch_async(bundleManagerQueue, ^{
        NSError *err;
        BOOL bundleBuilt = [self buildBundleWithError:&err];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!bundleBuilt){
                errorCallback(err);
            } else {
                successCallback(self.bundleURL);
            }
        });
    });
}

- (void)loadBundleFromURL:(NSURL *)bundlerURL withSuccess:(void (^)(NSURL *bundleURL))successCallback andError:(void (^)(NSError *error))errorCallback;{
    // Note that the bundleURL in this context is the URL of the processed
    // bundle in the documents/app_<app_id> directory
    if ([self.delegate respondsToSelector:@selector(bundleIsLoading)]) {
        [self.delegate bundleIsLoading];
    }
    
    void (^apiError)(NSError *) = ^(NSError *error) {
        errorCallback(error);
    };
    
    
    // To be run when the assets have been downloaded
    void (^assetsAreDownloaded)(NSData *) = ^(NSData *assetData) {
        // Notify that the assets have been fetched
        if ([self.delegate respondsToSelector:@selector(fetchedAssets)]) {
            [self.delegate fetchedAssets];
        }
        
        // Asynchronously process the assets
        dispatch_queue_t bundleManagerQueue = dispatch_queue_create("Bundle Manager Queue", NULL);
        dispatch_async(bundleManagerQueue, ^{
            @autoreleasepool {
                NSError *error;
                BOOL processed = [self processAssets:assetData error:&error];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (processed) {
                        successCallback(self.bundleURL);
                        //[self.delegate bundleDidFinishLoading];
                    } else {
                        errorCallback(error);
                        //[self.delegate bundleFailedToLoad:error];
                    }
                });
            }
        });
    };
    
    dispatch_queue_t bundleManagerQueue = dispatch_queue_create("Bundle Manager Queue", NULL);
    dispatch_async(bundleManagerQueue, ^{
        NSDictionary *hashes = [self generateHashesForAssets];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSURLSessionDataTask *dataTask = [SPApiClient fetchAssetsForHashes:hashes from:bundlerURL withSuccess:assetsAreDownloaded andError:apiError];
            // Notify that the assets are being fetched
            if ([self.delegate respondsToSelector:@selector(fetchingAssets:)]) {
                [self.delegate fetchingAssets:dataTask];
            }
        });
        
    });
}

#pragma mark Asset Processing

// The meat of the bundle manager (call this asynchronously)
- (BOOL)processAssets:(NSData *)rawAssetData error:(NSError **)error {
    // Takes the raw zipped asset data returned by the api client and processes
    // it, saving it in it's appropriate location.
    // Create a temporary directory
    NSString *tmpDirName = [[NSProcessInfo processInfo] globallyUniqueString];
    NSURL *tmpDirectoryURL = [NSURL fileURLWithPath:
                              [NSTemporaryDirectory()
                               stringByAppendingPathComponent:tmpDirName]
                                        isDirectory:YES];
    
    BOOL createdTmpDirectory = [[NSFileManager defaultManager]
                                createDirectoryAtURL:tmpDirectoryURL
                                withIntermediateDirectories:YES
                                attributes:nil
                                error:nil];
    
    if (!createdTmpDirectory) {
        NSDictionary *errorInfo = @{
                                    NSLocalizedDescriptionKey:
                                        NSLocalizedString(@"An internal error occurred.", nil),
                                    NSLocalizedRecoverySuggestionErrorKey:
                                        NSLocalizedString(@"Please contact our team.", nil)
                                    };
        *error = [[NSError alloc]
                  initWithDomain:SP_ERROR_DOMAIN
                  code:SPBundleManagerCreateTempDirectoryError
                  userInfo:errorInfo];

        [SPFileSystem cleanUp:tmpDirectoryURL error:nil]; // Clean up and return
        return NO;
    }
    
    NSURL *filePath = [tmpDirectoryURL
                       URLByAppendingPathComponent:@"assets.zip"];
    
    // Save assets to the directory
    [rawAssetData writeToURL:filePath atomically:YES];
    
    
    // Extract asset data in tmp dir
    BOOL extracted = [self extractAssetDataFromRawAssetData:filePath
                                         andSaveInDirectory:tmpDirectoryURL
                                                      error:error];
    
    if (!extracted) {
        [SPFileSystem cleanUp:tmpDirectoryURL error:nil];
        return NO;
    }
    
    // Replace the old footer bundle with the new one
    NSURL *newFooter = [NSURL URLWithString:@"bundle-footer"
                                             relativeToURL:tmpDirectoryURL];
    [self replaceFooterWithFooter:newFooter];
    
    // Resolve the assets
    NSURL *assetsListingURL = [NSURL URLWithString:@"assets-listing"
                                   relativeToURL:tmpDirectoryURL];
    NSURL *tmpAssetsDirectory = [NSURL URLWithString:@"__siphon_assets/"
                                       relativeToURL:tmpDirectoryURL];
    
    BOOL assetsResolved = [self resolveAssetsWithAssetFile:assetsListingURL
                                         andAssetDirectory:tmpAssetsDirectory
                                                     error:error];
    
    if (!assetsResolved) {
        [SPFileSystem cleanUp:tmpDirectoryURL error:nil]; // Clean up and return
        return NO;
    }
    
    // Concatenate the bundle-header, bundle-middle and bundle-body
    BOOL bundleBuilt = [self buildBundleWithError:error];
    
    if (!bundleBuilt) {
        return NO;
    }
    
    return YES;
}

#pragma mark Helper Methods

- (BOOL)extractAssetDataFromRawAssetData:(NSURL *)rawDataURL
                      andSaveInDirectory:(NSURL *)directory
                                   error:(NSError **)error {
    
    NSString *zippedPath = rawDataURL.path;
    NSString *destinationDir = directory.path;
    
    BOOL unzipped = [SSZipArchive unzipFileAtPath:zippedPath
                                    toDestination:destinationDir];
    
    if (!unzipped) {
        NSDictionary *errorInfo = @{
                                    NSLocalizedDescriptionKey:
                                        NSLocalizedString(@"An internal error occurred.", nil),
                                    NSLocalizedRecoverySuggestionErrorKey:
                                        NSLocalizedString(@"Please contact our team.", nil)
                                    };
        *error = [[NSError alloc]
                  initWithDomain:SP_ERROR_DOMAIN
                  code:SPBundleManagerExtractAssetDataError
                  userInfo:errorInfo];
        return NO;
    }
    
    return YES;
}

- (void)replaceFooterWithFooter:(NSURL *)newFooterURL {
    NSURL *oldFooterURL = [NSURL URLWithString:@"bundle-footer"
                                 relativeToURL:self.appDirectory];
    
    NSString *footer = [NSString stringWithContentsOfFile:newFooterURL.path encoding:NSUTF8StringEncoding error:nil];
    
    // uri: "__SIPHON_ASSET_URL/images/logo.png" --> uri: "file://" + __GET_SIPHON_ASSET_DIR() + "/images/logo.png"
    NSString *processedFooter = [footer stringByReplacingOccurrencesOfString:@"__SIPHON_ASSET_URL"
                                                                  withString:@"file://\" + __GET_SIPHON_ASSET_DIR() + \""];
    [SPFileSystem createFile:oldFooterURL containingString:processedFooter];
}

- (BOOL)resolveAssetsWithAssetFile:(NSURL *)assetListingFile
                 andAssetDirectory:(NSURL *)assetsDirectory
                             error:(NSError **)error {
    // Takes an asset file and the directory containing the new assets and
    // resolves them with the current assets (Deletes those that are not
    // in the asset list, and moves the new ones over).
    
    NSString *assetListingFileContents = [NSString
                                          stringWithContentsOfURL:assetListingFile
                                          encoding:NSUTF8StringEncoding
                                          error:nil];
    
    // Get a dictionary of new asset {"images/myImage.png": assetURL, ...}
    // (In the temp directory supplied)
    NSMutableDictionary *newAssetNameURLDict = [[NSMutableDictionary alloc] init];
    
    // Recursively collect the files in the new assets directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *newAssetNames = [fileManager enumeratorAtPath:assetsDirectory.path];
    
    for (NSString *assetName in newAssetNames) {
        NSURL *assetURL = [[NSURL alloc] initWithString:assetName relativeToURL:assetsDirectory];
        BOOL isDirectory;
        [fileManager fileExistsAtPath:assetURL.path isDirectory:&isDirectory];
        if (!isDirectory) {
            [newAssetNameURLDict setObject:assetURL forKey:assetName];
        }
    }
    
    // Get a dictionary of current asset {"images/myImage.png": assetURL, ...}
    // (In the current app_<app_id>/assets directory)
    NSMutableDictionary *currentAssetNameURLDict = [[NSMutableDictionary alloc] init];
    
    NSDirectoryEnumerator *currentAssetNames = [fileManager enumeratorAtPath:self.assetsDirectory.path];
    
    for (NSString *assetName in currentAssetNames) {
        // Extract the asset name from the url (remove the path to the assets
        // directory)
        NSURL *assetURL = [[NSURL alloc] initWithString:assetName relativeToURL:assetsDirectory];
        BOOL isDirectory;
        [fileManager fileExistsAtPath:assetURL.path isDirectory:&isDirectory];
        if (!isDirectory) {
            [currentAssetNameURLDict setObject:assetURL forKey:assetName];
        }
    }
    
    NSArray *assetList = [assetListingFileContents
                          componentsSeparatedByCharactersInSet:
                          [NSCharacterSet newlineCharacterSet]];

    // Iterate through the current assets; if they do not appear in the
    // asset listing, remove them
    for (NSString *currentAssetName in currentAssetNameURLDict) {
        if (![assetList containsObject:currentAssetName]) {
            [SPBundleUtils removeAsset:currentAssetName fromAssetsDirectory:self.assetsDirectory];
        }
    }
    
    // Iteratate through the new assets and copy them over
    for (NSString *newAssetName in newAssetNameURLDict) {
        NSURL *assetDestination = [NSURL URLWithString:newAssetName
                                         relativeToURL:self.assetsDirectory];
        BOOL copied = [SPFileSystem
                       copyFileFrom:[newAssetNameURLDict objectForKey:newAssetName]
                       to:assetDestination
                       error:error];
        
        if (!copied) {
            return NO;
        }
    }
    
    return YES;
    
}

- (BOOL)buildBundleFromHeader:(NSURL *)headerURL andFooter:(NSURL *)footerURL error:(NSError **)error {
    NSURL *bundleURL = [NSURL URLWithString:@"bundle" relativeToURL:self.appDirectory];
    BOOL bundleExists = [[NSFileManager defaultManager]
                         fileExistsAtPath:bundleURL.path
                         isDirectory:nil];
    
    if (bundleExists) {
        [[NSFileManager defaultManager] removeItemAtURL:bundleURL error:nil];
    }
    
    NSBundle *siphonBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"SiphonResources" ofType:@"bundle"]];
    
    [[NSFileManager defaultManager] createFileAtPath:bundleURL.path
                                            contents:nil
                                          attributes:nil];
    
    NSString *preHeaderPath = [siphonBundle pathForResource:@"pre-header" ofType:nil];
    NSURL *preHeaderURL = [NSURL fileURLWithPath:preHeaderPath];
    
    
    NSString *preHeaderString = [NSString
                                 stringWithContentsOfURL:preHeaderURL
                                 encoding:NSUTF8StringEncoding error:nil];
    
    NSString *processedString = [preHeaderString
                                 stringByReplacingOccurrencesOfString:@"__SIPHON_APP_ID"
                                 withString:self.appId];
    processedString = [processedString stringByReplacingOccurrencesOfString:@"__SIPHON_ASSET_URL" withString:self.assetsDirectory.path];

    
    BOOL appendedMiddle = [SPFileSystem appendString:processedString
                                              toFile:bundleURL
                                               error:error];
    
    if (!appendedMiddle) {
        return NO;
    }
    
    // Append header
    BOOL appendedHeader = [SPFileSystem appendContentsOfFileFrom:headerURL
                                                              to:bundleURL
                                                           error:error];
    if (!appendedHeader) {
        return NO;
    }

    // Append footer
    BOOL appendedFooter = [SPFileSystem appendContentsOfFileFrom:footerURL
                                                              to:bundleURL
                                                           error:error];
    
    if (!appendedFooter) {
        return NO;
    }
    
    return YES;

}

- (BOOL)buildBundleWithError:(NSError **)error {
    NSBundle *siphonBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"SiphonResources" ofType:@"bundle"]];
    NSString *headerPath = [siphonBundle pathForResource:self.header ofType:nil];
    NSURL *headerURL = [NSURL fileURLWithPath:headerPath];
    
    NSURL *footerURL = [NSURL URLWithString:@"bundle-footer" relativeToURL:self.appDirectory];
    return [self buildBundleFromHeader:headerURL andFooter:footerURL error:error];
}

- (NSDictionary *)generateHashesForAssets {
    // Returns a {assets/assetName: assetHash, ...} dictionary
    NSArray *assets = [self getCurrentAssets];
    NSMutableDictionary *assetHashesDict = [[NSMutableDictionary alloc] init];
    
    NSString *hash;
    NSURL *assetURL;
    
    for (NSString *asset in assets) {
        assetURL = [NSURL URLWithString:asset relativeToURL:self.assetsDirectory];
        hash = [FileHash sha256HashOfFileWithURL:assetURL];
        assetHashesDict[asset] = hash;
    }
    NSMutableDictionary *assetHolder = [[NSMutableDictionary alloc] init];
    [assetHolder setObject:assetHashesDict forKey:@"asset_hashes"];
    
    return assetHolder;
}


- (NSArray *)getCurrentAssets {
    // Returns an array of current asset paths
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *currentAssetNames = [fileManager
                                                enumeratorAtPath:self.assetsDirectory.path];
    
    NSMutableArray *currentAssetPaths = [[NSMutableArray alloc] init];
    
    for (NSString *assetName in currentAssetNames) {
        // We only want files (not directories)
        NSURL *assetURL = [[NSURL alloc] initWithString:assetName relativeToURL:self.assetsDirectory];
        BOOL isDirectory;
        [fileManager fileExistsAtPath:assetURL.path isDirectory:&isDirectory];
        
        if (!isDirectory) {
            [currentAssetPaths addObject:assetURL.path];
        }
        
    }
    
    return currentAssetPaths;
}

@end