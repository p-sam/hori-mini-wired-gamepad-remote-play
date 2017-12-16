#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOTypes.h>
#include <IOKit/IOReturn.h>
#include <IOKit/hid/IOHIDLib.h>
#import <objc/runtime.h>

#include <stdio.h>
#include <unistd.h>
#include <dlfcn.h>

#define CFENCODING kCFStringEncodingUTF8
#define CFSTRTOC(str) CFStringGetCStringPtr(str, CFENCODING)
#define CFINTFORMAT kCFNumberSInt32Type

#define COMMON_DEVICE_USAGE 5
#define COMMON_DEVICE_USAGE_PAGE 1
#define COMMON_DEVICE_TRANSPORT "USB"
#define DS4_VENDOR_ID 0x54c
#define DS4_PRODUCT_ID 0x5c4
#define SPOOF_VENDOR_ID 0x0f0d
#define SPOOF_PRODUCT_ID 0x00ee

void IOHIDWrapDumpCFPropertyList(CFPropertyListRef propertyList) {
    CFDataRef xmlPropertyListData = CFPropertyListCreateData(NULL, propertyList, kCFPropertyListXMLFormat_v1_0, 0, NULL);
    CFStringRef xmlAsString = CFStringCreateFromExternalRepresentation(NULL, xmlPropertyListData, CFENCODING);
    printf("%s\n", CFSTRTOC(xmlAsString));
    CFRelease(xmlAsString);
    CFRelease(xmlPropertyListData);
} 


CFNumberRef IOHIDWrapMakeInt(unsigned short value) {
	return CFNumberCreate(NULL, kCFNumberShortType, &value);
}

bool IOHIDWrapOpaqueIntEquals(CFTypeRef originalRef, unsigned short test) {
    CFNumberRef testNumber = IOHIDWrapMakeInt(test);
    bool equals = CFEqual(originalRef, testNumber);
    CFRelease(testNumber);
    CFRelease(originalRef);
    return equals;
}

CFTypeRef (*original_IOHIDDeviceGetProperty) (IOHIDDeviceRef, CFStringRef) = NULL;
bool IOHIDWrapShouldSpoof(IOHIDDeviceRef device) {
    assert(original_IOHIDDeviceGetProperty != NULL);

    bool result = true;
    CFTypeRef originalRef;

    originalRef = original_IOHIDDeviceGetProperty(device, CFSTR("VendorID"));
    if(!IOHIDWrapOpaqueIntEquals(originalRef, SPOOF_VENDOR_ID)) {
        result = false;
    } else {
        CFRelease(originalRef);
        originalRef = original_IOHIDDeviceGetProperty(device, CFSTR("ProductID"));
        if(!IOHIDWrapOpaqueIntEquals(originalRef, SPOOF_PRODUCT_ID)) {
            result = false;
        }
    }
    CFRelease(originalRef);

    return result;
}

CFTypeRef IOHIDDeviceGetProperty(IOHIDDeviceRef device, CFStringRef key) {
    if (!original_IOHIDDeviceGetProperty) {
        original_IOHIDDeviceGetProperty = dlsym(RTLD_NEXT, "IOHIDDeviceGetProperty");
    }

    printf("== IOHIDDeviceGetProperty: {%s} ==\n", CFSTRTOC(key));
    
    CFTypeRef ref = original_IOHIDDeviceGetProperty(device, key);
    CFShow(ref);

    if(IOHIDWrapShouldSpoof(device)) {
        if(CFStringCompare(key, CFSTR("VendorID"), 0) == 0) {
            printf("spoofing to %x\n",  DS4_VENDOR_ID);
            CFRelease(ref);
            return IOHIDWrapMakeInt(DS4_VENDOR_ID);
        } else if(CFStringCompare(key, CFSTR("ProductID"), 0) == 0) {
            printf("spoofing to %x\n",  DS4_PRODUCT_ID);
            CFRelease(ref);
            return IOHIDWrapMakeInt(DS4_PRODUCT_ID);
        }
    }

    return ref;
}

void (*original_IOHIDManagerSetDeviceMatchingMultiple) (IOHIDManagerRef, CFArrayRef) = NULL;

void IOHIDManagerSetDeviceMatchingMultiple(IOHIDManagerRef manager, CFArrayRef multiple) {
    if (!original_IOHIDManagerSetDeviceMatchingMultiple) {
        original_IOHIDManagerSetDeviceMatchingMultiple = dlsym(RTLD_NEXT, "IOHIDManagerSetDeviceMatchingMultiple");
    }

    CFIndex c = CFArrayGetCount(multiple);
    printf("== IOHIDManagerSetDeviceMatchingMultiple (%ld) ==\n", c);

    CFMutableArrayRef multiple_c = CFArrayCreateMutableCopy(NULL, c + 1, multiple);

    CFMutableDictionaryRef spoofDevicedict = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    
    int deviceUsageValue = COMMON_DEVICE_USAGE;
    CFNumberRef deviceUsageNumber = CFNumberCreate(NULL, kCFNumberIntType, &deviceUsageValue);
    CFDictionarySetValue(spoofDevicedict, CFSTR("DeviceUsage"), deviceUsageNumber);
    CFRelease(deviceUsageNumber);

    int deviceUsagePageValue = COMMON_DEVICE_USAGE_PAGE;
    CFNumberRef deviceUsagePageNumber = CFNumberCreate(NULL, kCFNumberIntType, &deviceUsagePageValue);
    CFDictionarySetValue(spoofDevicedict, CFSTR("DeviceUsagePage"), deviceUsagePageNumber);
    CFRelease(deviceUsagePageNumber);

    int productIdValue = SPOOF_PRODUCT_ID;
    CFNumberRef productIdNumber = CFNumberCreate(NULL, kCFNumberIntType, &productIdValue);
    CFDictionarySetValue(spoofDevicedict, CFSTR("ProductID"), productIdNumber);
    CFRelease(productIdNumber);

    int vendorIdValue = SPOOF_VENDOR_ID;
    CFNumberRef vendorIdNumber = CFNumberCreate(NULL, kCFNumberIntType, &vendorIdValue);
    CFDictionarySetValue(spoofDevicedict, CFSTR("VendorID"), vendorIdNumber);
    CFRelease(vendorIdNumber);

    CFDictionarySetValue(spoofDevicedict, CFSTR("Transport"), CFSTR(COMMON_DEVICE_TRANSPORT));

    CFArrayAppendValue(multiple_c, spoofDevicedict);

    IOHIDWrapDumpCFPropertyList(multiple_c);

    original_IOHIDManagerSetDeviceMatchingMultiple(manager, (CFArrayRef)multiple_c);
}

// copypasta from ShockEmu
IOReturn IOHIDWrapDeviceGetReport(IOHIDDeviceRef device, IOHIDReportType reportType, CFIndex reportID, uint8_t *report, CFIndex *pReportLength) {
	if(reportID == 0x12) {
		uint8_t report12[] = {0x12, 0x8B, 0x09, 0x07, 0x6D, 0x66, 0x1C, 0x08, 0x25, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
		assert(pReportLength != NULL && *pReportLength >= sizeof(report12));
		memcpy(report, report12, sizeof(report12));
	} else if(reportID == 0xa3) {
		uint8_t reporta3[] = {0xA3, 0x41, 0x75, 0x67, 0x20, 0x20, 0x33, 0x20, 0x32, 0x30, 0x31, 0x33, 0x00, 0x00, 0x00, 0x00, 0x00, 0x30, 0x37, 0x3A, 0x30, 0x31, 0x3A, 0x31, 0x32, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x31, 0x03, 0x00, 0x00, 0x00, 0x49, 0x00, 0x05, 0x00, 0x00, 0x80, 0x03, 0x00};
		assert(pReportLength != NULL && *pReportLength >= sizeof(reporta3));
		memcpy(report, reporta3, sizeof(reporta3));
	} else if(reportID == 0x02) {
		uint8_t report02[] = {0x02, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x87, 0x22, 0x7B, 0xDD, 0xB2, 0x22, 0x47, 0xDD, 0xBD, 0x22, 0x43, 0xDD, 0x1C, 0x02, 0x1C, 0x02, 0x7F, 0x1E, 0x2E, 0xDF, 0x60, 0x1F, 0x4C, 0xE0, 0x3A, 0x1D, 0xC6, 0xDE, 0x08, 0x00};
		assert(pReportLength != NULL && *pReportLength >= sizeof(report02));
		memcpy(report, report02, sizeof(report02));
	}
	return kIOReturnSuccess;
}


IOReturn (*original_IOHIDDeviceGetReport) (IOHIDDeviceRef, IOHIDReportType, CFIndex, uint8_t*, CFIndex*) = NULL;
IOReturn IOHIDDeviceGetReport(IOHIDDeviceRef device, IOHIDReportType reportType, CFIndex reportID, uint8_t *report, CFIndex *pReportLength) {
    if (!original_IOHIDDeviceGetReport) {
        original_IOHIDDeviceGetReport = dlsym(RTLD_NEXT, "IOHIDDeviceGetReport");
    }

	printf("== IOHIDDeviceGetReport(0x%x, %i)\n", (int) reportID, pReportLength == NULL ? 0 : (int) *pReportLength);

    if(IOHIDWrapShouldSpoof(device)) {
        printf("spoofing report\n");
        return IOHIDWrapDeviceGetReport(device, reportType, reportID, report, pReportLength);
    }
    return original_IOHIDDeviceGetReport(device, reportType, reportID, report, pReportLength);
}

/*
IOReturn IOHIDDeviceSetReport( IOHIDDeviceRef device, IOHIDReportType reportType, CFIndex reportID, const uint8_t *report, CFIndex reportLength) {
	printf("IOHIDDeviceSetReport\n");
	return kIOReturnSuccess;
}*/