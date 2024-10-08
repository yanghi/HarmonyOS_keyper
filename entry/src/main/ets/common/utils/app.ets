import router from '@ohos.router'
import { AppLockType } from '../enums/app'
import emitter from '@ohos.events.emitter'
import { EventId } from '../enums/Event'
import logger from './Logger'

type VerifyCb<D> = (data: D) => void

export function requestPasswordVerify<D extends object>(options: {
  id: string,
  reasonTitle?: string
}, callbackPayload: D, callback: VerifyCb<D>) {
  const id = options.id

  router.pushUrl({
    url: 'pages/Lock',
    params: {
      type: AppLockType.Verify,
      ...options,
      callbackPayload: {
        ...callbackPayload,
        $id: options.id
      }
    }
  })
  emitter.once({ eventId: EventId.VerifySuccess }, (e) => {
    if (e.data?.$id !== id) return logger.warn('[requestPasswordVerify.callback]', 'not destination target, target id=' + id
    + 'origin callback data:' + JSON.stringify(e))
    logger.debug('[requestPasswordVerify.callback]', 'invoke callback, target id=' + id)
    callback(e.data as any)
  })
}