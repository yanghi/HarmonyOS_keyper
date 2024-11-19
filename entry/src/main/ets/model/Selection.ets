@Observed
export class SelectionModel<Key extends keyof any = keyof any> {
  selected: Key[]

  constructor(options: { selected?: Key[] } = {}) {

    this.setSelected(options.selected || [])
  }

  isSelected(key: Key) {
    return this.selected.includes(key)
  }

  setSelected(keys: Key[]) {
    this.selected = keys
    return this.selected
  }

  unselect(key: Key) {
    this.selected = this.selected.filter(tkey => tkey !== key)
    return this.selected

  }

  select(key: Key) {
    this.selected = this.selected.concat(key)
    return this.selected

  }

  toggle(key: Key) {
    if (this.isSelected(key)) {
      this.unselect(key)
    } else {
      this.select(key)
    }
    return this.selected

  }
}