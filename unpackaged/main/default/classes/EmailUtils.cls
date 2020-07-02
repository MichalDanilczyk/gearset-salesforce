public class EmailUtils {

  public static void batchEmailDetails(String ayncApexJobId, String className, List<Exception> errorLogs){

    AsyncApexJob job = [SELECT Id, Status, NumberOfErrors,CreatedDate,
                        JobItemsProcessed,MethodName,CompletedDate,
                        TotalJobItems, CreatedBy.Email
                        FROM AsyncApexJob
                        WHERE Id = :ayncApexJobId];

    Long elapsedTime = job.CompletedDate.getTime() - job.CreatedDate.getTime();
    String errorLog = (errorLogs.size() != 0) ? 'Error Message : '+errorLogs.get(0).getMessage(): '';

    String body = 'ID : ' + job.Id + '\n' +
                  'Status : ' + job.Status + '\n' +
                  'Elapsed Time : '+ elapsedTime / 1000 + ' seconds\n' +
                  'Total Job Items : ' + job.TotalJobItems + '\n' +
                  'Job Items Processed : ' + job.JobItemsProcessed + '\n' +
                  'Class Name : ' + className + '\n' + errorLog;

    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
    List<String> receiversMails = new List<String>();
    ReceiversMails.add(job.CreatedBy.Email);
    message.toAddresses = receiversMails;
    message.optOutPolicy = 'FILTER';
    message.subject = 'Batch Excecution';
    message.plainTextBody = body;
    Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
    Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

    System.debug(Body);
    if (results[0].success) {
        System.debug('The email was sent successfully.');
    } else {
        System.debug('The email failed to send: ' + results[0].errors[0].message);
    }
  }
}