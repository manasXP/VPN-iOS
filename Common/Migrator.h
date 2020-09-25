#ifndef DNSCryptMigrator_h
#define DNSCryptMigrator_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(DNSCryptMigrator)
@interface Migrator : NSObject
+ (void) preflightCheck;
+ (void) resetLockPermissions;
@end

NS_ASSUME_NONNULL_END

#endif /* DNSCryptMigrator */
