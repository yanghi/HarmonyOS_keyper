import relationalStore from '@ohos.data.relationalStore'
import common from '@ohos.app.ability.common';
import { CommonConstants } from '../constants/CommonConstants';
import Logger from '../utils/Logger'
import { DBColumnsRecord, rdbExtractResultRecords } from '../utils/DBUtils';

let context = getContext(this);

const LOG_TAG = '[Rdb]'

interface RelationalStoreManagerOptions {
  init(db: RelationalStoreManager): void
}

export class RelationalStoreManager {
  store: relationalStore.RdbStore | null = null
  context: common.UIAbilityContext | null = null

  constructor(private  config: relationalStore.StoreConfig, private  options: RelationalStoreManagerOptions) {
  }

  async init() {
    await this.options.init(this)
  }

  getRdbStore() {
    return new Promise<relationalStore.RdbStore>((resolve, reject) => {
      if (this.store) {
        resolve(this.store)
        return
      }
      relationalStore.getRdbStore(context, this.config, (err, rdbStore) => {
        this.store = rdbStore;
        if (err) {
          Logger.error(LOG_TAG, `Get RdbStore failed, code is ${err.code},message is ${err.message}`);
          reject(err)
          return;
        }
        Logger.info(LOG_TAG, `Get RdbStore successfully.`);
        resolve(rdbStore)
      })
    })
  }

  async commit() {
    const store = await this.getRdbStore()
    store.commit()

  }

  async rollback() {
    const store = await this.getRdbStore()
    store.rollBack()
  }

  async execute(sql: string) {
    try {
      const store = await this.getRdbStore()
      await store.executeSql(sql)
      Logger.info(LOG_TAG, 'execute sql "' + sql + '" ok')
    } catch (e) {
      Logger.error(LOG_TAG, 'execute sql "' + sql + '" failed; err:' + JSON.stringify(e))
      throw e
    }

  }

  async insert(table: string, values) {
    try {
      const store = await this.getRdbStore()
      Logger.info(LOG_TAG, 'insert table ' + table)
      let insertRes = await store.insert(table, values)
      Logger.info(LOG_TAG, 'insert table ' + table + ' ok, rowId=' + insertRes)
      return insertRes
    } catch (e) {
      Logger.error(LOG_TAG, 'insert table ' + table + ' failed')

      throw e
    }

  }

  async update(values: relationalStore.ValuesBucket, predicates: relationalStore.RdbPredicates) {
    try {
      const store = await this.getRdbStore()
      Logger.info(LOG_TAG, 'update by values')
      let insertRes = await store.update(values, predicates)
      Logger.info(LOG_TAG, 'update by values ok, rowId=' + insertRes)
      return insertRes
    } catch (e) {
      Logger.error(LOG_TAG, 'update by values failed, err:' + JSON.stringify(e))

      throw e
    }
  }

  async querySql(sql: string, bindArgs?) {

    const store = await this.getRdbStore()
    const qres = await store.querySql(sql, bindArgs)
    // getColumnIndex
    return qres
  }
}

export const AppRelationalStoreManager = new RelationalStoreManager({
  name: "RdbTest.db",
  securityLevel: relationalStore.SecurityLevel.S4
}, {
  init(db) {
    // db.execute('CREATE TABLE IF NOT EXISTS  (id INTEGER PRIMARY KEY AUTOINCREMENT;)')
    Logger.info(LOG_TAG, 'App executes create tables sql')
    return Promise.all([
    db.execute(CommonConstants.CREATE_ACCOUNT_BINDING_TABLE_SQL),
    db.execute(CommonConstants.SQL_CREATE_ACCOUNT_TABLE),
    db.execute(CommonConstants.SQL_CREATE_ACCOUNT_BINDING_CONTACT_TABLE),
    db.execute(CommonConstants.SQL_CREATE_LOCK_TABLE),
    db.execute(CommonConstants.SQL_CREATE_ACCOUNT_GROUP_TABLE)
    ])
  }
})
