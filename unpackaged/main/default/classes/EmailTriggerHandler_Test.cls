@isTest
public with sharing class EmailTriggerHandler_Test {

@testSetup
  static void setup() {

    Contact newFrenchSalesAssociate = UtilityTests.getContact();
    newFrenchSalesAssociate.RICSC_CountryOfOrigin__c = 'France';
    insert newFrenchSalesAssociate;
    Contact newMonacoSalesAssociate = UtilityTests.getContact();
    newMonacoSalesAssociate.RICSC_CountryOfOrigin__c = 'Monaco';
    insert newMonacoSalesAssociate;

    Account newVanCleefAndArpelsAccount = UtilityTests.getPersonAccount();
    newVanCleefAndArpelsAccount.LastName = 'VanCleefAndArpelsFranceAccount';
    newVanCleefAndArpelsAccount.RICSC_VIP__c = true;
    newVanCleefAndArpelsAccount.RICSC_ReferenceSA__c = newFrenchSalesAssociate.Id;
    insert newVanCleefAndArpelsAccount;

    Account newVanCleefAndArpelsAccountGoldenRecord = UtilityTests.getPersonAccount();
    newVanCleefAndArpelsAccountGoldenRecord.LastName = 'newVanCleefAndArpelsAccountGoldenRecord';
    newVanCleefAndArpelsAccountGoldenRecord.RICSC_VIP__c = true;
    newVanCleefAndArpelsAccountGoldenRecord.RICSC_ReferenceSA__c = newMonacoSalesAssociate.Id;
    insert newVanCleefAndArpelsAccountGoldenRecord;

    RICSC_Email__c afterUpdateTestingEmail = UtilityTests.getEmail();
    afterUpdateTestingEmail.RICSC_Account__c = newVanCleefAndArpelsAccount.Id;
    insert afterUpdateTestingEmail;

    Account newVanCleefAndArpelsMonacoAccount = UtilityTests.getPersonAccount();
    newVanCleefAndArpelsMonacoAccount.LastName = 'VanCleefAndArpelsMonacoAccount';
    newVanCleefAndArpelsMonacoAccount.RICSC_VIP__c = true;
    newVanCleefAndArpelsMonacoAccount.RICSC_ReferenceSA__c = newMonacoSalesAssociate.Id;
    insert newVanCleefAndArpelsMonacoAccount;

  }

  static testmethod void afterInsertSharingRulesCreateOnEmailObjectLRANDGRFieldPopulated() {
    Contact frenchAccount = [SELECT Id FROM Contact WHERE RICSC_CountryOfOrigin__c = 'France' LIMIT 1];
    Account vanCleefAndArpelsAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c FROM Account WHERE Name = 'VanCleefAndArpelsFranceAccount'];
    Account newVanCleefAndArpelsAccountGoldenRecord = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c FROM Account WHERE Name = 'newVanCleefAndArpelsAccountGoldenRecord'];
    RICSC_Email__c testEmail = UtilityTests.getEmail();
    testEmail.RICSC_Account__c = vanCleefAndArpelsAccount.Id;
    insert testEmail;
    List<Group> gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMFrance' AND Id IN (SELECT UserOrGroupId FROM RICSC_Email__share)];
    System.assertEquals(false,gp.isEmpty());
    gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMMonaco' AND Id IN (SELECT UserOrGroupId FROM RICSC_Email__share)];
    System.assertEquals(true,gp.isEmpty());
  }


  static testmethod void afterInsertSharingRulesCreateOnEmailObjectLRFieldPopulated() {
    Contact frenchAccount = [SELECT Id FROM Contact WHERE RICSC_CountryOfOrigin__c = 'France' LIMIT 1];
    Account vanCleefAndArpelsAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c FROM Account WHERE Name = 'VanCleefAndArpelsFranceAccount'];
    RICSC_Email__c testEmail = UtilityTests.getEmail();
    testEmail.RICSC_Account__c = vanCleefAndArpelsAccount.Id;
    insert testEmail;

    List<Group> gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMFrance' AND Id IN (SELECT UserOrGroupId FROM RICSC_Email__share)];
    System.assertEquals(gp.isEmpty(),false);
  }


  static testmethod void afterUpdateSharingRulesCreateOnEmailObject() {

    //BeforeUpdate
    List<Group> gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMMonaco' AND Id IN (SELECT UserOrGroupId FROM RICSC_Email__share)];
    System.assertEquals(gp.isEmpty(),true);

    Account acc = [SELECT Id FROM Account WHERE Name = 'VanCleefAndArpelsMonacoAccount'];
    RICSC_Email__c updateEmail = [SELECT Id,RICSC_Account__c FROM RICSC_Email__c];
    updateEmail.RICSC_Account__c = acc.Id;
    update updateEmail;

    //AfterUpdate
    gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMMonaco' AND Id IN (SELECT UserOrGroupId FROM RICSC_Email__share)];
    System.assertEquals(gp.isEmpty(),false);
  }

}