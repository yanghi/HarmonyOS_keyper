import picker from '@ohos.file.picker';
import Logger from './Logger';
import fs from '@ohos.file.fs';
import { stringifyError } from './common';

const LABEL = 'fsUtils'
const TAG = `[${LABEL}]`

export namespace fsUtils {
  export async function writeDoc(filename: string, data: string | ArrayBuffer) {
    const documentSaveOptions = new picker.DocumentSaveOptions();
    documentSaveOptions.newFileNames = [filename];

    let sub = `[${LABEL}.writeDoc(filename=${filename})] `
    const documentViewPicker = new picker.DocumentViewPicker();
    try {
      Logger.info(sub, 'documentViewPicker.save')
      let documentSaveResult = await  documentViewPicker.save(documentSaveOptions)
      Logger.debug(sub, 'uri' + documentSaveResult[0])
      let uri = documentSaveResult[0];

      Logger.info(sub, 'documentViewPicker.save to file succeed and URI is:' + uri);
      let file = fs.openSync(uri, fs.OpenMode.READ_WRITE);
      Logger.info(sub, 'file fd: ' + file.fd);

      let writeLen = fs.writeSync(file.fd, data);
      Logger.info(sub, 'write data to file succeed and size is:' + writeLen);
      fs.closeSync(file);
    } catch (e) {
      Logger.error(sub, 'write failed, err:' + stringifyError(e) + ' msg ' + e?.message)
      throw e
    }

  }

  export async function readDoc() {

    const documentSelectOptions = new picker.DocumentSelectOptions();

    const documentViewPicker = new picker.DocumentViewPicker();

    let sub = `[${LABEL}.readDoc()]`
    try {
      let result = await documentViewPicker.select(documentSelectOptions)
      let uri = result[0];
      Logger.debug(sub, 'uri ' + uri)
      let file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      let buffer = new ArrayBuffer(4096);
      let len = fs.readSync(file.fd, buffer)
      Logger.info(sub, 'read data to file succeed and size is:' + len);
      return buffer
    } catch (e) {
      Logger.error(sub, 'read failed, err:' + stringifyError(e) + ' msg ' + e?.message)
    }
  }
}