export enum EventId {
  AccountListUpdate,
  AccountDeletedListUpdate,
  AccountBindingListUpdate,
  AccountGroupListUpdate,
  VerifySuccess,
  Lock,
  AppForeground = 500,
  AppBackground = 501
}

export enum LockReason {
  Expired,
  User,
}

export interface LockEventPayload {
  reason: LockReason
}