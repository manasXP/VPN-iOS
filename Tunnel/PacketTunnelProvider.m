#import "PacketTunnelProvider.h"
#import "Migrator.h"
#import "NetTester.h"
#import "DNSConstants.h"

@implementation PacketTunnelProvider

- (NSUserDefaults *)sharedDefs {
    return [[NSUserDefaults alloc] initWithSuiteName:appGroup];
}

- (NSURL *)sharedDir {
    return [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:appGroup];
}

- (void)preflightCheck {
    [Migrator preflightCheck];
    [Migrator resetLockPermissions];
}

- (void)startTunnelWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSError *))completionHandler {
//    [self preflightCheck];
    NSURL *fileManagerURL = [self sharedDir];
    
    NSURL *configFile = [fileManagerURL URLByAppendingPathComponent: @"dnscrypt/dnscrypt.toml"];
    
    NSURL *logFile = [fileManagerURL URLByAppendingPathComponent: @"dnscrypt/logs/dns.log"];
    if([[NSFileManager defaultManager] fileExistsAtPath:[logFile path]]) {
        [[NSFileManager defaultManager] removeItemAtPath:[logFile path] error:nil];
    }
    
    NSURL *nxLogFile = [fileManagerURL URLByAppendingPathComponent: @"dnscrypt/logs/nx.log"];
    if([[NSFileManager defaultManager] fileExistsAtPath:[nxLogFile path]]) {
        [[NSFileManager defaultManager] removeItemAtPath:[nxLogFile path] error:nil];
    }
    
    NSURL *queryLogFile = [fileManagerURL URLByAppendingPathComponent: @"dnscrypt/logs/query.log"];
    if([[NSFileManager defaultManager] fileExistsAtPath:[queryLogFile path]]) {
        [[NSFileManager defaultManager] removeItemAtPath:[queryLogFile path] error:nil];
    }
    
    NSURL *blockedLogFile = [fileManagerURL URLByAppendingPathComponent: @"dnscrypt/logs/blocked.log"];
    if([[NSFileManager defaultManager] fileExistsAtPath:[blockedLogFile path]]) {
        [[NSFileManager defaultManager] removeItemAtPath:[blockedLogFile path] error:nil];
    }
    
    NSURL *whiteLogFile = [fileManagerURL URLByAppendingPathComponent: @"dnscrypt/logs/whitelist.log"];
    if([[NSFileManager defaultManager] fileExistsAtPath:[whiteLogFile path]]) {
        [[NSFileManager defaultManager] removeItemAtPath:[whiteLogFile path] error:nil];
    }
    
    __weak typeof(self) weakSelf = self;
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:[configFile path]]) {
        NEPacketTunnelNetworkSettings *networkSettings = [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress: @"127.0.0.1" ];
        
        [self setTunnelNetworkSettings:networkSettings completionHandler:^(NSError * _Nullable error) {
            if (error) {
                completionHandler(error);
            } else {
                completionHandler(nil);
            }
        }];
    } else {
        self.reach = [Reachability reachabilityForInternetConnection];
        
        [[NSNotificationCenter defaultCenter] addObserver:weakSelf selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
        
        NEPacketTunnelNetworkSettings *networkSettings = [self getNetworkSettings];
                
        BOOL skipWaitResolvers = NO;
        
        if (![self.reach isReachable] || [self.reach isConnectionRequired]) {
            skipWaitResolvers = YES;
        }
                
        self.dns = [[DNSCryptThread alloc] initWithArgument:[configFile path]];
        
        if (skipWaitResolvers) {
            [self startProxy];
            [self logNotice:@"Skipping available resolvers check, tell iOS we are ready"];
            
            [self setTunnelNetworkSettings:networkSettings completionHandler:^(NSError * _Nullable error) {
                if (error) {
                    completionHandler(error);
                } else {
                    weakSelf.lastForcedResolversCheck = [NSDate date];
                    [weakSelf.reach startNotifier];
                    completionHandler(nil);
                }
            }];
        } else {
            [self logWarn:@"We need to resolve a proxy"];
            [[NSNotificationCenter defaultCenter] addObserverForName:kDNSCryptProxyReady
                                                              object:nil
                                                               queue:[NSOperationQueue mainQueue]
                                                          usingBlock:^(NSNotification *note) {
                                                   
                                                   [weakSelf logInfo:@"Found available resolvers, tell iOS we are ready"];
                                                   
                                                   [weakSelf setTunnelNetworkSettings:networkSettings completionHandler:^(NSError * _Nullable error) {
                                                       if (error) {
                                                           completionHandler(error);
                                                       } else {
                                                           weakSelf.lastForcedResolversCheck = [NSDate date];
                                                           [weakSelf.reach startNotifier];
                                                           completionHandler(nil);
                                                       }
                                                   }];
                                               }];
            [self startProxy];
            [self logInfo:@"Waiting for available resolvers check."];
        }
    }
}

- (void)startProxy {
    [self logInfo:@"Starting proxy..."];
    [self.dns start];
    [self logInfo:[NSString stringWithFormat:@"Current reachability is [%@]", [_reach currentReachabilityFlags]]];
}

- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler {
    [self.reach stopNotifier];
    [self.dns stopApp];
    completionHandler();
    exit(EXIT_SUCCESS);
}

- (void)sleepWithCompletionHandler:(void (^)(void))completionHandler {
    completionHandler();
}

- (void)wake {
    BOOL ok = YES;
    
    if (self.lastForcedResolversCheck) {
        NSDate *curTime = [NSDate date];
        if ([curTime timeIntervalSinceDate:self.lastForcedResolversCheck] < 60.0)
            ok = NO;
    }
    
    if (ok)
        [self reactivateTunnel: NO];
}

- (void)reachabilityChanged:(NSNotification *)note {
    Reachability *r = (Reachability*) note.object;
    [self logInfo:[NSString stringWithFormat:@"Reachability changed to [%@]", [r currentReachabilityFlags]]];
    
    self.reasserting = YES;
    
    __strong typeof(self) strongSelf = self;
    [self setTunnelNetworkSettings:nil completionHandler:^(NSError * _Nullable error) {
        [strongSelf reactivateTunnel:NO];
    }];
}

- (void)refreshServers {
    [self.dns closeIdleConnections];
    [self.dns refreshServersInfo];
}

- (void)reactivateTunnel:(BOOL)isInitialize {
    __weak typeof(self) weakSelf = self;
    self.reasserting = YES;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSURL *fileManagerURL = [self sharedDir];
    
    NSURL *configFile = [fileManagerURL URLByAppendingPathComponent: @"dnscrypt/dnscrypt.toml"];
    
    if(![fileManager fileExistsAtPath:[configFile path]]) {
        NEPacketTunnelNetworkSettings *networkSettings = [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress: @"127.0.0.1" ];
        
        [self setTunnelNetworkSettings:networkSettings completionHandler:^(NSError * _Nullable error) {
            weakSelf.reasserting = NO;
        }];
    } else {
        [self refreshServers];
        
        NEPacketTunnelNetworkSettings *networkSettings = [self getNetworkSettings];
        
        self.lastForcedResolversCheck = [NSDate date];
        
        [self setTunnelNetworkSettings:networkSettings completionHandler:^(NSError * _Nullable error) {
            weakSelf.reasserting = NO;
        }];
    }
}

- (NEPacketTunnelNetworkSettings *)getNetworkSettings {
    
    BOOL hasIPv4 = NO;
    BOOL hasIPv6 = NO;
    
    NSString *net_type = @"2";
    
    if ([net_type isEqualToString:@"1"]) {
        hasIPv6 = YES;
        hasIPv4 = YES;
    } else if ([net_type isEqualToString:@"2"]) {
        hasIPv4 = YES;
    } else if ([net_type isEqualToString:@"3"]) {
        hasIPv6 = YES;
    } else {
        NSInteger net_status = [NetTester status];
        if (net_status == NET_TESTER_IPV6_CONN) {
            hasIPv6 = YES;
        } else if (net_status == NET_TESTER_DUAL_CONN) {
            hasIPv6 = YES;
            hasIPv4 = YES;
        } else {
            hasIPv4 = YES;
        }
    }
    
    NEPacketTunnelNetworkSettings *networkSettings = [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress: hasIPv6 ? @"::1" : @"127.0.0.1" ];
        
    if (hasIPv4) {
        NEIPv4Settings *ipv4Settings = [[NEIPv4Settings alloc] initWithAddresses:@[@"192.0.2.1"] subnetMasks:@[@"255.255.255.0"]];
        networkSettings.IPv4Settings = ipv4Settings;
    }
    
    if (hasIPv6) {
        NEIPv6Settings *ipv6Settings = [[NEIPv6Settings alloc] initWithAddresses:@[@"fdc1:c10:ac:1::1"] networkPrefixLengths:@[@(64)]];
        networkSettings.IPv6Settings = ipv6Settings;
    }
    
    NEDNSSettings *dnsSettings;
    if (hasIPv4 && hasIPv6) {
        dnsSettings = [[NEDNSSettings alloc] initWithServers: @[@"127.0.0.1", @"::1"]];
    } else if (hasIPv6) {
        dnsSettings = [[NEDNSSettings alloc] initWithServers: @[@"::1"]];
    } else {
        dnsSettings = [[NEDNSSettings alloc] initWithServers: @[@"127.0.0.1"]];
    }
    
    dnsSettings.matchDomains = @[@""];
    networkSettings.DNSSettings = dnsSettings;
    
    return networkSettings;
}

- (void)logDebug:(NSString *)str {
    [_dns logDebug:str];
}

- (void)logInfo:(NSString *)str {
    [self.dns logInfo:str];
}

- (void)logNotice:(NSString *)str {
    [self.dns logNotice:str];
}

- (void)logWarn:(NSString *)str {
    [self.dns logWarn:str];
}

- (void)logError:(NSString *)str {
    [self.dns logError:str];
}

- (void)logCritical:(NSString *)str {
    [self.dns logCritical:str];
}

- (void)logFatal:(NSString *)str {
    [self.dns logFatal:str];
}

@end
