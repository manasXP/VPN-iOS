#import <NetworkExtension/NetworkExtension.h>
#import "DNSCryptThread.h"
#import "Reachability.h"

@interface PacketTunnelProvider : NEPacketTunnelProvider

@property (nonatomic, copy, null_resettable) DNSCryptThread *dns;
@property (nonatomic, copy, null_resettable) Reachability *reach;
@property (nonatomic, copy, null_resettable) NSDate *lastForcedResolversCheck;

@end
