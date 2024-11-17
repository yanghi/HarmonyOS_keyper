import { AccountListModel } from '../../model/Account'
import { AccountInterface } from '../interfaces/Account'
import Logger from './Logger'
import promptAction from '@ohos.promptAction'

export function requestDeleteAccount(item: AccountInterface) {
  const TAG = '[requestDeleteAccount]'

  return new Promise<void>((resolve, reject) => {
    AlertDialog.show({
      title: '删除该账号',
      message: '',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      gridCount: 4,
      offset: { dx: 0, dy: -20 },
      primaryButton: {
        value: '删除',
        fontColor: 'red',
        action: () => {
          Logger.info(TAG, 'user confirm to delete account id=' + item.id)
          AccountListModel.delete(item.id)
            .then(() => {
              Logger.info(TAG, 'account soft delete successful after user confirm, id=' + item.id)
              promptAction.showToast({
                message: '账号删除成功,你可以在回收站恢复'
              })
              resolve()
            })
            .catch((e) => {
              promptAction.showToast({
                message: '删除失败',
              })
              reject(e)
            })
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {
          Logger.info(TAG, 'user cancel delete account id=' + item.id)
          reject('cancel')
        }
      },
      cancel: () => {
        Logger.info(TAG, 'user cancel delete account id=' + item.id)
        reject('cancel')
      }
    })
  })

}