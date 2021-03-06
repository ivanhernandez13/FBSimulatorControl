/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBArchiveOperations.h"

#import "FBControlCoreError.h"
#import "FBControlCoreLogger.h"
#import "FBTask.h"
#import "FBTaskBuilder.h"

@implementation FBArchiveOperations

+ (FBFuture<NSString *> *)extractZipArchiveAtPath:(NSString *)path toPath:(NSString *)extractPath queue:(dispatch_queue_t)queue logger:(id<FBControlCoreLogger>)logger
{
  return [[[[[[[FBTaskBuilder
    withLaunchPath:@"/usr/bin/unzip"]
    withArguments:@[@"-o", @"-d", extractPath, path]]
    withAcceptableTerminationStatusCodes:[NSSet setWithObject:@0]]
    withStdErrToLogger:logger.debug]
    withStdOutToLogger:logger.debug]
    runUntilCompletion]
    mapReplace:extractPath];
}

+ (FBFuture<NSString *> *)extractTarArchiveAtPath:(NSString *)path toPath:(NSString *)extractPath queue:(dispatch_queue_t)queue logger:(id<FBControlCoreLogger>)logger
{
  return [[[[[[[FBTaskBuilder
    withLaunchPath:@"/usr/bin/tar"]
    withArguments:@[@"-C", extractPath, @"-vzxpf", path]]
    withStdErrToLogger:logger.debug]
    withStdOutToLogger:logger.debug]
    withAcceptableTerminationStatusCodes:[NSSet setWithObject:@0]]
    runUntilCompletion]
    mapReplace:extractPath];
}

+ (FBFuture<NSString *> *)extractTarArchiveFromStream:(FBProcessInput *)stream toPath:(NSString *)extractPath queue:(dispatch_queue_t)queue logger:(id<FBControlCoreLogger>)logger
{
  return [[[[[[[[FBTaskBuilder
    withLaunchPath:@"/usr/bin/tar"]
    withArguments:@[@"-C", extractPath, @"-vzxpf", @"-"]]
    withStdIn:stream]
    withStdErrToLogger:logger.debug]
    withStdOutToLogger:logger.debug]
    withAcceptableTerminationStatusCodes:[NSSet setWithObject:@0]]
    runUntilCompletion]
    mapReplace:extractPath];
}

+ (FBFuture<NSString *> *)extractArchiveAtPath:(NSString *)path toPath:(NSString *)extractPath queue:(dispatch_queue_t)queue logger:(id<FBControlCoreLogger>)logger
{
  FBFileHeaderMagic magic = [self headerMagicForFile:path];
  switch (magic) {
    case FBFileHeaderMagicIPA:
      return [self extractZipArchiveAtPath:path toPath:extractPath queue:queue logger:logger];
    case FBFileHeaderMagicTAR:
      return [self extractTarArchiveAtPath:path toPath:extractPath queue:queue logger:logger];
    default:
      return [[FBControlCoreError
        describeFormat:@"File at path %@ is not determined to be an archive", path]
        failFuture];
  }
}

// The Magic Header for Zip Files is two chars 'PK'. As a short this is as below.
static unsigned short const ZipFileMagicHeader = 0x4b50;
// The Magic Header for Tar Files
static unsigned short const TarFileMagicHeader = 0x8b1f;

+ (FBFileHeaderMagic)headerMagicForData:(NSData *)data
{
  unsigned short magic = 0;
  [data getBytes:&magic length:sizeof(short)];
  return [self magicForShort:magic];
}

+ (FBFileHeaderMagic)headerMagicForFile:(NSString *)path
{
  // IPAs are Zip files. Zip Files always have a magic header in their first 4 bytes.
  FILE *file = fopen(path.UTF8String, "r");
  if (!file) {
    return FBFileHeaderMagicUnknown;
  }
  unsigned short magic = 0;
  if (!fread(&magic, sizeof(short), 1, file)) {
    fclose(file);
    return FBFileHeaderMagicUnknown;
  }
  fclose(file);
  return [self magicForShort:magic];
}

#pragma mark Private

+ (FBFileHeaderMagic)magicForShort:(unsigned short)magic
{
  if (magic == ZipFileMagicHeader) {
    return FBFileHeaderMagicIPA;
  } else if (magic == TarFileMagicHeader) {
    return FBFileHeaderMagicTAR;
  }
  return FBFileHeaderMagicUnknown;
}

@end
