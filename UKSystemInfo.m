//
//  UKSystemInfo.m
//  UKSystemInfo
//
//  Created by Uli Kusterer on 23.09.04.
//  Copyright 2004 M. Uli Kusterer. Uli Kusterer
//
//	This software is provided 'as-is', without any express or implied
//	warranty. In no event will the authors be held liable for any damages
//	arising from the use of this software.
//
//	Permission is granted to anyone to use this software for any purpose,
//	including commercial applications, and to alter it and redistribute it
//	freely, subject to the following restrictions:
//
//	   1. The origin of this software must not be misrepresented; you must not
//	   claim that you wrote the original software. If you use this software
//	   in a product, an acknowledgment in the product documentation would be
//	   appreciated but is not required.
//
//	   2. Altered source versions must be plainly marked as such, and must not be
//	   misrepresented as being the original software.
//
//	   3. This notice may not be removed or altered from any source
//	   distribution.
//

#import "UKSystemInfo.h"
#include <sys/types.h>
#include <sys/sysctl.h>

unsigned	UKPhysicalRAMSize(void)
{
	return (unsigned) (([NSProcessInfo.processInfo physicalMemory] / 1024ULL) / 1024ULL);
}


NSString*	UKSystemVersionString(void)
{
	static NSString*	sSysVersionCocoaStr = nil;
	if( !sSysVersionCocoaStr )
	{
		sSysVersionCocoaStr = [[[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"] objectForKey:@"ProductVersion"] retain];
	}
	return sSysVersionCocoaStr;
}


void	UKGetSystemVersionComponents( SInt32* outMajor, SInt32* outMinor, SInt32* outBugfix )
{
	NSArray		*	sysVersionComponents = [UKSystemVersionString() componentsSeparatedByString: @"."];
	
	if( sysVersionComponents.count > 0 )
		*outMajor = [[sysVersionComponents objectAtIndex: 0] intValue];
	if( sysVersionComponents.count > 1 )
		*outMinor = [[sysVersionComponents objectAtIndex: 1] intValue];
	if( sysVersionComponents.count > 2 )
		*outBugfix = [[sysVersionComponents objectAtIndex: 2] intValue];
}


long	UKSystemVersion(void)
{
	SInt32		sysVersion, major = 0, minor = 0, bugfix = 0, bcdMajor = 0;
	
	UKGetSystemVersionComponents( &major, &minor, &bugfix );
	
	if( bugfix > 9 )
		bugfix = 9;
	if( minor > 9 )
		minor = 9;
	bcdMajor = major % 10;
	while( major >= 10 )
	{
		major -= 10;
		bcdMajor += 16;
	}
	
	sysVersion = (bcdMajor << 8) | (minor << 4) | bugfix;
	printf( "%x\n", sysVersion );
	
	return sysVersion;
}


unsigned	UKClockSpeed(void)
{
	unsigned	count = 0;
	size_t		size = sizeof(count);

	if( sysctlbyname( "hw.cpufrequency_max", &count, &size, NULL, 0 ) )
		return 1;

	return count / 1000000;
}


unsigned	UKCountCores(void)
{
	unsigned	count = 0;
	size_t		size = sizeof(count);

	if( sysctlbyname( "hw.ncpu", &count, &size, NULL, 0 ) )
		return 1;

	return count;
}


NSString*	UKMachineName(void)
{
	static NSString*	cpuName = nil;
	if( cpuName )
		return cpuName;
	
	char		machineName[256] = {};
	int			modelInfo[2] = { CTL_HW, HW_MODEL };
	size_t		modelSize = sizeof(machineName) -1;
	if( sysctl(modelInfo, 2, machineName, &modelSize, NULL, 0 ) != 0 )
		return nil;
	
	NSString*	internalName = [NSString stringWithUTF8String: machineName];
	
	static NSDictionary* translationDictionary = nil;
	if( !translationDictionary )
		translationDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
				@"PowerMac 8500/8600",@"AAPL,8500",
				@"PowerMac 9500/9600",@"AAPL,9500",
				@"PowerMac 7200",@"AAPL,7200",
				@"PowerMac 7200/7300",@"AAPL,7300",
				@"PowerMac 7500",@"AAPL,7500",
				@"Apple Network Server",@"AAPL,ShinerESB",
				@"Alchemy(Performa 6400 logic-board design)",@"AAPL,e407",
				@"Gazelle(5500)",@"AAPL,e411",
				@"PowerBook 3400",@"AAPL,3400/2400",
				@"PowerBook 3500",@"AAPL,3500",
				@"PowerMac G3 (Gossamer)",@"AAPL,Gossamer",
				@"PowerMac G3 (Silk)",@"AAPL,PowerMac G3",
				@"PowerBook G3 (Wallstreet)",@"AAPL,PowerBook1998",
				@"Yikes! Old machine",@"AAPL",		// generic.
				
				@"iMac (first generation)",@"iMac,1",
				@"iMac",@"iMac",					// generic.
				
				@"PowerBook G3 (Lombard)",@"PowerBook1,1",
				@"iBook (clamshell)",@"PowerBook2,1",
				@"iBook FireWire (clamshell)",@"PowerBook2,2",
				@"PowerBook G3 (Pismo)",@"PowerBook3,1",
				@"PowerBook G4 (Titanium)",@"PowerBook3,2",
				@"PowerBook G4 (Titanium w/ Gigabit Ethernet)",@"PowerBook3,3",
				@"PowerBook G4 (Titanium w/ DVI)",@"PowerBook3,4",
				@"PowerBook G4 (Titanium 1GHZ)",@"PowerBook3,5",
				@"iBook (12in May 2001)",@"PowerBook4,1",
				@"iBook (May 2002)",@"PowerBook4,2",
				@"iBook 2 rev. 2 (w/ or w/o 14in LCD) (Nov 2002)",@"PowerBook4,3",
				@"iBook 2 (w/ or w/o 14in LDC)",@"PowerBook4,4",
				@"PowerBook G4 (Aluminum 17in)",@"PowerBook5,1",
				@"PowerBook G4 (Aluminum 15in)",@"PowerBook5,2",
				@"PowerBook G4 (Aluminum 17in rev. 2)",@"PowerBook5,3",
				@"PowerBook G4 (Aluminum 12in)",@"PowerBook6,1",
				@"PowerBook G4 (Aluminum 12in)",@"PowerBook6,2",
				@"iBook G4",@"PowerBook6,3",
				@"PowerBook or iBook",@"PowerBook",	// generic.
				
				@"Blue & White G3",@"PowerMac1,1",
				@"PowerMac G4 PCI Graphics",@"PowerMac1,2",
				@"iMac FireWire (CRT)",@"PowerMac2,1",
				@"iMac FireWire (CRT)",@"PowerMac2,2",
				@"PowerMac G4 AGP Graphics",@"PowerMac3,1",
				@"PowerMac G4 AGP Graphics",@"PowerMac3,2",
				@"PowerMac G4 AGP Graphics",@"PowerMac3,3",
				@"PowerMac G4 (QuickSilver)",@"PowerMac3,4",
				@"PowerMac G4 (QuickSilver)",@"PowerMac3,5",
				@"PowerMac G4 (MDD/Windtunnel)",@"PowerMac3,6",
				@"iMac (Flower Power)",@"PowerMac4,1",
				@"iMac (Flat Panel 15in)",@"PowerMac4,2",
				@"eMac",@"PowerMac4,4",
				@"iMac (Flat Panel 17in)",@"PowerMac4,5",
				@"PowerMac G4 Cube",@"PowerMac5,1",
				@"PowerMac G4 Cube",@"PowerMac5,2",
				@"iMac (Flat Panel 17in)",@"PowerMac6,1",
				@"PowerMac G5",@"PowerMac7,2",
				@"PowerMac G5",@"PowerMac7,3",
				@"PowerMac",@"PowerMac",	// generic.
				
				@"XServe",@"RackMac1,1",
				@"XServe rev. 2",@"RackMac1,2",
				@"XServe G5",@"RackMac3,1",
				@"XServe",@"RackMac",
				
				@"Mac Mini Core",@"Macmini1,1",	// Core Duo?
				@"Mac Mini",@"Macmini",				// generic

				@"Mac Pro",@"MacPro",				// generic

				@"MacBook Pro Core 2",@"MacBookPro4,1",
				@"MacBook Pro",@"MacBookPro",		// generic
				
				@"MacBook Air (Late 2010)",@"MacBookAir3,1",
				@"MacBook Air",@"MacBookAir",				// generic
				nil];
	
	NSRange			r;
	NSString*		aKey;
	NSString*		foundKey = nil;
	NSString*		humanReadableName = nil;
	
	// Find the corresponding entry in the NSDictionary
	//	Keys should be sorted to distinguish 'generic' from 'specific' names.
	//	So we can overwrite generic names with the more specific ones as we
	//	progress through the list.
	NSEnumerator	*e=[[[translationDictionary allKeys]
								sortedArrayUsingSelector:@selector(compare:)]
								objectEnumerator];
	while( aKey = [e nextObject] )
	{
		r = [internalName rangeOfString: aKey];
		if( r.location != NSNotFound )
		{
			if( humanReadableName == nil || [foundKey length] != [internalName length] )	// We didn't have an exact match yet?
			{
				humanReadableName = [translationDictionary objectForKey:aKey];
				foundKey = aKey;
			}
		}
	}
	
	// If it was a generic name, include the ugly name so we can add it to the list:
	if( [foundKey rangeOfString: @","].location == NSNotFound )
		humanReadableName = [[NSString stringWithFormat: @"%@ (%@)", humanReadableName, foundKey] retain];
	// If nothing was found, at least show the ugly name so we have some hint:
	if( humanReadableName == nil )
		cpuName = [[NSString stringWithFormat: @"Unknown (%@)", internalName] retain];
	else
		cpuName = humanReadableName;
	
	return cpuName;
}


NSString*	UKCPUName(void)
{
	return UKAutoreleasedCPUName( NO );
}


NSString*	UKAutoreleasedCPUName( BOOL dontCache )
{
	static NSString	*	sCPUName = nil;
	
	if( dontCache || !sCPUName )
	{
		char		cpuName[256] = {};
		size_t		size = sizeof(cpuName) -1;

		if( sysctlbyname( "machdep.cpu.brand_string", cpuName, &size, NULL, 0 ) != 0 )
			return nil;

		[sCPUName release];
		sCPUName = [[NSString alloc] initWithUTF8String: cpuName];
	}
	
	return sCPUName;
}


/*NSString*	UKSystemSerialNumber()
{
	mach_port_t				masterPort;
	kern_return_t			kr = noErr;
	io_registry_entry_t		entry;
	CFTypeRef				prop;
	CFTypeID				propID;
	NSString*				str = nil;

	kr = IOMasterPort(MACH_PORT_NULL, &masterPort);
	if( kr != noErr )
		goto cleanup;
	entry = IORegistryGetRootEntry( masterPort );
	if( entry == MACH_PORT_NULL )
		goto cleanup;
	prop = IORegistryEntrySearchCFProperty(entry, kIODeviceTreePlane, CFSTR("serial-number"), nil, kIORegistryIterateRecursively);
	if( prop == nil )
		goto cleanup;
	propID = CFGetTypeID( prop );
	if( propID != CFDataGetTypeID() )
		goto cleanup;
	
	const char*	buf = [(NSData*)prop bytes];
	int			len = [(NSData*)prop length],
				 x;
	
	char	secondPart[256];
	char	firstPart[256];
	char*	currStr = secondPart;
	int		y = 0;
	
	for( x = 0; x < len; x++ )
	{
		if( buf[x] > 0 && (y < 255) )
			currStr[y++] = buf[x];
		else if( currStr == secondPart )
		{
			currStr[y] = 0;		// Terminate string.
			currStr = firstPart;
			y = 0;
		}
	}
	currStr[y] = 0;	// Terminate string.
	
	str = [NSString stringWithFormat: @"%s%s", firstPart, secondPart];
	
cleanup:
	mach_port_deallocate( mach_task_self(), masterPort );
	
	return str;
}*/

