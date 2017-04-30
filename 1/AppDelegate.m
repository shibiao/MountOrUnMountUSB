//
//  AppDelegate.m
//  1
//
//  Created by Mac on 2017/4/30.
//  Copyright © 2017年 shibiao. All rights reserved.
//

#import "AppDelegate.h"
#import <IOKit/usb/IOUSBLib.h>
#import <IOKit/IOCFPlugIn.h>
@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[[NSWorkspace sharedWorkspace] notificationCenter]addObserver:self selector:@selector(deviceMounted:)  name: NSWorkspaceDidMountNotification object: nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter]addObserver:self selector:@selector(deviceUnmounted:)  name: NSWorkspaceDidUnmountNotification object: nil];
    
}
-(void)deviceMounted:(NSNotification *)notification{
//    NSArray * devices = [[NSWorkspace sharedWorkspace] mountedRemovableMedia];
//    NSLog(@"devices:%@",devices);
    NSLog(@"notification:%@",notification.userInfo);
    //Use -[NSFileManager mountedVolumeURLsIncludingResourceValuesForKeys:options:] instead."
    NSArray *array = @[NSURLThumbnailDictionaryKey,NSURLFileSizeKey,NSURLFileAllocatedSizeKey];
    NSArray *all = [[NSFileManager defaultManager]mountedVolumeURLsIncludingResourceValuesForKeys:array options:NSVolumeEnumerationSkipHiddenVolumes];
    NSLog(@"file:%@",all);
//    [self deviceAttributes];
    NSLog(@"attri:%@",[self deviceAttributes]);
}
-(void)deviceUnmounted:(NSNotification *)notification{
    
}
-(NSArray *) deviceAttributes

{
    
    mach_port_t masterPort;
    
    CFMutableDictionaryRef matchingDict;
    
    
    
    NSMutableArray * devicesAttributes = [NSMutableArray array];
    
    
    
    kern_return_t kr;
    
    
    
    //Create a master port for communication with the I/O Kit
    
    kr = IOMasterPort (MACH_PORT_NULL, &masterPort);
    
    if (kr || !masterPort)
        
    {
        
        NSLog (@"Error: Couldn't create a master I/O Kit port(%08x)", kr);
        
        return devicesAttributes;
        
    }
    
    
    
    //Set up matching dictionary for class IOUSBDevice and its subclasses
    
    matchingDict = IOServiceMatching (kIOUSBDeviceClassName);
    
    if (!matchingDict)
        
    {
        
        NSLog (@"Error: Couldn't create a USB matching dictionary");
        
        mach_port_deallocate(mach_task_self(), masterPort);
        
        return devicesAttributes;
        
    }
    
    
    
    io_iterator_t iterator;
    
    IOServiceGetMatchingServices (kIOMasterPortDefault, matchingDict, &iterator);
    
    
    
    io_service_t usbDevice = 0;
    
    
    
    //Iterate for USB devices
    
    while (usbDevice == IOIteratorNext (iterator))
        
    {
        
        IOCFPlugInInterface**plugInInterface = NULL;
        
        SInt32 theScore;
        
        
        
        //Create an intermediate plug-in
        
        kr = IOCreatePlugInInterfaceForService(usbDevice, kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID, &plugInInterface, &theScore);
        
        
        
        if ((kIOReturnSuccess != kr) || !plugInInterface)
            
            printf("Unable to create a plug-in (%08x)\n", kr);
        
        
        
        IOUSBDeviceInterface182 **dev = NULL;
        
        
        
        //Create the device interface
        
        HRESULT result = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID), (LPVOID)&dev);
        
        
        
        if (result || !dev)
            
            printf("Couldn't create a device interface (%08x)\n", (int) result);
        
        
        
        UInt16 vendorId;
        
        UInt16 productId;
        
        UInt16 releaseId;
        
        
        
        //Get configuration Ids of the device
        
        (*dev)->GetDeviceVendor(dev, &vendorId);
        
        (*dev)->GetDeviceProduct(dev, &productId);
        
        (*dev)->GetDeviceReleaseNumber(dev, &releaseId);
        
        
        
        
        
        UInt8 stringIndex;
        
        
        
        (*dev)->USBGetProductStringIndex(dev, &stringIndex);
        
        
        
        IOUSBConfigurationDescriptorPtr descriptor;
        
        
        
        (*dev)->GetConfigurationDescriptorPtr(dev, stringIndex, &descriptor);
        
        
        
        //Get Device name
        
        io_name_t deviceName;
        
        kr = IORegistryEntryGetName (usbDevice, deviceName);
        
        if (kr != KERN_SUCCESS)
            
        {
            
            NSLog (@"fail 0x%8x", kr);
            
            deviceName[0] = '\0';
            
        }
        
        
        
        NSString * name = [NSString stringWithCString:deviceName encoding:NSASCIIStringEncoding];
        
        
        
        //data will be initialized only for USB storage devices.
        
        //bsdName can be converted to mounted path of the device and vice-versa using DiskArbitration framework, hence we can identify the device through it's mounted path
        
        CFTypeRef data = IORegistryEntrySearchCFProperty(usbDevice, kIOServicePlane, CFSTR("BSD Name"), kCFAllocatorDefault, kIORegistryIterateRecursively);
        
        NSString* bsdName = [(__bridge NSString*)data substringToIndex:5];
        
        
        
        NSString* attributeString = @"";
        
        if(bsdName)
            
            attributeString = [NSString stringWithFormat:@"%@,%@,0x%x,0x%x,0x%x", name, bsdName, vendorId, productId, releaseId];
        
        else
            
            attributeString = [NSString stringWithFormat:@"%@,0x%x,0x%x,0x%x", name, vendorId, productId, releaseId];
        
        
        
        [devicesAttributes addObject:attributeString];
        
        
        
        IOObjectRelease(usbDevice);
        
        (*plugInInterface)->Release(plugInInterface);
        
        (*dev)->Release(dev);
        
    }
    
    
    
    //Finished with master port
    
    mach_port_deallocate(mach_task_self(), masterPort);
    
    masterPort = 0;
    
    
    
    return devicesAttributes;
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
