import util from '@ohos.util';

export function isValidateIntId(id: any) {
  return typeof id == 'number' && id > 0
}

export function dateTimeToDefaultString(time: number | string) {
  return new Date(time).toDateString()
}

export function stringToUint8Array(str) {
  let arr = [];
  for (let i = 0, j = str.length; i < j; ++i) {
    arr.push(str.charCodeAt(i));
  }
  return new Uint8Array(arr);
}

export function uint8ArrayToShowStr(uint8Array) {
  return Array.prototype.map
    .call(uint8Array, (x) => ('00' + x.toString(16)).slice(-2))
    .join('');
}

export function uint8ArrayToString(array) {
  let arrayString = '';
  for (let i = 0; i < array.length; i++) {
    arrayString += String.fromCharCode(array[i]);
  }
  return arrayString;
}

export function stringifyError(e: unknown) {
  if (e instanceof Error) {
    if ('code' in e) {
      return '' + e + ' code=' + (e as any).code
    }
    return '' + e
  }
  if (typeof e === 'string') return 'Err:' + e
  if ((e as any).code) {
    return 'Error<Obj>:' + JSON.stringify(e) + 'code=' + (e as any).code

  }
  return 'Error<Obj>:' + JSON.stringify(e)
}

export function ab2str(buf: ArrayBuffer): string {
  let buffer = new Uint8Array(buf)
  let readString = util.TextDecoder.create().decodeWithStream(buffer, { stream: false });

  return readString
}
