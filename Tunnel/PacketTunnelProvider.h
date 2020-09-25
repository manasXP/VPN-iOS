#import <NetworkExtension/NetworkExtension.h>
#import "DNSCryptThread.h"
#import "Reachability.h"

@interface PacketTunnelProvider : NEPacketTunnelProvider

@property (nonatomic, strong) DNSCryptThread *dns;
@property (nonatomic, strong) Reachability *reach;
@property (nonatomic, strong) NSDate *lastForcedResolversCheck;

@end
