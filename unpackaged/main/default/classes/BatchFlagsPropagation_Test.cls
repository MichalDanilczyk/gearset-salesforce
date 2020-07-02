@isTest
private class BatchFlagsPropagation_Test {
    @testSetup
    static void setup() {
      List<RICSC_Address__c> addresses = new List<RICSC_Address__c>();
      List<RICSC_Activity__c> activities = new List<RICSC_Activity__c>();
      List<RICSC_Phone__c> phones = new List<RICSC_Phone__c>();
      List<RICSC_Relation__c> relations = new List<RICSC_Relation__c>();
      List<RICSC_Email__c> emails = new List<RICSC_Email__c>();
      List<RICSC_Wishlist__c> wishlists = new List<RICSC_Wishlist__c>();
      List<RICSC_SocialMediaID__c> socialmediaIDs = new List<RICSC_SocialMediaID__c>();


      Account accGR = UtilityTests.getPersonAccount();
      accGR.LastName = 'GRAccount';
      insert accGR;
      Account acc = UtilityTests.getPersonAccount();
      acc.LastName = 'LRAccount';
      acc.RICSC_GoldenRecord__c = accGR.id;
      acc.RICSC_IsGoldenRecord__c = false;
      insert acc;

      RICSC_Address__c adr1 = UtilityTests.getAddress();
      adr1.RICSC_Account__c = acc.Id;
      addresses.add(adr1);
      RICSC_Address__c adr2 = UtilityTests.getAddress();
      adr2.RICSC_Account__c = acc.Id;
      addresses.add(adr2);
      insert addresses;
      RICSC_Activity__c act1 = UtilityTests.getActivity();
      act1.RICSC_Account__c = acc.Id;
      act1.Name='Activity1';
      activities.add(act1);
      RICSC_Activity__c act2 = UtilityTests.getActivity();
      act2.RICSC_Account__c = acc.Id;
      act2.Name='Activity2';
      activities.add(act2);
      insert activities;
      RICSC_Email__c em1 = UtilityTests.getEmail();
      em1.RICSC_Account__c = acc.Id;
      emails.add(em1);
      RICSC_Email__c em2 = UtilityTests.getEmail();
      em2.RICSC_Account__c = acc.Id;
      emails.add(em2);
      insert emails;
      RICSC_Phone__c ph1 = UtilityTests.getPhone();
      ph1.RICSC_Account__c = acc.Id;
      phones.add(ph1);
      RICSC_Phone__c ph2 = UtilityTests.getPhone();
      ph2.RICSC_Account__c = acc.Id;
      phones.add(ph2);
      insert phones;
      RICSC_SocialMediaID__c soc1 = UtilityTests.getSocialMediaID();
      soc1.RICSC_Account__c = acc.Id;
      socialmediaIDs.add(soc1);
      RICSC_SocialMediaID__c soc2 = UtilityTests.getSocialMediaID();
      soc2.RICSC_Account__c = acc.Id;
      socialmediaIDs.add(soc2);
      insert socialmediaIDs;
      RICSC_Relation__c rel1 = UtilityTests.getRelation();
      rel1.RICSC_Account__c = acc.Id;
      relations.add(rel1);
      RICSC_Relation__c rel2 = UtilityTests.getRelation();
      rel2.RICSC_Account__c = acc.Id;
      relations.add(rel2);
      insert relations;
      RICSC_Wishlist__c wis1 = UtilityTests.getWishlist();
      wis1.RICSC_Account__c = acc.Id;
      wishlists.add(wis1);
      RICSC_Wishlist__c wis2 = UtilityTests.getWishlist();
      wis2.RICSC_Account__c = acc.Id;
      wishlists.add(wis2);
      insert wishlists;
    }

    static testmethod void testSync() {
      Test.startTest();
      TRG_TriggerDispatcher.skipTriggerMap.put('Account',true);
      Account ac2 = [SELECT Id FROM Account WHERE LastName = 'LRAccount'];
      ac2.put('RICSC_VIP__c',true);
      ac2.put('RICSC_HighJewelleryClient__c',true);
      update ac2;
      BatchFlagsPropagation uca = new BatchFlagsPropagation(true,null);
      Id batchId = Database.executeBatch(uca);
      Test.stopTest();
      System.assert([SELECT RICSC_VIP__c FROM Account WHERE LastName = 'GRAccount'][0].RICSC_VIP__c, 'Account is not VIP');
      System.assert([SELECT RICSC_VIP__c FROM RICSC_Email__c][0].RICSC_VIP__c, 'Email is not VIP');
      System.assert([SELECT RICSC_HighJewelleryClient__c FROM RICSC_Email__c][1].RICSC_HighJewelleryClient__c, 'Email is not high jewelery');
      System.assert([SELECT RICSC_VIP__c FROM RICSC_Activity__c][0].RICSC_VIP__c, 'Activity is not VIP');
      System.assert([SELECT RICSC_VIP__c FROM RICSC_SocialMediaID__c][0].RICSC_VIP__c, 'Social Media ID is not VIP');
      System.assert([SELECT RICSC_VIP__c FROM RICSC_Address__c][0].RICSC_VIP__c, 'Address is not VIP');
      System.assert([SELECT RICSC_HighJewelleryClient__c FROM RICSC_Wishlist__c][0].RICSC_HighJewelleryClient__c, 'Wishlist is not high jewelery');
      System.assert([SELECT RICSC_VIP__c FROM RICSC_Relation__c][0].RICSC_VIP__c, 'Relation is not VIP');
      System.assert([SELECT RICSC_VIP__c FROM RICSC_Phone__c][0].RICSC_VIP__c, 'Phone is not VIP');
    }
    static testmethod void testAsync() {
      Test.startTest();
      TRG_TriggerDispatcher.skipTriggerMap.put('Account',true);
      Account ac2 = [SELECT Id FROM Account WHERE LastName = 'LRAccount'];
      ac2.put('RICSC_VIP__c',true);
      ac2.put('RICSC_HighJewelleryClient__c',true);
      ac2.put('RICSC_RecomputeFlagsPropagation__c', true);
      update ac2;
      Integer batchSize = 50;
      BatchFlagsPropagation batch = new BatchFlagsPropagation(false, 'SELECT Id, RICSC_RecomputeFlagsPropagation__c FROM Account WHERE isPersonAccount = true AND RICSC_RecomputeFlagsPropagation__c = true');
      ID batchprocessid = Database.executeBatch(batch,batchSize);
      Test.stopTest();
      System.assert([SELECT RICSC_VIP__c FROM Account WHERE LastName = 'GRAccount'][0].RICSC_VIP__c, 'Account is not VIP');
      System.assert([SELECT RICSC_VIP__c FROM RICSC_Email__c][0].RICSC_VIP__c, 'Email is not VIP');
      System.assert([SELECT RICSC_HighJewelleryClient__c FROM RICSC_Email__c][1].RICSC_HighJewelleryClient__c, 'Email is not high jewelery');
      System.assert([SELECT RICSC_VIP__c FROM RICSC_Activity__c][0].RICSC_VIP__c, 'Activity is not VIP');
      System.assert([SELECT RICSC_VIP__c FROM RICSC_SocialMediaID__c][0].RICSC_VIP__c, 'Social Media ID is not VIP');
      System.assert([SELECT RICSC_VIP__c FROM RICSC_Address__c][0].RICSC_VIP__c, 'Address is not VIP');
      System.assert([SELECT RICSC_HighJewelleryClient__c FROM RICSC_Wishlist__c][0].RICSC_HighJewelleryClient__c, 'Wishlist is not high jewelery');
      System.assert([SELECT RICSC_VIP__c FROM RICSC_Relation__c][0].RICSC_VIP__c, 'Relation is not VIP');
      System.assert([SELECT RICSC_VIP__c FROM RICSC_Phone__c][0].RICSC_VIP__c, 'Phone is not VIP');
    }

}