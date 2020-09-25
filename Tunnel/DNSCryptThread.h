#import <Foundation/Foundation.h>
#import <Dnscryptproxy/Dnscryptproxy.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kDNSCryptProxyReady;

NS_SWIFT_NAME(DNSCryptThread)
@interface DNSCryptThread : NSThread <DnscryptproxyCloakCallback>
- (instancetype)initWithArguments:(nullable NSArray<NSString *> *)arguments NS_DESIGNATED_INITIALIZER;
- (void)proxyReady;

- (void)stopApp;
- (void)closeIdleConnections;
- (void)refreshServersInfo;

- (void)logDebug:(NSString *)str;
- (void)logInfo:(NSString *)str;
- (void)logNotice:(NSString *)str;
- (void)logWarn:(NSString *)str;
- (void)logError:(NSString *)str;
- (void)logCritical:(NSString *)str;
- (void)logFatal:(NSString *)str;

@property (nonatomic, copy, null_resettable) DnscryptproxyApp *dnsApp;

@end

NS_ASSUME_NONNULL_END