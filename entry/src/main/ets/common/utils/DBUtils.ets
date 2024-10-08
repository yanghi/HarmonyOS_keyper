import relationalStore from '@ohos.data.relationalStore'

export type DBColumnsRecord = {
  [x: string]: string
}

interface DBColumnDescription {
  type: string
  prop?: string
  default?: any
  propType?: 'boolean' | 'datetime'
}

type DBColumnsRecordN = {
  [x: string]: DBColumnDescription
}
const stringDataTypeKeys = ['CHARACTER', 'TEXT', 'VARCHAR']
const numberDataTypeKeys = ['DATETIME', 'BOOLEAN', 'DATE', 'INT', 'INTEGER']

export function rdbExtractResultRecords(res: relationalStore.ResultSet, colsRecord: DBColumnsRecord) {
  const records = []
  const cols: DBColumnsRecordN = {}
  for (let colName in colsRecord) {
    let colDescStr = colsRecord[colName]
    const colDescArr = colDescStr.split(' ')
    let [prop, type, propType] = colDescArr

    if (type === 'DATETIME') {
      propType = 'datetime'
    }

    cols[colName] = {
      prop: prop === '-' ? colName : prop,
      type,
      propType: propType as any
    }
  }

  while (res.goToNextRow()) {
    let record = {}
    for (let colName in cols) {
      let colDesc = cols[colName]
      let colIdx = res.getColumnIndex(colName)
      let raw
      if (stringDataTypeKeys.includes(colDesc.type)) {
        raw = res.getString(colIdx)
      } else if (numberDataTypeKeys.includes(colDesc.type)) {
        raw = res.getLong(colIdx)
      }

      if (raw === undefined) {

        record[colDesc.prop ?? colName] = colDesc.default ?? null
        continue
      }

      let value
      if (colDesc.propType) {
        if (colDesc.propType === 'boolean') {
          value = String(raw)
        } else if (colDesc.propType === 'datetime') {
          value = new Date(raw).toString()
        }
      }

      record[colDesc.prop ?? colName] = colDesc.propType ? value ?? raw : raw
    }

    records.push(record)
  }

  return records
}
