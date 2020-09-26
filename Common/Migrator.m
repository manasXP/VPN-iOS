#import "Migrator.h"
#import <Dnscryptproxy/Dnscryptproxy.h>
#import "DNSConstants.h"

@import NetworkExtension;

NS_ASSUME_NONNULL_BEGIN

@interface Migrator ()
@end

@implementation Migrator

+ (void) preflightCheck {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *containerURL = [fileManager containerURLForSecurityApplicationGroupIdentifier:appGroup];
    
    NSString *dnscryptPath = [[containerURL path] stringByAppendingPathComponent:@"dnscrypt"];
    NSNumber* octal700 = [NSNumber numberWithUnsignedLong:0700] ;
    NSDictionary *attributes = @{ NSFilePosixPermissions: octal700 };
    if(![fileManager fileExistsAtPath:dnscryptPath]) {
        [fileManager createDirectoryAtPath:dnscryptPath withIntermediateDirectories:YES attributes:attributes error:NULL];
    }
    
    NSString *logsPath = [[containerURL path] stringByAppendingPathComponent:@"dnscrypt/logs"];
    if(![fileManager fileExistsAtPath:logsPath]) {
        [fileManager createDirectoryAtPath:logsPath withIntermediateDirectories:YES attributes:attributes error:NULL];
    }
    
    NSString *resolversPath = [[containerURL path] stringByAppendingPathComponent:@"dnscrypt/resolvers"];
    if(![fileManager fileExistsAtPath:resolversPath]) {
        [fileManager createDirectoryAtPath:resolversPath withIntermediateDirectories:YES attributes:attributes error:NULL];
    }
    
    //make config
    NSString *str = [NSString stringWithFormat:@"listen_addresses = [\"127.0.0.1:53\", \"[::1]:53\"]\n"
                     "ipv4_servers = true\n"
                     "ipv6_servers = true\n"
                     "max_clients = 250\n"
                     "dnscrypt_servers = true\n"
                     "doh_servers = true\n"
                     "require_dnssec = false\n"
                     "require_nolog = false\n"
                     "require_nofilter = false\n"
                     "force_tcp = false\n"
                     "tls_disable_session_tickets = false\n"
                     "dnscrypt_ephemeral_keys = false\n"
                     "timeout = 2500\n"
                     "cert_refresh_delay = 240\n"
                     "block_ipv6 = false\n"
                     "cache = true\n"
                     "cache_size = 256\n"
                     "cache_min_ttl = 600\n"
                     "cache_max_ttl = 86400\n"
                     "cache_neg_ttl = 60\n"
                     "fallback_resolver = \"9.9.9.9:53\"\n"
                     "ignore_system_dns = false\n"
                     "log_files_max_size = 10\n"
                     "log_files_max_age = 7\n"
                     "log_files_max_backups = 1\n"
                     "max_workers = 25\n"
                     "netprobe_timeout = 0\n"
                     "server_names = [\"customserver\"]\n"
                     "[static]\n"
                     "[static.\"customserver\"]\n"
                     "stamp = \"sdns://%@\"\n"
                     "[sources.\"public-resolvers\"]\n"
                     "url = \"https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v2/public-resolvers.md\"\n"
                     "minisign_key = \"RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3\"\n"
                     "cache_file = \"%@\"\n"
                     "format = \"v2\"\n"
                     "refresh_delay = 72\n"
                     "prefix = \"\"\n"
                     "\n"
                     "[query_log]\n"
                     "file = \"%@\"\n"
                     "format = \"tsv\"\n",
                     serverStamp,
                     [[containerURL path] stringByAppendingPathComponent:@"dnscrypt/resolvers/public-resolvers.md"],
                     [[containerURL path] stringByAppendingPathComponent:@"dnscrypt/logs/query.log"]
                     ];
    [str writeToFile:[[containerURL path] stringByAppendingPathComponent:@"dnscrypt/dnscrypt.toml"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

+ (void) resetLockPermissions {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *containerURL = [fileManager containerURLForSecurityApplicationGroupIdentifier:appGroup];
    
    // fix permissions for files
    NSArray *keys = @[NSURLIsDirectoryKey];
    NSURL *mainDir = [containerURL URLByAppendingPathComponent:@"dnscrypt"];
    NSDirectoryEnumerator *enumerator = [fileManager
                                         enumeratorAtURL:mainDir
                                         includingPropertiesForKeys:keys
                                         options:0
                                         errorHandler:^(NSURL *url, NSError *error) {
                                             return YES;
                                         }];
    
    for (NSURL *url in enumerator) {
        NSError *error;
        NSNumber *isDirectory = nil;
        if (![url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
            // handle error
        } else if (! [isDirectory boolValue]) {
            NSMutableDictionary *attr = [[fileManager attributesOfItemAtPath:[url path] error:nil] mutableCopy];
            [attr setObject:NSFileProtectionNone forKey:NSFileProtectionKey];
            [fileManager setAttributes:attr ofItemAtPath:[url path] error:nil];
        }
    }
}

@end

NS_ASSUME_NONNULL_END
