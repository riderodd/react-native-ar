#import "React/RCTViewManager.h"

@interface RCT_EXTERN_MODULE(ArViewerViewManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(model, NSString)
RCT_EXPORT_VIEW_PROPERTY(planeOrientation, NSString)
RCT_EXPORT_VIEW_PROPERTY(allowScale, BOOL)
RCT_EXPORT_VIEW_PROPERTY(allowRotate, BOOL)
RCT_EXPORT_VIEW_PROPERTY(allowTranslate, BOOL)
RCT_EXPORT_VIEW_PROPERTY(lightEstimation, BOOL)
RCT_EXPORT_VIEW_PROPERTY(manageDepth, BOOL)
RCT_EXPORT_VIEW_PROPERTY(disableInstructions, BOOL)
RCT_EXPORT_VIEW_PROPERTY(disableInstantPlacement, BOOL)

RCT_EXTERN_METHOD(reset:(nonnull NSNumber*) reactTag)
RCT_EXTERN_METHOD(takeScreenshot:(nonnull NSNumber*)reactTag withRequestId:(nonnull NSNumber*)requestId)
RCT_EXTERN_METHOD(rotateModel:(nonnull NSNumber*)reactTag withPitch:(nonnull NSNumber*)pitch withYaw:(nonnull NSNumber*)yaw withRoll:(nonnull NSNumber*)roll)

RCT_EXPORT_VIEW_PROPERTY(onStarted, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onError, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onDataReturned, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onEnded, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onModelPlaced, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onModelRemoved, RCTDirectEventBlock)

@end

