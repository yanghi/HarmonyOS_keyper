// 正则表达式定义
import logger from './Logger';

const REG_NUMBER = /[0-9]/;
const REG_UPPERCASE = /[A-Z]/;
const REG_LOWERCASE = /[a-z]/;
const REG_SYMBOL = /[!@#$%^&*()+_\-=}{[\]|:;"/?.><,`~]/;

export enum PasswordStrength {
  VeryWeak,
  Weak,
  Mid,
  Strong,
  VeryStrong
}

interface PasswordContain {
  numbers: boolean
  symbols: boolean
  upperCase: boolean
  lowerCase: boolean
}

export interface CheckPasswordStrengthResult {
  tips: string[]
  strength: PasswordStrength
  contain: PasswordContain
}

const TAG = '[PasswordStrength]'

// 密码强度校验函数
export const checkPasswordStrength = (password: string): CheckPasswordStrengthResult => {
  logger.debug(TAG, 'password: ' + password)
  // [[0,1],[0,1]]
  let result: CheckPasswordStrengthResult = {
    tips: [],
    strength: PasswordStrength.VeryWeak,
    contain: {
      numbers: false,
      symbols: false,
      upperCase: false,
      lowerCase: false,
    }
  }
  let score = 0
  let digitScore = 0
  let charKindAmount = 0;
  let messyScore = 1

  let weakTips: string[] = []
  if (password === '' || password.length < 8 || password.length > 32) {
    weakTips.push("密码长度应大于8");
  }

  let continuous = checkContinuousChar(password)
  logger.debug(TAG, 'checkContinuousChar ' + continuous)

  if (continuous) {
    messyScore *= Math.pow(((password.length - continuous) / password.length), 2)
    weakTips.push("请勿包含相同或连续的字符");
  }
  let keyBoardContinuous = checkKeyBoardContinuousChar(password)
  if (keyBoardContinuous) {
    messyScore *= Math.pow(((password.length - keyBoardContinuous) / password.length), 2)

    logger.debug(TAG, 'checkKeyBoardContinuousChar ' + keyBoardContinuous)
    weakTips.push("请勿包含键盘上连续的字符")
  }

  if (REG_NUMBER.test(password)) {
    charKindAmount++
    result.contain.numbers = true
    digitScore += 10
  }
  ;
  if (REG_UPPERCASE.test(password)) {
    result.contain.upperCase = true

    charKindAmount++;
    digitScore += 26
  }
  if (REG_LOWERCASE.test(password)) {
    result.contain.lowerCase = true
    charKindAmount++;
    digitScore += 26
  }
  if (REG_SYMBOL.test(password)) {
    result.contain.symbols = true
    digitScore += 37
    charKindAmount++;
  }

  score = (password.length / 8) * messyScore * digitScore

  if (score < 10) {
    result.strength = PasswordStrength.VeryWeak
  } else if (score < 26) {
    result.strength = PasswordStrength.Weak
  } else if (score < 52 * 0.75) {
    result.strength = PasswordStrength.Mid
  } else if (score < 52) {
    result.strength = PasswordStrength.Strong
  } else {
    result.strength = PasswordStrength.VeryStrong
  }

  if (result.strength == PasswordStrength.VeryWeak || result.strength == PasswordStrength.Weak) {
    result.tips.push(...weakTips)
  }

  logger.debug(TAG, 'scores ' + score + ' messyScore ' + messyScore + ' dit ' + digitScore)
  logger.debug(TAG, 'resut ' + JSON.stringify(result))
  return result

};

// 检查是否有连续字符
function checkContinuousChar(password: string) {
  let count = 0
  for (let i = 0; i < password.length - 1; i++) {
    if (password.charCodeAt(i) === password.charCodeAt(i + 1)) {
      count++
    }
  }
  return count;
}
// 检查是否有键盘上连续的字符
function checkKeyBoardContinuousChar(password: string) {
  const CHAR_TABLE1: string[][] = [
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '='],
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\\'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\''],
    ['z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/']
  ];
  const CHAR_TABLE2: string[][] = [
    ['!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+'],
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', '|'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '"'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?']
  ];
  let count = 0
  for (let i = 0; i < password.length - 1; i++) {
    for (let j = 0; j < CHAR_TABLE1.length; j++) {
      for (let k = 0; k < CHAR_TABLE1[j].length; k++) {
        if (password[i] === CHAR_TABLE1[j][k] &&
        password[i + 1] === CHAR_TABLE1[j][k + 1]) {
          count++
        }
      }
    }
    for (let j = 0; j < CHAR_TABLE2.length; j++) {
      for (let k = 0; k < CHAR_TABLE2[j].length; k++) {
        if (password[i] === CHAR_TABLE2[j][k] &&
        password[i + 1] === CHAR_TABLE2[j][k + 1]) {
          count++
        }
      }
    }
  }
  return count;
}