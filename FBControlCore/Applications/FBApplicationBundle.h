/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBControlCore/FBBundleDescriptor.h>

NS_ASSUME_NONNULL_BEGIN

@class FBBinaryDescriptor;

/**
 A Bundle Descriptor specialized to Applications
 */
@interface FBApplicationBundle : FBBundleDescriptor

#pragma mark Initializers

/**
 Constructs a FBApplicationBundle for the an Application.

 @param name the name of the application
 @param path the path of the application
 @param bundleID the bundle id of the application
 @return a FBApplicationBundle instance.
 */
+ (instancetype)applicationWithName:(NSString *)name path:(NSString *)path bundleID:(NSString *)bundleID;

/**
 Constructs a FBApplicationBundle for the Application at the given path.

 @param path the path of the applocation to construct.
 @param error an error out.
 @return a FBApplicationBundle instance if one could be constructed, nil otherwise.
 */
+ (nullable instancetype)applicationWithPath:(NSString *)path error:(NSError **)error;

+ (NSString *)infoPlistKey:(NSString *)key forAppAtPath:(NSString *)appPath error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
