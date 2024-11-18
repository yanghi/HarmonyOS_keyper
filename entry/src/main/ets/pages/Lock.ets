import router from '@ohos.router'
import { AppLockType, CustomPwdValidateType } from '../common/enums/app'
import { AppRelationalStoreManager } from '../common/stores/relationalStore'
import { CipherModel, cipherModel } from '../model/Cipher'
import { AppLock } from '../model/Lock'
import promptAction from '@ohos.promptAction'
import Logger from '../common/utils/Logger'
import emitter from '@ohos.events.emitter'
import { EventId } from '../common/enums/Event'
import { TopNavBar } from '../components/TopNavBar'
import { PasswordStrengthIndicator } from '../components/PasswordStrengthIndicator'
import { CheckPasswordStrengthResult, PasswordStrength } from '../common/utils/CheckPasswordStrength'
import { PortCryptModel } from '../model/DataManager'
import { stringifyError } from '../common/utils/common'

const TAG = '[LockEntry]'

export interface VerifyParams {
  id: string
  reasonTitle?: string
  title?: string
  subTitle?: string
  callbackPayload?: any
  token?: string
  customPwdValidateType?: CustomPwdValidateType
}

@Entry
@Component
struct LockEntry {
  @State pwd: string = ''
  @State pwdErrTip: string = ''
  @State lockType: AppLockType = AppLockType.Create
  prevPwd: string = ''
  resetPwdInputFlag = false
  @State confirmPwdPhase: boolean = false
  private verifyParams: VerifyParams | null = null
  passwordStrengthResult: CheckPasswordStrengthResult | null = null

  checkIsVerifyMode() {
    Logger.info(TAG, 'checkIsVerifyMode')
    let routeParams = router.getParams() || {} as any
    if (routeParams.type === AppLockType.Verify) {
      Logger.debug(TAG, 'verify mode')
      this.lockType = AppLockType.Verify
      this.verifyParams = routeParams
      return true
    }
  }

  aboutToAppear() {
    if (this.checkIsVerifyMode()) return

    AppRelationalStoreManager.init().then(() => {
      return AppLock.lockIsSetup()
    }).then((isSetup) => {
      if (isSetup) {
        this.lockType = AppLockType.Login
      } else {
        this.lockType = AppLockType.Create

        // cipherModel.testAes()
        // cipherModel.testAesBigJsonText()
      }
    })
  }

  onPageShow() {
    this.checkIsVerifyMode()
  }

  createLock() {
    if (this.confirmPwdPhase) {
      if (this.pwd === this.prevPwd) {
        Logger.info(TAG, 'confirm password ok')
        AppLock.createLock(this.pwd).then(() => {
          this.unlock()
        }).catch(() => {
          promptAction.showToast({
            message: '创建密码失败'
          })
        })

      } else {
        this.pwd = ''
        this.resetPwdInputFlag = true
        this.pwdErrTip = '两次输入的密码不一致'
      }

      return
    }

    this.prevPwd = this.pwd
    this.confirmPwdPhase = true
    this.pwd = ''
  }

  unlock() {
    AppLock.unlock()
    router.replaceUrl({
      url: 'pages/Index',
    })
  }

  verify() {
    let customPwdValidate
    Logger.debug(TAG, 'verify , params:' + JSON.stringify(this.verifyParams))
    if (this.verifyParams.customPwdValidateType === CustomPwdValidateType.ImportTokenValidate) {
      customPwdValidate = (inputSecret: string) => {

        if (!this.verifyParams.token) {
          throw { code: 401, msg: 'miss verify token' }
        }
        let cipher = new CipherModel()
        cipher.setAESKeyBlob(inputSecret)
        Logger.debug(TAG, 'customPwdValidate.ImportTokenValidate()')

        return PortCryptModel.checkTokenWithCipher(this.verifyParams.token, cipher)
      }
    }

    if (customPwdValidate) {
      Logger.debug(TAG, 'use customPwdValidate type=' + this.verifyParams?.customPwdValidateType)
    }

    AppLock.isCorrectPwd(this.pwd, customPwdValidate).then(result => {
      if (!result.correct) {
        this.pwdErrTip = '密码错误'
        return
      }

      if (this.verifyParams) {
        AppLock.unlock()
        router.back()
        emitter.emit(
          { eventId: EventId.VerifySuccess },
          {
            data:
            {
              payload: this.verifyParams?.callbackPayload,
              inputSecret: result.inputSecret,
              id: this.verifyParams.id
            }
          }
        )
        this.verifyParams = null
      } else {
        this.unlock()
      }
    }).catch(e => {
      Logger.error(TAG, 'isCorrectPwd e ' + stringifyError(e))
    })
  }

  submit() {

    if (this.pwd == '') {
      this.pwdErrTip = '密码不能为空'

      return
    }
    if (this.lockType === AppLockType.Verify) {
      this.verify()
      return
    }

    if (this.lockType === AppLockType.Create) {
      if (!this.confirmPwdPhase && this.passwordStrengthResult && this.passwordStrengthResult.strength < PasswordStrength.Mid) {
        AlertDialog.show({
          title: '提示',
          message: '当前使用的密码强度过低,确定使用吗',
          autoCancel: true,
          alignment: DialogAlignment.Center,
          gridCount: 4,
          offset: { dx: 0, dy: -20 },
          primaryButton: {
            value: '确定',
            fontColor: 'red',
            action: () => {
              Logger.info(TAG, 'user confirm use wak pwd')

              this.createLock()
            }
          },
          secondaryButton: {
            value: '取消',
            action: () => {

            }
          },
          cancel: () => {

          }
        })
        return
      }

      this.createLock()
      return
    }

    AppLock.isCorrectPwd(this.pwd).then(result => {
      if (result.correct) {
        this.unlock()
      } else {
        this.pwdErrTip = '密码错误'
      }
    })
  }

  lockTitle() {
    if (this.lockType == AppLockType.Login) return '登录'
    if (this.lockType == AppLockType.Reset) return '重置数据'
    if (this.lockType == AppLockType.Create) {
      if (this.confirmPwdPhase) return '再次确认密码'
      return '设置访问密码'
    }

    if (this.lockType == AppLockType.Verify) return this.verifyParams?.title || '确认身份'

    throw 'not support this AppLockType'
  }

  confirmBtnText() {
    if (this.lockType == AppLockType.Login) return '解锁'
    if (this.lockType == AppLockType.Reset) return '重置'
    if (this.lockType == AppLockType.Create || this.lockType == AppLockType.Verify) return '确认'

    throw 'not support this AppLockType'
  }

  pwdInputController: TextInputController = new TextInputController()

  build() {
    Column() {
      if (this.lockType === AppLockType.Verify) {
        TopNavBar({ back: true, title: this.verifyParams?.reasonTitle ?? '' }) {
        }
      }

      Column() {
        Column() {
          Column() {
            Image($r('app.media.account_lock')).width(50).margin({ bottom: 10 })
            Text(this.lockTitle())
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
          }
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          // subtitle
          Row() {
            if (this.lockType == AppLockType.Verify && this.verifyParams) {
              if (this.verifyParams.reasonTitle) {
                Text('您想要进行"' + this.verifyParams.reasonTitle + '"操作,输入密码确认').fontSize(18)
              }
              if (this.verifyParams.subTitle) {
                Text(this.verifyParams.subTitle).fontSize(18)
              }
            }
          }.margin({ top: 10, bottom: 30 })

          Row() {
            TextInput({
              // controller: pwdInputController,
              text: this.pwd,
            })
              .focusable(true)
              .type(InputType.Password)
              .enterKeyType(EnterKeyType.Go)
              .onSubmit(() => this.submit())
              .onChange((v) => {
                this.pwd = v
                if (this.resetPwdInputFlag) {
                  this.resetPwdInputFlag = false
                } else {
                  this.pwdErrTip = ''
                }
              })
          }

          if (this.lockType === AppLockType.Create && !this.confirmPwdPhase) {
            PasswordStrengthIndicator({
              password: this.pwd,
              onStrengthResultChange: (res) => {
                this.passwordStrengthResult = res
              }
            })
          }
          Row() {
            Text(this.pwdErrTip)
              .fontColor('red')
              .fontSize(12)
              .align(Alignment.Center)
              .width('100%')
          }
          .height(20)
          .align(Alignment.Center)
          .alignItems(VerticalAlign.Center)
          .margin('6 0')

          Column() {
            Button({ type: ButtonType.Capsule }) {
              Row() {
                Text(this.confirmBtnText())
                  .fontColor(0xffffff)
              }
            }
            .fontColor(0xfff)
            .backgroundColor(0x317aff)
            .width('80%')
            .padding(10)
            .alignSelf(ItemAlign.Center)
            .onClick(() => this.submit())
          }
          .alignItems(HorizontalAlign.Center)
        }
        .margin({ top: '30%' })
      }.flexGrow(2)
      .padding({ left: '10%', right: '10%' })
      .justifyContent(FlexAlign.Center)

    }
    .alignItems(HorizontalAlign.Center)
    .width('100%')
  }
}