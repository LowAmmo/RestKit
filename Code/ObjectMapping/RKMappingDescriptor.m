//
//  RKMappingDescriptor.m
//  RestKit
//
//  Created by Blake Watters on 8/16/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <RestKit/RKPathMatcher.h>
#import "RKMappingDescriptor.h"

NSUInteger RKStatusCodeRangeLength = 100;

NSRange RKStatusCodeRangeForClass(RKStatusCodeClass statusCodeClass)
{
    return NSMakeRange(statusCodeClass, RKStatusCodeRangeLength);
}

NSIndexSet * RKStatusCodeIndexSetForClass(RKStatusCodeClass statusCodeClass)
{
    return [NSIndexSet indexSetWithIndexesInRange:RKStatusCodeRangeForClass(statusCodeClass)];
}

// Cloned from AFStringFromIndexSet -- method should be non-static for reuse
static NSString * RKStringFromIndexSet(NSIndexSet *indexSet) {
    NSMutableString *string = [NSMutableString string];
    
    NSRange range = NSMakeRange([indexSet firstIndex], 1);
    while (range.location != NSNotFound) {
        NSUInteger nextIndex = [indexSet indexGreaterThanIndex:range.location];
        while (nextIndex == range.location + range.length) {
            range.length++;
            nextIndex = [indexSet indexGreaterThanIndex:nextIndex];
        }
        
        if (string.length) {
            [string appendString:@","];
        }
        
        if (range.length == 1) {
            [string appendFormat:@"%u", range.location];
        } else {
            NSUInteger firstIndex = range.location;
            NSUInteger lastIndex = firstIndex + range.length - 1;
            [string appendFormat:@"%u-%u", firstIndex, lastIndex];
        }
        
        range.location = nextIndex;
        range.length = 1;
    }
    
    return string;
}

@interface RKMappingDescriptor ()
@property (nonatomic, strong, readwrite) RKMapping *mapping;
@property (nonatomic, strong, readwrite) NSString *pathPattern;
@property (nonatomic, strong, readwrite) NSString *keyPath;
@property (nonatomic, strong, readwrite) NSIndexSet *statusCodes;
@end

@implementation RKMappingDescriptor

+ (RKMappingDescriptor *)mappingDescriptorWithMapping:(RKMapping *)mapping
                                          pathPattern:(NSString *)pathPattern
                                              keyPath:(NSString *)keyPath
                                          statusCodes:(NSIndexSet *)statusCodes
{
    RKMappingDescriptor *mappingDescriptor = [self new];
    mappingDescriptor.mapping = mapping;
    mappingDescriptor.pathPattern = pathPattern;
    mappingDescriptor.keyPath = keyPath;
    mappingDescriptor.statusCodes = statusCodes;
    
    return mappingDescriptor;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p pathPattern=%@ keyPath=%@ statusCodes=%@ : %@>",
            NSStringFromClass([self class]), self, self.pathPattern, self.keyPath, RKStringFromIndexSet(self.statusCodes), self.mapping];
}

@end
