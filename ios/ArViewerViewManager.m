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

@end

