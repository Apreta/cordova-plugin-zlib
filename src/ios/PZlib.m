#import "PZlib.h"

#include "zlib.h"

/*
   Might be more efficient to use Base64 for exchanging with JS
*/

@implementation PZlib {
  z_stream deflaters[4];
  bool deflaterActive[4];
  
  z_stream inflaters[4];
  bool inflaterActive[4];

  unsigned char * inBuff;
  size_t inBuffSize;
  unsigned char * outBuff;
  size_t outBuffSize;
}

- (id)init
{
  self = [super init];
  if (self)
  {
    inBuff = NULL;
    inBuffSize = 0;
    outBuff = NULL;
    outBuffSize = 0;
    for (int i = 0; i < 4; i++)
    {
      deflaterActive[i] = false;
      inflaterActive[i] = false;
    }
  }
  return self;
}

-(void)dealloc
{
  free(inBuff);
  free(outBuff);
  for (int i = 0; i < 4; i++)
  {
    if (inflaterActive[i])
    {
      inflateEnd(&inflaters[i]);
      inflaterActive[i] = false;
    }
    if (deflaterActive[i])
    {
      deflateEnd(&deflaters[i]);
      deflaterActive[i] = false;
    }
  }
}

- (void)deflate:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* result;
    NSNumber* stream = [[command arguments] objectAtIndex:0];
    NSArray* data = [[command arguments] objectAtIndex:1];
    NSMutableArray* out = [NSMutableArray array];

    z_streamp pz;
    int err;
    int streamId = [stream intValue];
    int inSize = [data count];
    int outSize = inSize + (inSize + 99) / 100 + 12;

    if (inSize > inBuffSize)
    {
      if (inBuff)
        inBuff = realloc(inBuff, inSize);
      else
        inBuff = malloc(inSize);
      inBuffSize = inSize;
    }

    for (int i=0; i<inSize; i++)
    {
      inBuff[i] = [[data objectAtIndex:i] unsignedCharValue];
    }
  
    if (outSize > outBuffSize)
    {
      if (outBuff)
        outBuff = realloc(outBuff, outSize);
      else
        outBuff = malloc(outSize);
      outBuffSize = outSize;
    }
  
    pz = &deflaters[streamId];
  
    /* Initialize compression stream if needed. */
    if (!deflaterActive[streamId])
    {
      pz->zalloc = Z_NULL;
      pz->zfree = Z_NULL;
      pz->opaque = Z_NULL;
    
      err = deflateInit2 (pz, Z_DEFAULT_COMPRESSION, Z_DEFLATED, MAX_WBITS,
                        MAX_MEM_LEVEL, Z_DEFAULT_STRATEGY);
      if (err != Z_OK)
      {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Zlib error"];
        goto done;
      }
      
      deflaterActive[streamId] = true;
    }
  
    /* Prepare buffer pointers. */
    pz->next_in = (Bytef *)inBuff;
    pz->avail_in = inSize;
    pz->next_out = (Bytef *)outBuff;
    pz->avail_out = outBuffSize;
  
    /* Actual compression. */
    if (deflate (pz, Z_SYNC_FLUSH) != Z_OK || pz->avail_in != 0 || pz->avail_out == 0)
    {
      result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Zlib error"];
      goto done;
    }
  
    for (int i=0; i < outBuffSize - pz->avail_out; i++)
    {
      [out addObject:[NSNumber numberWithUnsignedChar:outBuff[i] ]];
    }
  
    result = [CDVPluginResult
              resultWithStatus:CDVCommandStatus_OK
              messageAsArray:out];
done:
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)inflate:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* result;
    NSNumber* stream = [[command arguments] objectAtIndex:0];
    NSArray* data = [[command arguments] objectAtIndex:1];
    NSMutableArray* out = [NSMutableArray array];
  
    z_streamp pz;
    int err;
    int streamId = [stream intValue];
    int inSize = [data count];
    int outSize = inSize * 10;

    if (inSize > inBuffSize)
    {
      if (inBuff)
        inBuff = realloc(inBuff, inSize);
      else
        inBuff = malloc(inSize);
      inBuffSize = inSize;
    }

    for (int i=0; i<inSize; i++)
    {
      inBuff[i] = [[data objectAtIndex:i] unsignedCharValue];
    }
  
    if (outSize > outBuffSize)
    {
      if (outBuff)
        outBuff = realloc(outBuff, outSize);
      else
        outBuff = malloc(outSize);
      outBuffSize = outSize;
    }

    pz = &inflaters[streamId];
    if (!inflaterActive[streamId])
    {
      pz->zalloc = Z_NULL;
      pz->zfree = Z_NULL;
      pz->opaque = Z_NULL;
      err = inflateInit(pz);
      if (err != Z_OK)
      {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Zlib error"];
        goto done;
      }
      inflaterActive[streamId] = TRUE;
    }
  
  
    pz->next_in = (Bytef *)inBuff;
    pz->avail_in = inSize;;
  
    do
    {
      pz->next_out = (Bytef *)outBuff;
      pz->avail_out = outBuffSize;
      
      err = inflate(pz, Z_SYNC_FLUSH);
      if (err == Z_BUF_ERROR)   /* Input exhausted -- no problem. */
        break;
      if (err != Z_OK && err != Z_STREAM_END)
      {
        if (pz->msg != NULL)
        {
          result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                     messageAsString:[NSString stringWithUTF8String:pz->msg]];
        } else {
          result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Zlib error"];
        }
        goto done;
      }
      
      for (int i=0; i < outBuffSize - pz->avail_out; i++)
      {
        [out addObject:[NSNumber numberWithUnsignedChar:outBuff[i] ]];
      }
    }
    while (pz->avail_out == 0);
  
    result = [CDVPluginResult
              resultWithStatus:CDVCommandStatus_OK
              messageAsArray:out];

done:
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)reset:(CDVInvokedUrlCommand*)command
{

    NSNumber* stream = [[command arguments] objectAtIndex:0];
    int streamId = [stream intValue];

    if (inflaterActive[streamId])
    {
      inflateEnd(&inflaters[streamId]);
      inflaterActive[streamId] = false;
    }
    if (deflaterActive[streamId])
    {
      deflateEnd(&deflaters[streamId]);
      deflaterActive[streamId] = false;
    }
  
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               ];

    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

@end
