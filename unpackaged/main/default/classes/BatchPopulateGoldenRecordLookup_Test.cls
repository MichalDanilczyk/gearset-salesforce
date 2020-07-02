@isTest
private class BatchPopulateGoldenRecordLookup_Test {
  @testSetup
  static void setup() {

    TRG_TriggerSettings__c triggerSetting = TRG_TriggerSettings__c.getOrgDefaults();

    triggerSetting.DisableAllProcessBuilders__c = false;
    triggerSetting.DisableAllTriggers__c = true;
    triggerSetting.DisableAllWorkflows__c = false;
    triggerSetting.CheckEnabledOnLeanLoad__c = false;
    triggerSetting.PrintLimitsInDebug__c = true;
    triggerSetting.DisableTriggerMethods__c = '';
    triggerSetting.DisableTriggerObjects__c = '';

    upsert triggerSetting  TRG_TriggerSettings__c.Id;

    List<RICSC_Address__c> addresses = new List<RICSC_Address__c>();
    List<RICSC_Activity__c> activities = new List<RICSC_Activity__c>();
    List<RICSC_Phone__c> phones = new List<RICSC_Phone__c>();
    List<RICSC_Relation__c> relations = new List<RICSC_Relation__c>();
    List<RICSC_Email__c> emails = new List<RICSC_Email__c>();
    List<RICSC_Wishlist__c> wishlists = new List<RICSC_Wishlist__c>();
    List<RICSC_SocialMediaID__c> socialmediaIDs = new List<RICSC_SocialMediaID__c>();

    Account acc = UtilityTests.getPersonAccount();
    acc.LastName = 'AccountTransactionOwner';
    acc.RICSC_CountryofOrigin__c='Greece';
    acc.RICSC_SourceCRM__c = UtilityConstants.SOURCE_CRM_SAP;
    insert acc;
    Account myowner = [SELECT id FROM Account WHERE LastName = 'AccountTransactionOwner'];
    RICSC_Address__c adr1 = UtilityTests.getAddress();
    adr1.RICSC_Account__c = myowner.Id;
    addresses.add(adr1);
    RICSC_Address__c adr2 = UtilityTests.getAddress();
    adr2.RICSC_Account__c = myowner.Id;
    addresses.add(adr2);
    insert addresses;
    RICSC_Activity__c act1 = UtilityTests.getActivity();
    act1.RICSC_Account__c = myowner.Id;
    act1.Name='Activity1';
    activities.add(act1);
    RICSC_Activity__c act2 = UtilityTests.getActivity();
    act2.RICSC_Account__c = myowner.Id;
    act2.Name='Activity2';
    activities.add(act2);
    insert activities;
    RICSC_Email__c em1 = UtilityTests.getEmail();
    em1.RICSC_Account__c = myowner.Id;
    emails.add(em1);
    RICSC_Email__c em2 = UtilityTests.getEmail();
    em2.RICSC_Account__c = myowner.Id;
    emails.add(em2);
    insert emails;
    RICSC_Phone__c ph1 = UtilityTests.getPhone();
    ph1.RICSC_Account__c = myowner.Id;
    phones.add(ph1);
    RICSC_Phone__c ph2 = UtilityTests.getPhone();
    ph2.RICSC_Account__c = myowner.Id;
    phones.add(ph2);
    insert phones;
    RICSC_SocialMediaID__c soc1 = UtilityTests.getSocialMediaID();
    soc1.RICSC_Account__c = myowner.Id;
    socialmediaIDs.add(soc1);
    RICSC_SocialMediaID__c soc2 = UtilityTests.getSocialMediaID();
    soc2.RICSC_Account__c = myowner.Id;
    socialmediaIDs.add(soc2);
    insert socialmediaIDs;
    RICSC_Relation__c rel1 = UtilityTests.getRelation();
    rel1.RICSC_Account__c = myowner.Id;
    relations.add(rel1);
    RICSC_Relation__c rel2 = UtilityTests.getRelation();
    rel2.RICSC_Account__c = myowner.Id;
    relations.add(rel2);
    insert relations;
    RICSC_Wishlist__c wis1 = UtilityTests.getWishlist();
    wis1.RICSC_Account__c = myowner.Id;
    wishlists.add(wis1);
    RICSC_Wishlist__c wis2 = UtilityTests.getWishlist();
    wis2.RICSC_Account__c = myowner.Id;
    wishlists.add(wis2);
    insert wishlists;
    wishlists = [SELECT Id, RICSC_Account__c, RICSC_GoldenRecord__c FROM RICSC_Wishlist__c];
    System.debug('==> wishlists: ' + wishlists);
  }

  static testmethod void test() {
    Test.startTest();
    BatchPopulateGoldenRecordLookup b = new BatchPopulateGoldenRecordLookup(false,null);
    b.skipTriggers = true;
    Id batchId = Database.executeBatch(b);
    Test.stopTest();

    List<SObject> objects = new List<SObject>();
    objects.addAll([SELECT RICSC_GR__c, RICSC_Account__c FROM RICSC_Email__c]);
    objects.addAll([SELECT RICSC_GoldenRecord__c, RICSC_Account__c FROM RICSC_Activity__c]);
    objects.addAll([SELECT RICSC_GR__c, RICSC_Account__c FROM RICSC_SocialMediaID__c]);
    objects.addAll([SELECT RICSC_GR__c, RICSC_Account__c FROM RICSC_Address__c]);
    objects.addAll([SELECT RICSC_GoldenRecord__c, RICSC_Account__c FROM RICSC_Wishlist__c]);
    objects.addAll([SELECT RICSC_GoldenRecord__c, RICSC_Account__c FROM RICSC_Relation__c]);
    objects.addAll([SELECT RICSC_GR__c, RICSC_Account__c FROM RICSC_Phone__c]);

    Boolean error = false;
    for(SObject obj : objects){
      if(obj.getSobjectType().getDescribe().fields.getMap().keySet().contains('ricsc_goldenrecord__c')){
        if(!obj.get('RICSC_GoldenRecord__c').toString().equals(obj.get('RICSC_Account__c').toString())){
          error = true;
        }
      }
      else if(obj.getSobjectType().getDescribe().fields.getMap().keySet().contains('ricsc_gr__c')){
        if(!obj.get('RICSC_GR__c').toString().equals(obj.get('RICSC_Account__c').toString())){
          error = true;
        }
      }
    }

    System.assert(!error, 'Lookup not populated correctly');
  }
}