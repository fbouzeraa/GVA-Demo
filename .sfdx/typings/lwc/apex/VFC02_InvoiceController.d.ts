declare module "@salesforce/apex/VFC02_InvoiceController.sendInvoiceByEmailFromInvoiceId" {
  export default function sendInvoiceByEmailFromInvoiceId(param: {invoiceId: any, userEmail: any}): Promise<any>;
}
declare module "@salesforce/apex/VFC02_InvoiceController.downloadPDFInvoice" {
  export default function downloadPDFInvoice(param: {invoiceId: any}): Promise<any>;
}
declare module "@salesforce/apex/VFC02_InvoiceController.getOriginalInvoiceId" {
  export default function getOriginalInvoiceId(param: {subscriptionId: any}): Promise<any>;
}
