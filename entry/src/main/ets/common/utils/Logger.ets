import hilog from '@ohos.hilog';

const LOGGER_PREFIX: string = 'KeyperMain';

class Logger {
  private domain: number;
  private prefix: string;
  private format: string = '%{public}s %{public}s';

  constructor(prefix: string = '', domain: number = 0xFF00) {
    this.prefix = prefix;
    this.domain = domain;
  }

  debug(...args: string[]): void {
    hilog.debug(this.domain, this.prefix, this.format, args);
  }

  info(...args: string[]): void {
    hilog.info(this.domain, this.prefix, this.format, ...args);
  }

  infoF(format: string, ...args) {
    hilog.info(this.domain, this.prefix, format, ...args);
  }

  warn(...args: string[]): void {
    hilog.warn(this.domain, this.prefix, this.format, args);
  }

  error(...args: string[]): void {
    hilog.error(this.domain, this.prefix, this.format, args);
  }

  bindPrefix(prefix: string) {
    return new Logger(prefix)
  }
}

export const logger = new Logger(LOGGER_PREFIX, 0xFF02);

export default logger
