@isTest
private class BatchAccountScrambler_Test {

  @testSetup
  static void setup() {

    insert new GeneralSettings__c(
      Scope__c = 'SBX',
      ErrorLog_EmailRecipient__c = 'ssholla@deloitte.gr'
    );

    Account newCartierPersonAccount = new Account();
    newCartierPersonAccount.FirstName = 'FirstName';
    newCartierPersonAccount.LastName = 'LastName';
    newCartierPersonAccount.RecordTypeId = RecordTypeHelper.getRTId('Account', 'RICSC_Cartier');

    insert newCartierPersonAccount;

    Account newBoutiquePersonAccount = new Account();
    newBoutiquePersonAccount.Name = 'BoutiqueName';
    newBoutiquePersonAccount.RecordTypeId = RecordTypeHelper.getRTId('Account', 'RICSC_Boutique');

    insert newBoutiquePersonAccount;
  }

  static testmethod void correctRecordType() {

    //Query the Records before and after batch calculations
    //Because RecordType is not equal to Boutique it does the proper modifications so

    Account accBeforeBatchExec = [SELECT Id,FirstName,LastName FROM Account WHERE RecordTypeId = :RecordTypeHelper.getRTId('Account', 'RICSC_Cartier') LIMIT 1];

    Test.startTest();
    BatchAccountScrambler bas = new BatchAccountScrambler(true, null);
    Id batchId = Database.executeBatch(bas);
    Test.stopTest();

    Account accAfterBatchExec = [SELECT Name FROM Account WHERE RecordTypeId = :RecordTypeHelper.getRTId('Account', 'RICSC_Cartier') LIMIT 1];

    System.assertEquals(accBeforeBatchExec.Id +
                        accBeforeBatchExec.FirstName.substring(0,1) + ' ' +
                        accBeforeBatchExec.Id +
                        accBeforeBatchExec.LastName.substring(0,1), accAfterBatchExec.Name, 'Account name not scrambled correctly');
  }

  static testmethod void incorrectRecordType() {

    //Query the Records before and after batch calculations
    //Because RecordType is Boutique it doesnt do the proper modifications so
    //the last modification date is the same before and after

    Account accBeforeBatchExec = [SELECT Id,LastModifiedDate FROM Account WHERE RecordTypeId = :RecordTypeHelper.getRTId('Account', 'RICSC_Boutique')];

    Test.startTest();
    BatchAccountScrambler bas = new BatchAccountScrambler(true, null);
    Id batchId = Database.executeBatch(bas);
    Test.stopTest();

    Account accAfterBatchExec = [SELECT Id,LastModifiedDate FROM Account WHERE RecordTypeId = :RecordTypeHelper.getRTId('Account', 'RICSC_Boutique')];

    System.assertEquals(accBeforeBatchExec.LastModifiedDate,accAfterBatchExec.LastModifiedDate, 'Account name not scrambled correctly');
  }
}