declare module "@salesforce/apex/AP01_Task.getTaskSubject" {
  export default function getTaskSubject(): Promise<any>;
}
declare module "@salesforce/apex/AP01_Task.getRequestedTasks" {
  export default function getRequestedTasks(param: {filter: any}): Promise<any>;
}
declare module "@salesforce/apex/AP01_Task.getListUsers" {
  export default function getListUsers(param: {name: any}): Promise<any>;
}
declare module "@salesforce/apex/AP01_Task.getTaskRecords" {
  export default function getTaskRecords(param: {taskId: any}): Promise<any>;
}
declare module "@salesforce/apex/AP01_Task.handleBulkActions" {
  export default function handleBulkActions(param: {selectedJSON: any, owner: any, dueDate: any, bulkDelete: any}): Promise<any>;
}
