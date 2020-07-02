@isTest
private class BatchDefaultRecord_Test {

  @testSetup
  static void setup() {

    TRG_TriggerDispatcher.skipTriggerMap.put('EmailTriggerHandler.DefaultEmailCheck',true);
    TRG_TriggerDispatcher.skipTriggerMap.put('AddressTriggerHandler.DefaultAddressCheck',true);
    TRG_TriggerDispatcher.skipTriggerMap.put('PhoneTriggerHandler.DefaultPhoneCheck',true);
    TRG_TriggerDispatcher.skipTriggerMap.put('SocialMediaIDTriggerHandler.DefaultSocialMediaIDCheck',true);
    TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.defaultRecordsBasedOnMasterRecordScore',true);

    Account newPersonAccountLR = UtilityTests.getPersonAccount();
    newPersonAccountLR.FirstName = 'FirstName';
    newPersonAccountLR.LastName = 'LastName';

    insert newPersonAccountLR;

    List<RICSC_Email__c> emails = new List<RICSC_Email__c>();

    RICSC_Email__c newEmail = UtilityTests.getEmail();
    newEmail.RICSC_Account__c = newPersonAccountLR.Id;
    emails.add(newEmail);

    RICSC_Email__c newEmail1 = UtilityTests.getEmail();
    newEmail1.RICSC_Account__c = newPersonAccountLR.Id;
    newEmail1.RICSC_DefaultEmail__c = true;
    emails.add(newEmail1);

    RICSC_Email__c newEmail2 = UtilityTests.getEmail();
    newEmail2.RICSC_Account__c = newPersonAccountLR.Id;
    emails.add(newEmail2);

    insert emails;

    List<RICSC_Phone__c> phones = new List<RICSC_Phone__c>();
    RICSC_Phone__c newPhone = UtilityTests.getPhone();
    newPhone.RICSC_Account__c = newPersonAccountLR.Id;
    phones.add(newPhone);

    insert phones;

    List<RICSC_socialMediaId__c> socialMediaIds = new List<RICSC_socialMediaId__c>();
    RICSC_socialMediaId__c newsocialMediaId = UtilityTests.getsocialMediaId();
    newsocialMediaId.RICSC_Account__c = newPersonAccountLR.Id;
    socialMediaIds.add(newsocialMediaId);

    insert socialMediaIds;

    List<RICSC_address__c> addresss = new List<RICSC_address__c>();
    RICSC_address__c newaddress = UtilityTests.getaddress();
    newaddress.RICSC_Account__c = newPersonAccountLR.Id;
    addresss.add(newaddress);

    insert addresss;
  }

  static testmethod void defaultEmailCheck() {
    Test.startTest();
    BatchDefaultRecord bas = new BatchDefaultRecord(false, null);
    Id batchId = Database.executeBatch(bas);
    Test.stopTest();
    System.assertEquals(1,[SELECT Id FROM RICSC_Email__c WHERE RICSC_DefaultGREmail__c = true].size(), 'Email not set as default');
    System.assertEquals(1,[SELECT Id FROM RICSC_Email__c WHERE RICSC_DefaultEmail__c = true].size(), 'Email not set as default');
  }

  static testmethod void defaultAddressCheck() {
    Test.startTest();
    BatchDefaultRecord bas = new BatchDefaultRecord(false, null);
    Id batchId = Database.executeBatch(bas);
    Test.stopTest();
    System.assertEquals(1,[SELECT Id FROM RICSC_Address__c WHERE RICSC_GRMainAddress__c = true].size(), 'Address not set as default');
    System.assertEquals(1,[SELECT Id FROM RICSC_Address__c WHERE RICSC_LRMainAddress__c = true].size(), 'Address not set as default');
  }

  static testmethod void defaultSocialMediaIDCheck() {
    Test.startTest();
    BatchDefaultRecord bas = new BatchDefaultRecord(false, null);
    Id batchId = Database.executeBatch(bas);
    Test.stopTest();
    System.assertEquals(1,[SELECT Id FROM RICSC_SocialMediaID__c WHERE RICSC_DefaultGRSocialMediaID__c = true].size(), 'Social ID not set as default');
    System.assertEquals(1,[SELECT Id FROM RICSC_SocialMediaID__c WHERE RICSC_DefaultSocialMediaID__c = true].size(), 'Social ID not set as default');
  }

   static testmethod void defaultPhoneCheck() {
    Test.startTest();
    BatchDefaultRecord bas = new BatchDefaultRecord(false, null);
    Id batchId = Database.executeBatch(bas);
    Test.stopTest();
    System.assertEquals(1,[SELECT Id FROM RICSC_Phone__c WHERE RICSC_DefaultGRPhone__c = true].size(), 'Phone not set as default');
    System.assertEquals(1,[SELECT Id FROM RICSC_Phone__c WHERE RICSC_DefaultPhone__c = true].size(), 'Phone not set as default');
  }

  static testmethod void defaultPhoneCheckSkippTriggers() {
    Test.startTest();
    BatchDefaultRecord bas = new BatchDefaultRecord(true, null);
    Id batchId = Database.executeBatch(bas);
    Test.stopTest();
    System.assertEquals(1,[SELECT Id FROM RICSC_Phone__c WHERE RICSC_DefaultGRPhone__c = true].size(), 'Phone not set as default');
  }

}