import { describe, expect, it, jest } from '@jest/globals';
import { createRef } from 'react';
import { render, screen } from '@testing-library/react-native';
import { Commands } from '../ArViewerViewNativeComponent';
import { ArViewerView } from '../index';

jest.mock('../ArViewerViewNativeComponent', () => ({
  __esModule: true,
  default: 'ArViewerView',
  Commands: {
    takeScreenshot: jest.fn(),
    reset: jest.fn(),
    rotateModel: jest.fn(),
  },
}));

async function renderArView() {
  const ref = createRef<ArViewerView>();
  await render(<ArViewerView ref={ref} model="model.usdz" testID="ar-view" />);
  return { view: ref.current!, native: screen.getByTestId('ar-view') };
}

function lastRequestId() {
  const calls = jest.mocked(Commands.takeScreenshot).mock.calls;
  return calls[calls.length - 1]![1];
}

describe('ArViewerView', () => {
  it('resolves takeScreenshot with the data returned by the native view', async () => {
    const { view, native } = await renderArView();
    const promise = view.takeScreenshot();

    native.props.onDataReturned({
      nativeEvent: { requestId: lastRequestId(), result: 'base64', error: '' },
    });

    await expect(promise).resolves.toBe('base64');
  });

  it('rejects takeScreenshot when the native view returns an error', async () => {
    const { view, native } = await renderArView();
    const promise = view.takeScreenshot();

    native.props.onDataReturned({
      nativeEvent: { requestId: lastRequestId(), result: '', error: 'failure' },
    });

    await expect(promise).rejects.toThrow('failure');
  });

  it('forwards rotate and reset to native commands', async () => {
    const { view } = await renderArView();
    view.rotate(1, 2, 3);
    view.reset();

    const [, ...angles] = jest.mocked(Commands.rotateModel).mock.calls[0]!;
    expect(angles).toEqual([1, 2, 3]);
    expect(Commands.reset).toHaveBeenCalled();
  });
});
