import router from '@ohos.router'
import { AppLockType } from '../enums/app'
import emitter from '@ohos.events.emitter'
import { EventId } from '../enums/Event'
import logger from './Logger'
import type { VerifyParams } from '../../pages/Lock'

type VerifyCb<D> = (data: D) => void

export function requestPasswordVerify<D extends object>(options: VerifyParams, callbackPayload: D, callback: VerifyCb<{
  payload: D,
  inputSecret: string
}>) {
  const id = options.id

  router.pushUrl({
    url: 'pages/Lock',
    params: {
      type: AppLockType.Verify,
      ...options,
      callbackPayload
    }
  })
  emitter.once({ eventId: EventId.VerifySuccess }, (e) => {
    if (e.data?.id !== id) return logger.error('[requestPasswordVerify.callback]',
      `not destination target, target id=${id} current id = ${e.data?.id} origin callback data: ${JSON.stringify(e)}`)

    logger.debug('[requestPasswordVerify.callback]', 'invoke callback, target id=' + id)
    callback(e.data as any)
  })
}