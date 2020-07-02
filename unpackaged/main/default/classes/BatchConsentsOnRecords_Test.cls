@isTest
private class BatchConsentsOnRecords_Test {
    @testSetup
    static void setup() {
        Account newVanCleefAndArpelsAccount = new Account();
        newVanCleefAndArpelsAccount.LastName = 'VanCleefAndArpelsAccount';
        newVanCleefAndArpelsAccount.RecordTypeId = RecordTypeHelper.getRTId('Account', 'RICSC_VanCleefAndArpels');
        newVanCleefAndArpelsAccount.RICSC_VIP__c = true;
        newVanCleefAndArpelsAccount.RICSC_ConsentTimestamp__c = Datetime.now().addDays(-5);
        newVanCleefAndArpelsAccount.RICSC_HasLocalRecords__c = true;
        insert newVanCleefAndArpelsAccount;

        Account newVanCleefAndArpelsAccount2 = new Account();
        newVanCleefAndArpelsAccount2.LastName = 'VanCleefAndArpelsAccount2';
        newVanCleefAndArpelsAccount2.RecordTypeId = RecordTypeHelper.getRTId('Account', 'RICSC_VanCleefAndArpels');
        newVanCleefAndArpelsAccount2.RICSC_VIP__c = false;
        newVanCleefAndArpelsAccount2.RICSC_ConsentTimestamp__c = Datetime.now().addMonths(-1);
        newVanCleefAndArpelsAccount2.RICSC_GoldenRecord__c = newVanCleefAndArpelsAccount.id;
        insert newVanCleefAndArpelsAccount2;

    }

    static testmethod void goldenCanBeContacted() {
      Test.startTest();
      TRG_TriggerDispatcher.skipTriggerMap.put('Account',true);
      Account goldenAccount = [SELECT Id, RICSC_GoldenRecord__c, RICSC_ConsentTimestamp__c, RICSC_CanBeContacted__c, RICSC_PostalContact__c, RICSC_ElectronicContact__c, RICSC_VoiceContact__c
                                                FROM Account
                                                WHERE LastName = 'VanCleefAndArpelsAccount'];
      goldenAccount.RICSC_CanBeContacted__c = true;
      goldenAccount.RICSC_ConsentTimestamp__c = Datetime.now();
      update goldenAccount;
      BatchConsentsOnRecords uca = new BatchConsentsOnRecords(true, null);
      Id batchid = Database.executeBatch(uca);
      Test.stopTest();
      List<Account> localRecords = [SELECT Id, RICSC_GoldenRecord__c, RICSC_ConsentTimestamp__c, RICSC_CanBeContacted__c, RICSC_PostalContact__c, RICSC_ElectronicContact__c, RICSC_VoiceContact__c
                                    FROM Account
                                    WHERE LastName = 'VanCleefAndArpelsAccount2'];
      List<Account> accountsWithFalseFlag = new List<Account>();
      for(Account acc : localRecords){
        if(!acc.RICSC_CanBeContacted__c){
          accountsWithFalseFlag.add(acc);
        }
      }
      System.assert(accountsWithFalseFlag.isEmpty(), 'Accounts with false flag');
    }

    static testmethod void localPostalContact() {
      Test.startTest();
      TRG_TriggerDispatcher.skipTriggerMap.put('Account',true);
      Account goldenAccount = [SELECT Id, RICSC_GoldenRecord__c, RICSC_ConsentTimestamp__c, RICSC_CanBeContacted__c, RICSC_PostalContact__c, RICSC_ElectronicContact__c, RICSC_VoiceContact__c
                                                FROM Account
                                                WHERE LastName = 'VanCleefAndArpelsAccount'];
      goldenAccount.RICSC_PostalContact__c = true;
      goldenAccount.RICSC_ConsentTimestamp__c = Datetime.now().addMonths(-10);
      update goldenAccount;
      BatchConsentsOnRecords uca = new BatchConsentsOnRecords(true, null);
      Id batchid = Database.executeBatch(uca);
      Test.stopTest();
      List<Account> localRecords = [SELECT Id, RICSC_GoldenRecord__c, RICSC_ConsentTimestamp__c, RICSC_CanBeContacted__c, RICSC_PostalContact__c, RICSC_ElectronicContact__c, RICSC_VoiceContact__c
                      FROM Account
                      WHERE LastName = 'VanCleefAndArpelsAccount2'];
      List<Account> accountsWithFalseFlag = new List<Account>();
      for(Account acc : localRecords){
        if(!acc.RICSC_PostalContact__c){
          accountsWithFalseFlag.add(acc);
        }
      }
      System.assert(accountsWithFalseFlag.size()>0, 'Accounts with false flag');
    }

   static testmethod void goldenElectronicContact() {
      Test.startTest();
      TRG_TriggerDispatcher.skipTriggerMap.put('Account',true);
      List<Account> localRecords = [SELECT Id, RICSC_GoldenRecord__c, RICSC_ConsentTimestamp__c, RICSC_CanBeContacted__c, RICSC_PostalContact__c, RICSC_ElectronicContact__c, RICSC_VoiceContact__c
                FROM Account
                WHERE LastName = 'VanCleefAndArpelsAccount2'];
      Account localRecord = localRecords.get(0);
      localRecord.RICSC_ElectronicContact__c = true;
      localRecord.RICSC_ConsentTimestamp__c = Datetime.now().addMonths(1);
      update localRecord;
      BatchConsentsOnRecords uca = new BatchConsentsOnRecords(true, null);
      Id batchid = Database.executeBatch(uca);
      Test.stopTest();
      List<Account> relatedRecords = [SELECT Id, RICSC_GoldenRecord__c, RICSC_ConsentTimestamp__c, RICSC_CanBeContacted__c, RICSC_PostalContact__c, RICSC_ElectronicContact__c, RICSC_VoiceContact__c
                      FROM Account
                      WHERE LastName = 'VanCleefAndArpelsAccount2' OR LastName = 'VanCleefAndArpelsAccount'];
      System.debug('==> relatedRecords: ' + relatedRecords);
      List<Account> accountsWithFalseFlag = new List<Account>();
      for(Account acc : relatedRecords){
        if(!acc.RICSC_ElectronicContact__c){
          accountsWithFalseFlag.add(acc);
        }
      }
      System.debug('==> accountsWithFalseFlag: ' + accountsWithFalseFlag);
      System.assert(accountsWithFalseFlag.isEmpty(), 'Accounts with false flag');
   }

   static testmethod void goldenVoiceContact() {
      Test.startTest();
      TRG_TriggerDispatcher.skipTriggerMap.put('Account',true);
      Account localRecord= [SELECT Id, RICSC_GoldenRecord__c, RICSC_ConsentTimestamp__c, RICSC_CanBeContacted__c, RICSC_PostalContact__c, RICSC_ElectronicContact__c, RICSC_VoiceContact__c
                FROM Account
                WHERE LastName = 'VanCleefAndArpelsAccount2'];
      localRecord.RICSC_VoiceContact__c = true;
      localRecord.RICSC_ConsentTimestamp__c = Datetime.now().addMonths(-1);
      update localRecord;
      BatchConsentsOnRecords uca = new BatchConsentsOnRecords(true, null);
      Id batchid = Database.executeBatch(uca);
      Test.stopTest();
      List<Account> relatedRecords = [SELECT Id, RICSC_GoldenRecord__c, RICSC_ConsentTimestamp__c, RICSC_CanBeContacted__c, RICSC_PostalContact__c, RICSC_ElectronicContact__c, RICSC_VoiceContact__c
                      FROM Account
                      WHERE LastName = 'VanCleefAndArpelsAccount2' OR LastName = 'VanCleefAndArpelsAccount'];
      List<Account> accountsWithFalseFlag = new List<Account>();
      for(Account acc : relatedRecords){
        if(!acc.RICSC_VoiceContact__c){
          accountsWithFalseFlag.add(acc);
        }
      }
      System.assert(accountsWithFalseFlag.size()>0, 'Accounts with false flag');

    }

}