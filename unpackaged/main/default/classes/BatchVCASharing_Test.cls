@isTest
private class BatchVCASharing_Test {

  @testSetup
  static void setup() {

    TRG_TriggerDispatcher.skipTriggerMap.put('SocialMediaIDTriggerHandler.VCARecordSharing',true);
    TRG_TriggerDispatcher.skipTriggerMap.put('PhoneTriggerHandler.VCARecordSharing',true);
    TRG_TriggerDispatcher.skipTriggerMap.put('EmailTriggerHandler.VCARecordSharing',true);
    TRG_TriggerDispatcher.skipTriggerMap.put('AddressTriggerHandler.VCARecordSharing',true);
    TRG_TriggerDispatcher.skipTriggerMap.put('TransactionTriggerHandler.VCARecordSharing',true);

    Contact newFrenchSalesAssociate = UtilityTests.getContact();
    newFrenchSalesAssociate.RICSC_CountryOfOrigin__c = 'France';
    insert newFrenchSalesAssociate;

    Contact newUSASalesAssociate = UtilityTests.getContact();
    newUSASalesAssociate.RICSC_CountryOfOrigin__c = 'USA';
    insert newUSASalesAssociate;

    Account newBoutique = UtilityTests.getBoutique();
    newBoutique.RICSC_CountryOfOrigin__c = 'France';
    newBoutique.RICSC_Maison__c = 'Cartier';
    newBoutique.RICSC_ReferenceSA__c = newUSASalesAssociate.Id;
    insert newBoutique;

    Account newVanCleefAndArpelsGoldenRecord = UtilityTests.getPersonAccount();
    newVanCleefAndArpelsGoldenRecord.LastName = 'VanCleefAndArpelsGoldenRecordAccount';
    newVanCleefAndArpelsGoldenRecord.RICSC_VIP__c = true;
    newVanCleefAndArpelsGoldenRecord.RICSC_HasLocalRecords__c = true;
    newVanCleefAndArpelsGoldenRecord.RICSC_IsGoldenRecord__c = true;
    newVanCleefAndArpelsGoldenRecord.RICSC_TotalNumberOfRepairs__c = 2;
    newVanCleefAndArpelsGoldenRecord.RICSC_TotalNumberOfRepairs__c = 0;
    newVanCleefAndArpelsGoldenRecord.RICSC_ReferenceSA__c = newFrenchSalesAssociate.Id;
    insert newVanCleefAndArpelsGoldenRecord;

    Account newVanCleefAndArpelsAccount = UtilityTests.getPersonAccount();
    newVanCleefAndArpelsAccount.LastName = 'VanCleefAndArpelsLocalReordAccount';
    newVanCleefAndArpelsAccount.RICSC_VIP__c = true;
    newVanCleefAndArpelsAccount.RICSC_ReferenceSA__c = newFrenchSalesAssociate.Id;
    newVanCleefAndArpelsAccount.RICSC_IsGoldenRecord__c = false;
    newVanCleefAndArpelsAccount.RICSC_GoldenRecord__c = newVanCleefAndArpelsGoldenRecord.id;
    insert newVanCleefAndArpelsAccount;

    RICSC_Address__c afterUpdateTestingAddress = UtilityTests.getAddress();
    afterUpdateTestingAddress.RICSC_Account__c = newVanCleefAndArpelsAccount.Id;
    insert afterUpdateTestingAddress;

    RICSC_Transaction__c testTransaction = new RICSC_Transaction__c(RICSC_SalesAssociate__c = newUSASalesAssociate.Id,RICSC_Boutique__c = newBoutique.Id,RICSC_Account__c = newVanCleefAndArpelsAccount.Id,RICSC_Maison__c = 'Cartier',RICSC_AmountWithTaxEUR__c = 260000,RICSC_CurrencyKey__c = 'EUR',RICSC_ExtCreationDate__c = Date.newInstance(2016, 12, 9),RICSC_CountryOfOrigin__c = 'Monaco');
    insert testTransaction;

    RICSC_Email__c afterUpdateTestingEmail = UtilityTests.getEmail();
    afterUpdateTestingEmail.RICSC_Account__c = newVanCleefAndArpelsAccount.Id;
    insert afterUpdateTestingEmail;

    RICSC_SocialMediaID__c afterUpdateTestingSocialMediaID = UtilityTests.getSocialMediaID();
    afterUpdateTestingSocialMediaID.RICSC_Account__c = newVanCleefAndArpelsAccount.Id;
    insert afterUpdateTestingSocialMediaID;

    RICSC_Phone__c afterUpdateTestingPhone = UtilityTests.getPhone();
    afterUpdateTestingPhone.RICSC_Account__c = newVanCleefAndArpelsAccount.Id;
    insert afterUpdateTestingPhone;

    Account newVanCleefAndArpelsNonVIPAccount = UtilityTests.getPersonAccount();
    newVanCleefAndArpelsNonVIPAccount.LastName = 'newVanCleefAndArpelsNonVIPAccount';
    newVanCleefAndArpelsNonVIPAccount.RICSC_VIP__c = false;
    newVanCleefAndArpelsNonVIPAccount.RICSC_ReferenceSA__c = newFrenchSalesAssociate.Id;
    insert newVanCleefAndArpelsNonVIPAccount;

    testTransaction = new RICSC_Transaction__c(RICSC_SalesAssociate__c = newFrenchSalesAssociate.Id,RICSC_Account__c = newVanCleefAndArpelsNonVIPAccount.Id,RICSC_Maison__c = 'Cartier',RICSC_AmountWithTax__c = 200,RICSC_CurrencyKey__c = 'EUR',RICSC_ExtCreationDate__c = Date.newInstance(2016, 12, 9),RICSC_CountryOfOrigin__c = 'Monaco');
    insert testTransaction;

    afterUpdateTestingEmail = UtilityTests.getEmail();
    afterUpdateTestingEmail.RICSC_Account__c = newVanCleefAndArpelsNonVIPAccount.Id;
    insert afterUpdateTestingEmail;

    afterUpdateTestingSocialMediaID = UtilityTests.getSocialMediaID();
    afterUpdateTestingSocialMediaID.RICSC_Account__c = newVanCleefAndArpelsNonVIPAccount.Id;
    insert afterUpdateTestingSocialMediaID;

    afterUpdateTestingPhone = UtilityTests.getPhone();
    afterUpdateTestingPhone.RICSC_Account__c = newVanCleefAndArpelsNonVIPAccount.Id;
    insert afterUpdateTestingPhone;

  }

  static testmethod void addressSharingRuleCheck() {

    Test.startTest();
    BatchVCASharing bas = new BatchVCASharing();
    Id batchId = Database.executeBatch(bas);
    Test.stopTest();

    List<Group> gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMFrance' AND Id IN (SELECT UserOrGroupId FROM RICSC_Address__share)];
    System.assertEquals(1,gp.size());
  }

  static testmethod void transactionSharingRuleCheck() {

    Test.startTest();
    BatchVCASharing bas = new BatchVCASharing();
    Id batchId = Database.executeBatch(bas);
    Test.stopTest();

    //country of origin based on the reference SA this is just for local records
    List<Group> gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMFrance' AND Id IN (SELECT UserOrGroupId FROM RICSC_Transaction__share)];
    System.assertEquals(1,gp.size());

    //Country of origin of transaction
    gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMMonaco' AND Id IN (SELECT UserOrGroupId FROM RICSC_Transaction__share)];
    System.assertEquals(1,gp.size());

    //country of origin based on the reference SA of the Account whitch in VCA record type is determined by the top 1 SA only for golden Record
    //In our case i hardcoded the reference SA in france but the cacluated fields changed the reference sa based on the top 1 SA after the transaction insert
    gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMUSA' AND Id IN (SELECT UserOrGroupId FROM RICSC_Transaction__share)];
    System.assertEquals(0,gp.size());
  }
}