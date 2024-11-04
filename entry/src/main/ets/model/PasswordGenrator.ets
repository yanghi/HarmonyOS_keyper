import cryptoFramework from '@ohos.security.cryptoFramework';
import { stringifyError } from '../common/utils/common';
import { logger } from '../common/utils/Logger';

let pool: Uint8Array[] = []
let maxPoolLength = 3
let poolGenWip = 0
let randomIndex = 0

function getRandomPool() {

  while (poolGenWip < maxPoolLength && pool.length < maxPoolLength) {

    poolGenWip++
    logger.info('[getRandomPools generateRandom]', 'wip ' + poolGenWip + ' total ' + pool.length)

    cryptoFramework.createRandom().generateRandom(256, (err, data) => {
      poolGenWip--
      if (err) {
        logger.error('[getRandomPools generateRandom]', stringifyError(err))
        return
      }

      logger.info('[getRandomPools generateRandom]', 'generate random succeed')

      pool.push(data.data)
    })
  }
}

getRandomPool()

function fallbackRandValue() {
  return Math.floor(Math.random() * 256)
}

function nextRandValue(): number {
  let randomBytes = pool[0]

  if (pool.length < maxPoolLength) {
    getRandomPool()
  }

  if (!randomBytes) {
    logger.warn('[nextRandValue]', 'random pool is unavailable, use fallback rand')
    randomIndex = 0
    return fallbackRandValue()
  }

  if (randomIndex >= randomBytes.length) {
    randomIndex = 0;
    pool.shift()
    return nextRandValue()
  }

  var result = randomBytes[randomIndex];
  randomIndex += 1;

  return result;
}

function random(max: number) {
  var rand = nextRandValue();
  while (rand >= 256 - (256 % max)) {
    rand = nextRandValue();
  }

  return rand % max;
}

export enum DigitType {
  LowerAlpha = 1,
  UpperAlpha = 1 << 1,
  Numeric = 1 << 2,
  Punctuation = 1 << 3
}

interface DigitOptionsCharLetters {
  charLetters: string
}

interface DigitOptionsBase {
  type: DigitType
  required?: boolean
}

interface DigitOptions extends DigitOptionsBase, Partial<DigitOptionsCharLetters> {}

interface DigitOptionsNormalized extends DigitOptionsBase, DigitOptionsCharLetters {}

type DigitOptionType = DigitType | DigitOptions

interface GenOptions {
  length?: [number, number]
  digit?: DigitOptionType[]
}


const NUMERIC = '0123456789'
const LOWER_ALPHA = 'abcdefghijklmnopqrstuvwxyz'
const UPPER_ALPHA = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

const PUNCTUATION = '!@#$%^&*()+_-=}{[]|:;"/?.><,`~'

const FULL_DEFAULT_TYPE: DigitOptionsNormalized[] = [
  {
    type: DigitType.LowerAlpha,
    charLetters: LOWER_ALPHA
  }, {
  type: DigitType.UpperAlpha,
  charLetters: UPPER_ALPHA
},
  {
    type: DigitType.Numeric,
    charLetters: NUMERIC
  },
  {
    type: DigitType.Punctuation,
    charLetters: PUNCTUATION
  }
]

function normalizeDigitOptions(options: DigitOptionType): DigitOptionsNormalized {
  let normalized = typeof options == 'number' ? { type: options } : options
  if (!normalized.charLetters) {
    let defaultOpt = FULL_DEFAULT_TYPE.find(o => o.type === normalized.type)
    if (!defaultOpt) {
      throw new Error('invalid digit type ' + normalized.type)
    }
    normalized.charLetters = defaultOpt.charLetters
  }

  return normalized as DigitOptionsNormalized
}

function randLength(min, max) {
  if (min === max) return min

  return min + Math.floor(Math.random() * (max - min))
}

const PasswordGeneratorTag = '[PasswordGenerator]'

export class PasswordGenerator {
  private digitOptions: DigitOptionsNormalized[]

  constructor(private  options: GenOptions) {
    this.digitOptions = options.digit?.map(opt => normalizeDigitOptions(opt)) || FULL_DEFAULT_TYPE
  }

  generate() {
    const {length = [18, 30]} = this.options
    const [minLen = 18, maxLen = 30] = length

    let destPasswordLen = randLength(minLen, maxLen)
    let chars = '';
    let password = '';

    this.digitOptions.forEach(typeOpts => {
      chars += typeOpts.charLetters
    })

    while (password.length < destPasswordLen) {
      password += chars[random(chars.length)]
    }

    let allExpected = this.digitOptions.every(opt => {
      if (!opt.required) return true
      for (let i = 0; i < password.length; i++) {
        for (let j = 0; j < opt.charLetters.length; j++) {
          if (password[i] === opt.charLetters[j]) return true
        }
      }

      return false
    })

    if (!allExpected) {
      logger.info(PasswordGeneratorTag, 'regenerate')
      return this.generate()
    }

    return password
  }

  generateMultiple(amount: number) {
    var passwords: string[] = [];

    for (var i = 0; i < amount; i++) {
      passwords[i] = this.generate();
    }

    return passwords;
  }
}