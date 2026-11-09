#import "RNArViewerComponentView.h"

#import <react/renderer/components/RNArViewerSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNArViewerSpec/EventEmitters.h>
#import <react/renderer/components/RNArViewerSpec/Props.h>
#import <react/renderer/components/RNArViewerSpec/RCTComponentViewHelpers.h>

#if __has_include(<react_native_ar_viewer/react_native_ar_viewer-Swift.h>)
#import <react_native_ar_viewer/react_native_ar_viewer-Swift.h>
#else
#import "react_native_ar_viewer-Swift.h"
#endif

using namespace facebook::react;

@interface RNArViewerComponentView () <RCTArViewerViewViewProtocol>
@end

@implementation RNArViewerComponentView {
  ArViewerView *_view;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<ArViewerViewComponentDescriptor>();
}

// Each instance owns an ARKit session and a child view controller, so it cannot be reused
+ (BOOL)shouldBeRecycled
{
  return NO;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const ArViewerViewProps>();
    _props = defaultProps;
    _view = [[ArViewerView alloc] initWithFrame:frame];
    [self setupEvents];
    self.contentView = _view;
  }
  return self;
}

- (const ArViewerViewEventEmitter *)eventEmitter
{
  return static_cast<const ArViewerViewEventEmitter *>(_eventEmitter.get());
}

- (void)setupEvents
{
  __weak RNArViewerComponentView *weakSelf = self;
  _view.onStarted = ^(NSDictionary *payload) {
    if (auto emitter = [weakSelf eventEmitter]) {
      emitter->onStarted({});
    }
  };
  _view.onEnded = ^(NSDictionary *payload) {
    if (auto emitter = [weakSelf eventEmitter]) {
      emitter->onEnded({});
    }
  };
  _view.onModelPlaced = ^(NSDictionary *payload) {
    if (auto emitter = [weakSelf eventEmitter]) {
      emitter->onModelPlaced({});
    }
  };
  _view.onModelRemoved = ^(NSDictionary *payload) {
    if (auto emitter = [weakSelf eventEmitter]) {
      emitter->onModelRemoved({});
    }
  };
  _view.onError = ^(NSDictionary *payload) {
    if (auto emitter = [weakSelf eventEmitter]) {
      NSString *message = payload[@"message"] ?: @"";
      emitter->onError({.message = message.UTF8String});
    }
  };
  _view.onDataReturned = ^(NSDictionary *payload) {
    if (auto emitter = [weakSelf eventEmitter]) {
      NSString *result = payload[@"result"] ?: @"";
      NSString *error = payload[@"error"] ?: @"";
      emitter->onDataReturned({
          .requestId = [payload[@"requestId"] intValue],
          .result = result.UTF8String,
          .error = error.UTF8String,
      });
    }
  };
}

- (void)updateProps:(const Props::Shared &)props oldProps:(const Props::Shared &)oldProps
{
  const auto &oldViewProps = *std::static_pointer_cast<const ArViewerViewProps>(_props);
  const auto &newViewProps = *std::static_pointer_cast<const ArViewerViewProps>(props);

  if (oldViewProps.model != newViewProps.model) {
    _view.model = [NSString stringWithUTF8String:newViewProps.model.c_str()];
  }
  if (oldViewProps.planeOrientation != newViewProps.planeOrientation) {
    _view.planeOrientation = [NSString stringWithUTF8String:toString(newViewProps.planeOrientation).c_str()];
  }
  if (oldViewProps.allowScale != newViewProps.allowScale) {
    _view.allowScale = newViewProps.allowScale;
  }
  if (oldViewProps.allowRotate != newViewProps.allowRotate) {
    _view.allowRotate = newViewProps.allowRotate;
  }
  if (oldViewProps.allowTranslate != newViewProps.allowTranslate) {
    _view.allowTranslate = newViewProps.allowTranslate;
  }
  if (oldViewProps.lightEstimation != newViewProps.lightEstimation) {
    _view.lightEstimation = newViewProps.lightEstimation;
  }
  if (oldViewProps.manageDepth != newViewProps.manageDepth) {
    _view.manageDepth = newViewProps.manageDepth;
  }
  if (oldViewProps.disableInstructions != newViewProps.disableInstructions) {
    _view.disableInstructions = newViewProps.disableInstructions;
  }
  if (oldViewProps.disableInstantPlacement != newViewProps.disableInstantPlacement) {
    _view.disableInstantPlacement = newViewProps.disableInstantPlacement;
  }

  [super updateProps:props oldProps:oldProps];
}

- (void)handleCommand:(const NSString *)commandName args:(const NSArray *)args
{
  RCTArViewerViewHandleCommand(self, commandName, args);
}

- (void)takeScreenshot:(NSInteger)requestId
{
  [_view takeScreenshotWithRequestId:requestId];
}

- (void)reset
{
  [_view reset];
}

- (void)rotateModel:(double)pitch yaw:(double)yaw roll:(double)roll
{
  [_view rotateModelWithPitch:pitch yaw:yaw roll:roll];
}

- (void)prepareForRecycle
{
  [super prepareForRecycle];
  [_view tearDown];
}

@end
