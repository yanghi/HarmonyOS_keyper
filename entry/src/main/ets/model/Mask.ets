function asterisk(val: string, start: number, end = val.length - 2) {
  // function  fill(val, start, end){

  if (start > val.length - 1) {
    return val
  }

  let strArr = new Array(val.length).fill('*')
  let endIdx = end > 0 ? end : Math.max(start, val.length + end)

  for (let i = start; i > -1; i--) {
    strArr[i] = val[i]
  }

  for (let j = endIdx; j < val.length; j++) {
    strArr[j] = val[j]
  }

  return strArr.join('')
}

const EMAIL_REG = /@/
const PHONE_REG = /d+/

function desensitization(val: string) {
  if (EMAIL_REG.test(val)) {
    let f = val.indexOf('@')
    return asterisk(val, 3, f)
  }

  if (val.length < 4) return asterisk(val, 0, 3)
  return asterisk(val, 1, -1)
}

export class MaskObject<Data extends object, Keys extends Array<keyof Data>> {
  masked: Record<Keys[0], boolean>
  private _maskedData: Record<Keys[0], string>

  constructor(public data: Data, keys: Keys, private  options: { initMask?: boolean } = { initMask: true }) {
    this.masked = {} as any
    this._maskedData = {} as any
    keys.forEach(key => {
      this.masked[key] = options.initMask
      this.updateMask(key)
    })
  }

  private updateMask(key: Keys[0]) {
    let value = this.data[key] as any as string
    this._maskedData[key] = desensitization(value)
  }

  isMasked(key: Keys[0]) {
    return this.masked[key]
  }

  isAllMasked() {
    for (let k in this.masked) {
      if (!this.masked[k]) return false
    }

    return true
  }

  toggleMask(key: Keys[0]) {

    this.masked[key] = !this.masked[key]
  }

  toggleAllMask() {
    let dest = !this.isAllMasked()
    for (let k in this.masked) {
      this.masked[k] = dest
    }
  }

  getValue<K extends keyof Data>(key: K): Data[K] {
    return this.masked[key] ? this._maskedData[key] : this.data[key] as any
  }

  setValue(key: keyof Data, value: string) {
    this.data[key] = value as any
    if (key in this.masked) {
      this.updateMask(key)
    }
  }
}

