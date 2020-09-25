#import "DNSCryptThread.h"
@import CocoaLumberjack;

NS_ASSUME_NONNULL_BEGIN

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

NSString *const kDNSCryptProxyReady = @"DNSCryptProxyReady";

@interface DNSCryptThread ()
@end

@implementation DNSCryptThread
- (instancetype)init {
    return [self initWithArguments:nil];
}

- (instancetype)initWithArguments:(nullable NSArray<NSString *> *)arguments {
    self = [super init];
    if (!self)
        return nil;
    
    _dnsApp = DnscryptproxyMain(arguments[0]);
    
    self.name = @"DNSCrypt";
    [DDLog addLogger:[DDOSLogger sharedInstance]]; // Uses os_log

    return self;
}

- (void)main {
    [_dnsApp run:self];
}

- (void) proxyReady {
    [[NSNotificationCenter defaultCenter] postNotificationName:kDNSCryptProxyReady object:self];
}

- (DnscryptproxyApp *)dnsApp {
    return _dnsApp;
}

- (void)closeIdleConnections {
    [_dnsApp closeIdleConnections];
}

- (void)refreshServersInfo {
    [_dnsApp refreshServersInfo];
}

- (void)stopApp {
    [_dnsApp stop:nil];
}

- (void)logDebug:(NSString *)str {
    DDLogDebug(@"%@: %@", self.name, str);
    [_dnsApp logDebug:str];
}

- (void)logInfo:(NSString *)str {
    DDLogInfo(@"%@: %@", self.name, str);
    [_dnsApp logInfo:str];
}

- (void)logNotice:(NSString *)str {
    DDLogInfo(@"%@: %@", self.name, str);
    [_dnsApp logNotice:str];
}

- (void)logWarn:(NSString *)str {
    DDLogWarn(@"%@: %@", self.name, str);
    [_dnsApp logWarn:str];
}

- (void)logError:(NSString *)str {
    DDLogError(@"%@: %@", self.name, str);
    [_dnsApp logError:str];
}

- (void)logCritical:(NSString *)str {
    DDLogError(@"%@: %@", self.name, str);
    [_dnsApp logCritical:str];
}

- (void)logFatal:(NSString *)str {
    DDLogError(@"%@: %@", self.name, str);
    [_dnsApp logFatal:str];
}
@end

NS_ASSUME_NONNULL_END
