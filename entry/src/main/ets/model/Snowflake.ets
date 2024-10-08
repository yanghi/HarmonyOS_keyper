export class Snowflake {
  private _val: string
  private _snow: string
  snow: boolean = false

  get value() {
    if (this.snow) {
      return this._snow
    } else {
      return this._val
    }
  }

  constructor(value: string) {
    this._val = value
  }
}