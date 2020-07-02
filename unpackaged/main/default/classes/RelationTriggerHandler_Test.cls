@isTest
public with sharing class RelationTriggerHandler_Test {
    public RelationTriggerHandler_Test() {
      makeData();
    }

    @TestSetup
    static void makeData(){
      RICSC_RelationType__c type1 = new RICSC_RelationType__c(Name = 'Wife', RICSC_InverseRoleName__c = 'Husband');
      insert type1;
      RICSC_RelationType__c type2 = new RICSC_RelationType__c(Name = 'Husband', RICSC_InverseRoleName__c = 'Wife');
      insert type2;
      type1.RICSC_InverseRelationshipRole__c = type2.Id;
      type2.RICSC_InverseRelationshipRole__c = type1.Id;
      update type1;
      update type2;
    }

    @IsTest
    static void relationManagementTest(){
      Test.startTest();
      RICSC_RelationType__c wifeRelationType = [SELECT Id FROM RICSC_RelationType__c WHERE Name = 'Wife' LIMIT 1];
      RICSC_RelationType__c husbandRelationType = [SELECT Id FROM RICSC_RelationType__c WHERE Name = 'Husband' LIMIT 1];
      Account wife = new Account(FirstName = 'Wife', LastName = 'Account', RICSC_SourceCRM__c = 'SAP_CRM');
      insert wife;
      Account husband = new Account(FirstName = 'Husband', LastName = 'Account', RICSC_SourceCRM__c = 'SAP_CRM');
      insert husband;
      RICSC_Relation__c rel = new RICSC_Relation__c(RICSC_RelationType__c = wifeRelationType.Id, RICSC_Account__c = wife.Id, RICSC_RelatedAccount__c = husband.Id);
      insert rel;

      List<RICSC_Relation__c> inverseRelationship = [SELECT Id FROM RICSC_Relation__c WHERE RICSC_InverseRelationship__c = :rel.Id];
      System.assert(inverseRelationship.size() > 0);

      rel.RICSC_EndDate__c = Date.today();
      update rel;

      inverseRelationship = [SELECT Id,RICSC_EndDate__c FROM RICSC_Relation__c WHERE RICSC_InverseRelationship__c = :rel.Id];
      System.assert(inverseRelationship.size() > 0 && inverseRelationship.get(0).RICSC_EndDate__c != null);

      Test.stopTest();
    }
}