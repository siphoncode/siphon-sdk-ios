extern NSString *const SP_API_URL;
extern NSString *const SP_HOST;
extern NSString *const SP_SCHEME;
extern NSString *const SP_API;
extern NSString *const SP_ERROR_DOMAIN;
// This version of the framework is only compatible with a given base version.
extern NSString *const SP_BASE_VERSION;
extern NSString *const SP_STORAGE_PREFIX;
extern NSString *const SP_PLATFORM;

typedef NS_ENUM(NSUInteger, SP_ERROR_CODE) {
    // SPApiClient errors (1xx)
    SPApiClientError = 100,
    SPApiClientUserError = 101,
    
    // SPFileSystem errors (2xx)
    SPFileSystemCopyError = 200,
    SPFileSystemAppendFileToFileError = 201,
    SPFileSystemAppendStringToFileError = 202,
    SPFileSystemCleanUpDirectoryError = 203,
    
    // SPBundleManager errors (3xx)
    SPBundleManagerInitializeAppDirectoryError = 300,
    SPBundleManagerCreateTempDirectoryError = 301,
    SPBundleManagerExtractAssetDataError = 302
};
