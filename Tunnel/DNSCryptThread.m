#import "DNSCryptThread.h"
//@import CocoaLumberjack;

NS_ASSUME_NONNULL_BEGIN

//static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

NSString *const kDNSCryptProxyReady = @"DNSCryptProxyReady";

@interface DNSCryptThread ()
@end

@implementation DNSCryptThread
- (instancetype)init {
    return [self initWithArgument:nil];
}

- (instancetype)initWithArgument:(nullable NSString *)argument {
    self = [super init];
    if (!self)
        return nil;
    
    _dnsApp = DnscryptproxyMain(argument);
    
    self.name = @"DNSCrypt";
//    [DDLog addLogger:[DDOSLogger sharedInstance]]; // Uses os_log

    return self;
}

- (void)main {
    [self.dnsApp run:self];
}

- (void) proxyReady {
    [[NSNotificationCenter defaultCenter] postNotificationName:kDNSCryptProxyReady object:self];
}

- (void)closeIdleConnections {
    [self.dnsApp closeIdleConnections];
}

- (void)refreshServersInfo {
    [self.dnsApp refreshServersInfo];
}

- (void)stopApp {
    [self.dnsApp stop:nil];
}

- (void)logDebug:(NSString *)str {
//    DDLogDebug(@"%@: %@", self.name, str);
    [self.dnsApp logDebug:str];
}

- (void)logInfo:(NSString *)str {
//    DDLogInfo(@"%@: %@", self.name, str);
    [self.dnsApp logInfo:str];
}

- (void)logNotice:(NSString *)str {
//    DDLogInfo(@"%@: %@", self.name, str);
    [self.dnsApp logNotice:str];
}

- (void)logWarn:(NSString *)str {
//    DDLogWarn(@"%@: %@", self.name, str);
    [self.dnsApp logWarn:str];
}

- (void)logError:(NSString *)str {
//    DDLogError(@"%@: %@", self.name, str);
    [self.dnsApp logError:str];
}

- (void)logCritical:(NSString *)str {
//    DDLogError(@"%@: %@", self.name, str);
    [self.dnsApp logCritical:str];
}

- (void)logFatal:(NSString *)str {
//    DDLogError(@"%@: %@", self.name, str);
    [self.dnsApp logFatal:str];
}
@end

NS_ASSUME_NONNULL_END
