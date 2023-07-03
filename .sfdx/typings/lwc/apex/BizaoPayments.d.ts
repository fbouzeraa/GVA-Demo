declare module "@salesforce/apex/BizaoPayments.isFrancophone" {
  export default function isFrancophone(): Promise<any>;
}
declare module "@salesforce/apex/BizaoPayments.mobileMoneyPayment" {
  export default function mobileMoneyPayment(param: {amount: any, operator: any, order: any, recordId: any}): Promise<any>;
}
declare module "@salesforce/apex/BizaoPayments.bankPayment" {
  export default function bankPayment(param: {amount: any, order: any, recordId: any}): Promise<any>;
}
declare module "@salesforce/apex/BizaoPayments.mobileMoneyStatus" {
  export default function mobileMoneyStatus(param: {operator: any, orderId: any, subCountryCode: any}): Promise<any>;
}
declare module "@salesforce/apex/BizaoPayments.bankPaymentStatus" {
  export default function bankPaymentStatus(param: {orderId: any, recordId: any}): Promise<any>;
}
