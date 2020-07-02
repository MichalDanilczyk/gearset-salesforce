@isTest
public with sharing class AccountTriggerHandler_Test {


  @testSetup
  static void setup() {

    UtilityTests.testSetup();
    List<RICSC_Localisation__c> locList = new List<RICSC_Localisation__c>();
    RICSC_Localisation__c localisationFrance = new RICSC_Localisation__c(Name = 'France',RICSC_LocalisationLevel__c = 'Country',RICSC_Maison__c = 'Cartier');
    RICSC_Localisation__c localisationMonaco = new RICSC_Localisation__c(Name = 'Monaco',RICSC_LocalisationLevel__c = 'Country',RICSC_Maison__c = 'Cartier');
    locList.add(localisationFrance);
    locList.add(localisationMonaco);

    insert locList;

    Contact newFrenchSalesAssociate = new Contact();
    newFrenchSalesAssociate.FirstName = 'Silvain';
    newFrenchSalesAssociate.LastName = 'Sola';
    newFrenchSalesAssociate.RICSC_CountryOfOrigin__c = 'France';
    insert newFrenchSalesAssociate;

    Contact newMonacoAssociate = new Contact();
    newMonacoAssociate.FirstName = 'Silva';
    newMonacoAssociate.LastName = 'Solla';
    newMonacoAssociate.RICSC_CountryOfOrigin__c = 'Monaco';
    insert newMonacoAssociate;

    List<Account> accountsToBeUpdated = new List<Account>();
    List<Account> accountsToInsert = new List<Account>();
    Account newVanCleefAndArpelsAccount = new Account();
    newVanCleefAndArpelsAccount.LastName = 'VanCleefAndArpelsAccount';
    newVanCleefAndArpelsAccount.RecordTypeId = RecordTypeHelper.getRTId('Account', 'RICSC_VanCleefAndArpels');
    newVanCleefAndArpelsAccount.RICSC_VIP__c = true;
    newVanCleefAndArpelsAccount.RICSC_ReferenceSA__c = newFrenchSalesAssociate.Id;
    newVanCleefAndArpelsAccount.RICSC_DataOrigin__c = 'NOT-WS';
    accountsToInsert.add(newVanCleefAndArpelsAccount);

    Account newVanCleefAndArpelsAccountW = new Account();
    newVanCleefAndArpelsAccountW.LastName = 'VanCleefAndArpelsAccountWholesaler';
    newVanCleefAndArpelsAccountW.RecordTypeId = RecordTypeHelper.getRTId('Account', 'RICSC_VanCleefAndArpels');
    newVanCleefAndArpelsAccountW.RICSC_DataOrigin__c = 'NOT-WS';
    accountsToInsert.add(newVanCleefAndArpelsAccountW);

    Account newVanCleefAndArpelsAccount3 = new Account();
    newVanCleefAndArpelsAccount3.LastName = 'VanCleefAndArpelsAccount3';
    newVanCleefAndArpelsAccount3.RICSC_ReferenceSA__c = newFrenchSalesAssociate.Id;
    newVanCleefAndArpelsAccount3.RecordTypeId = RecordTypeHelper.getRTId('Account', 'RICSC_VanCleefAndArpels');
    accountsToInsert.add(newVanCleefAndArpelsAccount3);

    Account goldenRecord = UtilityTests.getPersonAccount();
    goldenRecord.LastName = 'GoldenRecord';
    goldenRecord.RICSC_VIP__c = false;
    goldenRecord.RICSC_ReferenceSA__c = newFrenchSalesAssociate.Id;
    accountsToInsert.add(goldenRecord);

    Account newVanCleefAndArpelsAccount2 = new Account();
    newVanCleefAndArpelsAccount2.LastName = 'VanCleefAndArpelsAccount2';
    newVanCleefAndArpelsAccount2.RecordTypeId = RecordTypeHelper.getRTId('Account', 'RICSC_VanCleefAndArpels');
    newVanCleefAndArpelsAccount2.RICSC_VIP__c = false;
    newVanCleefAndArpelsAccount2.RICSC_ReferenceSA__c = newFrenchSalesAssociate.Id;
    accountsToInsert.add(newVanCleefAndArpelsAccount2);

    //Notes/Spot Notes Calculating
    Account notesAccountGRc = UtilityTests.getPersonAccount();
    notesAccountGRc.put('LastName','NotesAccountGR');
    accountsToInsert.add(notesAccountGRc);
    Account notesAccountLR1 = UtilityTests.getPersonAccount();
    notesAccountLR1.put('LastName','NotesAccountLR1');
    accountsToInsert.add(notesAccountLR1);
    Account notesAccountLR2 = UtilityTests.getPersonAccount();
    notesAccountLR2.put('LastName','NotesAccountLR2');
    accountsToInsert.add(notesAccountLR2);

    Account accountryprop = UtilityTests.getPersonAccount();
    accountryprop.LastName = 'AccountCountryofOriginPropagation';
    accountryprop.RICSC_CountryofOrigin__c = 'Italy';
    accountryprop.RICSC_SourceCRM__c = UtilityConstants.SOURCE_CRM_SAP;
    accountsToInsert.add(accountryprop);

    insert accountsToInsert;

    newVanCleefAndArpelsAccount3.RICSC_GoldenRecord__c = newVanCleefAndArpelsAccount.Id;
    accountsToBeUpdated.add(newVanCleefAndArpelsAccount3);
    newVanCleefAndArpelsAccount2.RICSC_GoldenRecord__c = goldenRecord.Id;
    accountsToBeUpdated.add(newVanCleefAndArpelsAccount2);

    notesAccountLR1.put('RICSC_GoldenRecord__c',notesAccountGRc.id);
    accountsToBeUpdated.add(notesAccountLR1);
    notesAccountLR2.put('RICSC_GoldenRecord__c',notesAccountGRc.id);
    accountsToBeUpdated.add(notesAccountLR2);

    update accountsToBeUpdated;

    List<RICSC_Address__c> addresses = new List<RICSC_Address__c>();
    List<RICSC_Activity__c> activities = new List<RICSC_Activity__c>();
    List<RICSC_Phone__c> phones = new List<RICSC_Phone__c>();
    List<RICSC_Relation__c> relations = new List<RICSC_Relation__c>();
    List<RICSC_Email__c> emails = new List<RICSC_Email__c>();
    List<RICSC_Wishlist__c> wishlists = new List<RICSC_Wishlist__c>();
    List<RICSC_SocialMediaID__c> socialmediaIDs = new List<RICSC_SocialMediaID__c>();
    List<RICSC_Transaction__c> transactions = new List<RICSC_Transaction__c>();

    RICSC_Email__c testEmail = new RICSC_Email__c(RICSC_Account__c = newVanCleefAndArpelsAccount2.Id,RICSC_Email__c = 'vipFlagPropagationChangeVip@test.com');
    emails.add(testEmail);

    RICSC_SocialMediaId__c testSocialMedia = new RICSC_SocialMediaId__c(RICSC_Account__c = newVanCleefAndArpelsAccount.Id);
    socialmediaIDs.add(testSocialMedia);

    RICSC_Phone__c testPhone = new RICSC_Phone__c(RICSC_Account__c = newVanCleefAndArpelsAccount.Id);
    phones.add(testPhone);

    RICSC_Address__c testAddress = new RICSC_Address__c(RICSC_Account__c = newVanCleefAndArpelsAccount.Id);
    addresses.add(testAddress);

    RICSC_Transaction__c testTransaction = new RICSC_Transaction__c(RICSC_Account__c = newVanCleefAndArpelsAccount2.Id,RICSC_AmountWithTax__c = 220000,RICSC_AmountWithTaxEUR__c = 220000,RICSC_CountryOfOrigin__c = 'Monaco');
    transactions.add(testTransaction);

    RICSC_Transaction__c testTransaction2 = new RICSC_Transaction__c(RICSC_Account__c = newVanCleefAndArpelsAccount3.Id,RICSC_AmountWithTax__c = 220000,RICSC_AmountWithTaxEUR__c = 220000,RICSC_CountryOfOrigin__c = 'France');
    transactions.add(testTransaction2);
    insert(transactions);

    //CountryOforiginPropagation
    RICSC_Address__c adr1 = UtilityTests.getAddress();
    adr1.RICSC_Account__c = accountryprop.Id;
    addresses.add(adr1);
    RICSC_Address__c adr2 = UtilityTests.getAddress();
    adr2.RICSC_Account__c = accountryprop.Id;
    addresses.add(adr2);
    insert addresses;
    RICSC_Activity__c act1 = UtilityTests.getActivity();
    act1.RICSC_Account__c = accountryprop.Id;
    act1.Name='Activity1';
    activities.add(act1);
    RICSC_Activity__c act2 = UtilityTests.getActivity();
    act2.RICSC_Account__c = accountryprop.Id;
    act2.Name='Activity2';
    activities.add(act2);
    insert activities;
    RICSC_Email__c em1 = UtilityTests.getEmail();
    em1.RICSC_Account__c = accountryprop.Id;
    emails.add(em1);
    RICSC_Email__c em2 = UtilityTests.getEmail();
    em2.RICSC_Account__c = accountryprop.Id;
    emails.add(em2);
    insert emails;
    RICSC_Phone__c ph1 = UtilityTests.getPhone();
    ph1.RICSC_Account__c = accountryprop.Id;
    phones.add(ph1);
    RICSC_Phone__c ph2 = UtilityTests.getPhone();
    ph2.RICSC_Account__c = accountryprop.Id;
    phones.add(ph2);
    insert phones;
    RICSC_SocialMediaID__c soc1 = UtilityTests.getSocialMediaID();
    soc1.RICSC_Account__c = accountryprop.Id;
    socialmediaIDs.add(soc1);
    RICSC_SocialMediaID__c soc2 = UtilityTests.getSocialMediaID();
    soc2.RICSC_Account__c = accountryprop.Id;
    socialmediaIDs.add(soc2);
    insert socialmediaIDs;
    RICSC_Relation__c rel1 = UtilityTests.getRelation();
    rel1.RICSC_Account__c = accountryprop.Id;
    relations.add(rel1);
    RICSC_Relation__c rel2 = UtilityTests.getRelation();
    rel2.RICSC_Account__c = accountryprop.Id;
    relations.add(rel2);
    insert relations;
    RICSC_Wishlist__c wis1 = UtilityTests.getWishlist();
    wis1.RICSC_Account__c = accountryprop.Id;
    wishlists.add(wis1);
    RICSC_Wishlist__c wis2 = UtilityTests.getWishlist();
    wis2.RICSC_Account__c = accountryprop.Id;
    wishlists.add(wis2);
    insert wishlists;
  }



    static testmethod void changeVIPtoFalse() {


        //Changing from vip true to false all related sharing rulles has to be deleted
        Test.startTest();
        Account updateVanCleefAndArpelsAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c FROM Account WHERE LastName LIKE 'VanCleefAndArpelsAccount2'];
        updateVanCleefAndArpelsAccount.RICSC_VIP__c = false;
        update updateVanCleefAndArpelsAccount;
        Test.stopTest();

        List<RICSC_Email__share> gp = [SELECT UserOrGroupId,rowcause FROM RICSC_Email__share WHERE ParentId IN (SELECT Id FROM RICSC_Email__c WHERE Name = 'vipFlagPropagationChangeVip@test.com')];

        System.assertEquals(gp.isEmpty(),true);
    }

    static testmethod void changeVIPtoTrue() {

        List<RICSC_Transaction__share> emailSharingRullesBeforeVipChangeToFalse = [SELECT Id FROM RICSC_Transaction__share];

        //Changing from vip true to false all related sharing rulles has to be deleted
        Test.startTest();
        Account updateVanCleefAndArpelsAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c FROM Account WHERE LastName = 'VanCleefAndArpelsAccount2'];
        updateVanCleefAndArpelsAccount.RICSC_VIP__c = true;
        update updateVanCleefAndArpelsAccount;
        Test.stopTest();
        //because there is not any sharing rule created when the record is created the list is empty
        //after change to VIP sharing rules are created for all related object email , socialmedia , phone and transaction
        //also because one transaction got defferent country of origin from the contact , its going to be created a seperate sharing rule for that country
        //so we got 2 from the transaction inserted and 1 more because the country differs from the contacts in total 3 sharing rules

        List<Group> gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMFrance' AND Id IN (SELECT UserOrGroupId FROM RICSC_Email__share)];
        System.assertEquals(gp.isEmpty(),false);

    }

    static testmethod void changeReferenceSAVIPTrue() {

        // on the objects email , phone and socialmedia there is already created a sharing rule from the UI , so it has 1 imported
        Test.startTest();
        Contact monacoSalesAssociate = [SELECT Id FROM Contact WHERE RICSC_CountryOfOrigin__c = 'Monaco' LIMIT 1];
        Account updateVanCleefAndArpelsAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c FROM Account WHERE LastName = 'VanCleefAndArpelsAccount' LIMIT 1];
        updateVanCleefAndArpelsAccount.RICSC_ReferenceSA__c = monacoSalesAssociate.Id;
        update updateVanCleefAndArpelsAccount;
        Test.stopTest();
        List<Group> gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMMonaco' AND Id IN (SELECT UserOrGroupId FROM RICSC_Address__share)];
        System.assertEquals(gp.isEmpty(),false);
    }

    static testmethod void changeFieldOtherThanVIPOrReferenceSA() {

        // In case trigger is executed and non of the fields that is required to create sharing rules is changed
        // trigger exit so it avoid doing unneccesary queries
        Test.startTest();
        Account updateVanCleefAndArpelsAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c FROM Account WHERE LastName = 'VanCleefAndArpelsAccount2'];
        updateVanCleefAndArpelsAccount.RICSC_VIP__c = true;
        update updateVanCleefAndArpelsAccount;

        List<Group> gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMFrance' AND Id IN (SELECT UserOrGroupId FROM RICSC_Email__share)];
        Integer gpSize = gp.size();
        System.assertEquals(gp.isEmpty(),false);

        updateVanCleefAndArpelsAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c FROM Account WHERE LastName = 'VanCleefAndArpelsAccount2'];
        updateVanCleefAndArpelsAccount.RICSC_Nationality__c = 'Albanian';
        update updateVanCleefAndArpelsAccount;
        gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMFrance' AND Id IN (SELECT UserOrGroupId FROM RICSC_Email__share)];
        System.assertEquals(gp.size(), gpSize, 'Change on other field affected account sharing');
        Test.stopTest();
    }

    static testmethod void vipFlagPropagationChangeVip(){

      Test.startTest();
        Account myowner = [SELECT id FROM Account WHERE LastName = 'AccountCountryofOriginPropagation'];
        myowner.RICSC_VIP__c = true;
        update myowner;
      Test.stopTest();

      System.assertEquals([SELECT RICSC_VIP__c FROM RICSC_Email__c WHERE RICSC_Account__c = :myowner.Id][0].RICSC_VIP__c,true);
    }


    //Notes, Spot Notes, Ecard, VIP-change ClientFlag, CollectionOfInterests, ProductOfInterests Calculating Fields Test on update
    static testmethod void changeNotesSpotNotesEcardFlagClient(){

        Test.startTest();
        List<Account> acclist = [SELECT RICSC_GoldenRecord__c FROM Account WHERE  LastName = 'NotesAccountLR1' OR LastName = 'NotesAccountLR2' ORDER BY Name ASC];
        acclist[0].put('RICSC_Notes__C','Some info about the customer');
        acclist[0].put('RICSC_SpotNotes__c','Contact after 12:00');
        acclist[0].put('RICSC_ECard__c',true);
        acclist[0].put('RICSC_ProductOfInterests__c','Jewellery Envol');
        acclist[0].put('RICSC_CollectionOfInterests__c','Bridal jewellery');
        acclist[0].put('RICSC_ClientFlag__c','VIP');
        acclist[1].put('RICSC_Notes__C','Extra info about the customer');
        acclist[1].put('RICSC_SpotNotes__c','VVP');
        acclist[1].put('RICSC_CollectionOfInterests__c','Estate Pieces');
        update acclist;
        Test.stopTest();
        Account acc = [SELECT id,RICSC_Notes__c,RICSC_SpotNotes__c,RICSC_ECard__c,RICSC_VIP__c,RICSC_CollectionOfInterests__c,RICSC_ProductOfInterests__c FROM Account WHERE id =: acclist[0].RICSC_GoldenRecord__c];
        System.assertEquals(acclist[0].get('RICSC_Notes__c').toString()+' '+acclist[1].get('RICSC_Notes__c').toString(),acc.RICSC_Notes__c);
        System.assertEquals(acclist[0].get('RICSC_SpotNotes__c').toString()+' '+acclist[1].get('RICSC_SpotNotes__c').toString(),acc.RICSC_SpotNotes__c);
        System.assertEquals(acclist[0].get('RICSC_CollectionOfInterests__c').toString()+';'+acclist[1].get('RICSC_CollectionOfInterests__c').toString(),acc.RICSC_CollectionOfInterests__c);
        System.assertEquals(acclist[0].get('RICSC_ProductOfInterests__c').toString(),acc.RICSC_ProductOfInterests__c);
        System.assert(acc.RICSC_ECard__c);

    }


    static testmethod void localisationPropagationTriggerTest(){

      Test.startTest();
        Account newBoutique = UtilityTests.getBoutique();
        newBoutique.RICSC_CountryOfOrigin__c = 'France';
        newBoutique.Name = 'France Boutique';
        newBoutique.RICSC_Maison__c = 'Cartier';
        insert newBoutique;
        Account boutiqueAfterInsert = [SELECT RICSC_Localisation__c FROM Account WHERE Name = 'France Boutique'];
        boutiqueAfterInsert.RICSC_CountryOfOrigin__c = 'Monaco';
        update boutiqueAfterInsert;
        Account boutiqueAfterUpdate = [SELECT RICSC_Localisation__c FROM Account WHERE Name = 'France Boutique'];
      Test.stopTest();


      System.assertEquals(boutiqueAfterInsert.RICSC_Localisation__c,Utility.getLocalisationId('Cartier','France'), 'Wrong localisation');
      System.assertEquals(boutiqueAfterUpdate.RICSC_Localisation__c,Utility.getLocalisationId('Cartier','Monaco'), 'Wrong localisation');
    }

    static testmethod void manualLinkUnlinkTest(){
      Test.startTest();
      Account childToLink = new Account(LastName='ChildToLink');
      insert childToLink;

      Account golden = [SELECT Id, RICSC_IsGoldenRecord__c, RICSC_HasLocalRecords__c FROM Account WHERE LastName LIKE 'VanCleefAndArpelsAccount%' AND RICSC_HasLocalRecords__c = true LIMIT 1];
      childToLink.RICSC_GoldenRecord__c = golden.Id;
      update childToLink;
      Map<Id, Account> allAccounts = new Map<Id,Account>([SELECT Id, RICSC_IsGoldenRecord__c, RICSC_HasLocalRecords__c, RICSC_MasterRecord__c FROM Account WHERE RICSC_GoldenRecord__c = :golden.Id OR Id = :golden.Id]);
      golden = allAccounts.get(golden.Id);
      childToLink = allAccounts.get(childToLink.Id);
      System.assert(!childToLink.RICSC_IsGoldenRecord__c, true);
      System.assert(!childToLink.RICSC_HasLocalRecords__c, true);
      System.assert(golden.RICSC_IsGoldenRecord__c, true);
      System.assert(golden.RICSC_HasLocalRecords__c, true);

      childToLink.RICSC_GoldenRecord__c = null;
      update childToLink;
      golden = [SELECT Id, RICSC_IsGoldenRecord__c, RICSC_HasLocalRecords__c FROM Account WHERE Id = :golden.Id LIMIT 1];
      childToLink = [SELECT Id, RICSC_IsGoldenRecord__c, RICSC_HasLocalRecords__c, RICSC_GoldenRecord__c FROM Account WHERE Id = :childToLink.Id LIMIT 1];
      System.assert(childToLink.RICSC_IsGoldenRecord__c, 'Unlinked account is not golden record');
      System.assert(!childToLink.RICSC_HasLocalRecords__c, 'Unlinked account has local records');
      System.assert(childToLink.RICSC_GoldenRecord__c == null, 'Unlinked account has still reference to golden');
      Test.stopTest();
    }

    static testmethod void highJewelleryFlagPropagationTest(){
      Test.startTest();
      Account updateVanCleefAndArpelsAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c FROM Account WHERE LastName LIKE 'VanCleefAndArpelsAccount%' AND RICSC_HasLocalRecords__c = true LIMIT 1];
      updateVanCleefAndArpelsAccount.RICSC_HighJewelleryClient__c = true;
      update updateVanCleefAndArpelsAccount;
      Test.stopTest();

      Account acc = [SELECT Id, RICSC_HighJewelleryClient__c, (SELECT RICSC_HighJewelleryClient__c FROM Cases), (SELECT RICSC_HighJewelleryClient__c FROM RICSC_ActivitiesAccount__r), (SELECT RICSC_HighJewelleryClient__c FROM RICSC_AddressesAccount__r), (SELECT RICSC_HighJewelleryClient__c FROM RICSC_EmailsAccount__r ), (SELECT RICSC_HighJewelleryClient__c FROM RICSC_PhonesAccount__r), (SELECT RICSC_HighJewelleryClient__c FROM Assets), (SELECT RICSC_HighJewelleryClient__c FROM RICSC_RelationsAccount__r), (SELECT RICSC_HighJewelleryClient__c FROM RICSC_SocialMediaIDsAccount__r), (SELECT RICSC_HighJewelleryClient__c FROM RICSC_TransactionsAccount__r), (SELECT RICSC_HighJewelleryClient__c FROM RICSC_WishlistsAccount__r) FROM Account WHERE Id = :updateVanCleefAndArpelsAccount.Id];
      List<SObject> objects = new List<SObject>();
      objects.addAll(acc.Cases);
      objects.addAll(acc.RICSC_ActivitiesAccount__r);
      objects.addAll(acc.RICSC_AddressesAccount__r);
      objects.addAll(acc.RICSC_EmailsAccount__r);
      objects.addAll(acc.RICSC_PhonesAccount__r);
      objects.addAll(acc.Assets);
      objects.addAll(acc.RICSC_RelationsAccount__r);
      objects.addAll(acc.RICSC_SocialMediaIDsAccount__r);
      objects.addAll(acc.RICSC_TransactionsAccount__r);
      objects.addAll(acc.RICSC_WishlistsAccount__r);

      List<SObject> objWithFalseFlag = new List<SObject>();
      for(SObject obj : objects){
        if(!(Boolean)obj.get('RICSC_HighJewelleryClient__c')){
          objWithFalseFlag.add(obj);
        }
      }
      System.assert(objWithFalseFlag.isEmpty(), 'Objects with RICSC_HighJewelleryClient__c field set to false');
    }

    static testmethod void consentPropagation(){
      Test.startTest();
      Account goldenAccount = [SELECT Id, RICSC_GoldenRecord__c, RICSC_ConsentTimestamp__c, RICSC_CanBeContacted__c, RICSC_PostalContact__c, RICSC_ElectronicContact__c, RICSC_VoiceContact__c
                                                FROM Account
                                                WHERE LastName LIKE 'VanCleefAndArpelsAccount' AND RICSC_HasLocalRecords__c = true LIMIT 1];
      goldenAccount.RICSC_CanBeContacted__c = true;
      goldenAccount.RICSC_ConsentTimestamp__c = Datetime.now();
      update goldenAccount;

      List<Account> localRecords = [SELECT Id, RICSC_GoldenRecord__c, RICSC_ConsentTimestamp__c, RICSC_CanBeContacted__c, RICSC_PostalContact__c, RICSC_ElectronicContact__c, RICSC_VoiceContact__c
                                    FROM Account
                                    WHERE RICSC_GoldenRecord__c = :goldenAccount.Id];
      List<Account> accountsWithFalseFlag = new List<Account>();
      for(Account acc : localRecords){
        if(!acc.RICSC_CanBeContacted__c){
          accountsWithFalseFlag.add(acc);
        }
      }
      System.assert(accountsWithFalseFlag.isEmpty(), true);

      goldenAccount.RICSC_PostalContact__c = true;
      goldenAccount.RICSC_ConsentTimestamp__c = Datetime.now().addMonths(-1);
      update goldenAccount;

      localRecords = [SELECT Id, RICSC_GoldenRecord__c, RICSC_ConsentTimestamp__c, RICSC_CanBeContacted__c, RICSC_PostalContact__c, RICSC_ElectronicContact__c, RICSC_VoiceContact__c
                      FROM Account
                      WHERE RICSC_GoldenRecord__c = :goldenAccount.Id];
      accountsWithFalseFlag = new List<Account>();
      for(Account acc : localRecords){
        if(!acc.RICSC_PostalContact__c){
          accountsWithFalseFlag.add(acc);
        }
      }
      System.assert(accountsWithFalseFlag.size()>0, true);

      Account localRecord = localRecords.get(0);
      localRecord.RICSC_ElectronicContact__c = true;
      localRecord.RICSC_ConsentTimestamp__c = Datetime.now().addMonths(1);
      update localRecord;

      List<Account> relatedRecords = [SELECT Id, RICSC_GoldenRecord__c, RICSC_ConsentTimestamp__c, RICSC_CanBeContacted__c, RICSC_PostalContact__c, RICSC_ElectronicContact__c, RICSC_VoiceContact__c
                      FROM Account
                      WHERE RICSC_GoldenRecord__c = :localRecord.RICSC_GoldenRecord__c OR Id = :localRecord.RICSC_GoldenRecord__c];
      System.debug('==> relatedRecords: ' + relatedRecords);
      accountsWithFalseFlag = new List<Account>();
      for(Account acc : relatedRecords){
        if(!acc.RICSC_ElectronicContact__c){
          accountsWithFalseFlag.add(acc);
        }
      }
      System.debug('==> accountsWithFalseFlag: ' + accountsWithFalseFlag);
      System.assert(accountsWithFalseFlag.isEmpty(), true);

      localRecord.RICSC_VoiceContact__c = true;
      localRecord.RICSC_ConsentTimestamp__c = Datetime.now().addMonths(-1);
      update localRecord;

      relatedRecords = [SELECT Id, RICSC_GoldenRecord__c, RICSC_ConsentTimestamp__c, RICSC_CanBeContacted__c, RICSC_PostalContact__c, RICSC_ElectronicContact__c, RICSC_VoiceContact__c
                      FROM Account
                      WHERE RICSC_GoldenRecord__c = :localRecord.RICSC_GoldenRecord__c OR Id = :localRecord.RICSC_GoldenRecord__c];
      accountsWithFalseFlag = new List<Account>();
      for(Account acc : relatedRecords){
        if(!acc.RICSC_VoiceContact__c){
          accountsWithFalseFlag.add(acc);
        }
      }
      System.assert(accountsWithFalseFlag.size()>0, true);

      Test.stopTest();
    }


    static testmethod void classCodeCalculationProspect(){
      Test.startTest();
      Account testAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c FROM Account WHERE LastName = 'VanCleefAndArpelsAccount' LIMIT 1];
      testAccount.RICSC_DataOrigin__c = 'WS';
      update testAccount;
      testAccount = [SELECT Id, RICSC_ClassCode__c FROM Account WHERE Id = :testAccount.Id];
      System.assertEquals(UtilityConstants.CLASS_CODE_PROSP, testAccount.RICSC_ClassCode__c, 'Wrong class code');
      Test.stopTest();
    }


    static testmethod void classCodeCalculationWholesaler(){

      Test.startTest();
        Account testAccount = [SELECT Id FROM Account WHERE LastName = 'VanCleefAndArpelsAccountWholeSaler'];
        Asset testAsset = new Asset(Name='testAsset',RICSC_GoldenRecord__c = testAccount.id);
        insert testAsset;

        testAccount = [SELECT Id, RICSC_ClassCode__c FROM Account WHERE LastName = 'VanCleefAndArpelsAccountWholeSaler'];
        System.assertEquals(UtilityConstants.CLASS_CODE_WHLSL, testAccount.RICSC_ClassCode__c);

      Test.stopTest();

    }


    static testmethod void classCodeCalculationCustomerServiceClient(){
      Test.startTest();
      Account localAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c FROM Account WHERE LastName LIKE 'VanCleefAndArpelsAccount%' AND RICSC_GoldenRecord__c != null LIMIT 1];
      RICSC_Transaction__c testTransaction = new RICSC_Transaction__c(RICSC_Account__c = localAccount.Id,RICSC_AmountWithTax__c = 220000,RICSC_TransactionCategory__c = 'Repair',RICSC_CurrencyKey__c = 'EUR');
      insert testTransaction;
      Account goldenAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c FROM Account WHERE LastName LIKE 'VanCleefAndArpelsAccount%' AND RICSC_HasLocalRecords__c = true LIMIT 1];
      goldenAccount.RICSC_DataOrigin__c = 'NOT-WS';
      update goldenAccount;
      goldenAccount = [SELECT Id, RICSC_ClassCode__c FROM Account WHERE Id = :goldenAccount.Id];
      System.assertEquals(UtilityConstants.CLASS_CODE_SCLNT, goldenAccount.RICSC_ClassCode__c, 'Wrong class code');
      Test.stopTest();
    }

    static testmethod void classCodeCalculationBoutique(){
      Test.startTest();
      Account localAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c FROM Account WHERE LastName LIKE 'VanCleefAndArpelsAccount%' AND RICSC_GoldenRecord__c != null LIMIT 1];
      RICSC_Transaction__c testTransaction1 = new RICSC_Transaction__c(RICSC_Account__c = localAccount.Id,RICSC_AmountWithTax__c = 220000,RICSC_CurrencyKey__c = 'EUR',RICSC_Channel__c = 'Boutique');
      insert testTransaction1;
      Account goldenAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c FROM Account WHERE LastName LIKE 'VanCleefAndArpelsAccount%' AND RICSC_HasLocalRecords__c = true LIMIT 1];
      goldenAccount.RICSC_DataOrigin__c = 'NOT-WS';
      update goldenAccount;
      goldenAccount = [SELECT Id, RICSC_ClassCode__c FROM Account WHERE Id = :goldenAccount.Id];
      System.assertEquals(UtilityConstants.CLASS_CODE_PROSP, goldenAccount.RICSC_ClassCode__c, 'Wrong class code');
      Test.stopTest();
    }

    static testmethod void classCodeCalculationTransactionSalesCCChannel(){
      Test.startTest();
      Account testAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c, RICSC_GoldenRecord__c FROM Account WHERE LastName LIKE 'VanCleefAndArpelsAccount%' AND RICSC_GoldenRecord__c != null LIMIT 1];
      RICSC_Transaction__c testTransaction1 = new RICSC_Transaction__c(RICSC_Account__c = testAccount.Id,RICSC_TransactionCategory__c = 'Sale',RICSC_AmountWithTax__c = 220000,RICSC_CurrencyKey__c = 'EUR',RICSC_Channel__c = 'CC');
      insert testTransaction1;
      testAccount = [SELECT Id, RICSC_ClassCode__c FROM Account WHERE Id = :testAccount.RICSC_GoldenRecord__c LIMIT 1];
      testAccount.RICSC_DataOrigin__c = 'NOT-WS';
      update testAccount;
      testAccount = [SELECT Id, RICSC_ClassCode__c FROM Account WHERE LastName LIKE 'VanCleefAndArpelsAccount%' AND RICSC_HasLocalRecords__c = true LIMIT 1];
      System.assertEquals(UtilityConstants.CLASS_CODE_CCLNT, testAccount.RICSC_ClassCode__c, 'Wrong class code for account');
      Test.stopTest();
    }

    static testmethod void classCodeCalculationTransactionSalesBoutiqueChannel(){
      Test.startTest();
      Account localAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c, RICSC_GoldenRecord__c FROM Account WHERE LastName LIKE 'VanCleefAndArpelsAccount%' AND RICSC_GoldenRecord__c != null LIMIT 1];
      RICSC_Transaction__c testTransaction1 = new RICSC_Transaction__c(RICSC_Account__c = localAccount.Id,RICSC_TransactionCategory__c = 'Sale',RICSC_AmountWithTax__c = 220000,RICSC_CurrencyKey__c = 'EUR',RICSC_Channel__c = 'Boutique');
      insert testTransaction1;
      Account goldenAccount = [SELECT Id FROM Account WHERE Id = :localAccount.RICSC_GoldenRecord__c LIMIT 1];
      goldenAccount.RICSC_DataOrigin__c = 'NOT-WS';
      update goldenAccount;
      goldenAccount = [SELECT Id, RICSC_ClassCode__c,RICSC_TotalNumberOfRepairs__c FROM Account WHERE Id = :goldenAccount.Id];
      System.assertEquals(UtilityConstants.CLASS_CODE_RCLNT, goldenAccount.RICSC_ClassCode__c, 'Wrong class code');
      Test.stopTest();
    }

    static testmethod void classCodeCalculationTransactionSalesWEBChannel(){
      Test.startTest();
      Account localAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c, RICSC_GoldenRecord__c FROM Account WHERE LastName LIKE 'VanCleefAndArpelsAccount%' AND RICSC_GoldenRecord__c != null LIMIT 1];
      RICSC_Transaction__c testTransaction1 = new RICSC_Transaction__c(RICSC_Account__c = localAccount.Id,RICSC_TransactionCategory__c = 'Sale',RICSC_AmountWithTax__c = 220000,RICSC_CurrencyKey__c = 'EUR',RICSC_Channel__c = 'WEB');
      insert testTransaction1;
      Account goldenAccount = [SELECT Id FROM Account WHERE Id = :localAccount.RICSC_GoldenRecord__c LIMIT 1];
      goldenAccount.RICSC_DataOrigin__c = 'NOT-WS';
      update goldenAccount;
      goldenAccount = [SELECT Id, RICSC_ClassCode__c,RICSC_TotalNumberOfRepairs__c FROM Account WHERE Id = :goldenAccount.Id];
      System.assertEquals(UtilityConstants.CLASS_CODE_WCLNT, goldenAccount.RICSC_ClassCode__c, 'Wrong class code');
      Test.stopTest();
    }

    static testmethod void classCodeCalculationTransactionSalesWEBCCChannel(){
      Test.startTest();
      Account localAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c, RICSC_GoldenRecord__c FROM Account WHERE LastName LIKE 'VanCleefAndArpelsAccount%' AND RICSC_GoldenRecord__c != null LIMIT 1];
      List<RICSC_Transaction__c> transactionsList = new List<RICSC_Transaction__c>();
      RICSC_Transaction__c testTransaction1 = new RICSC_Transaction__c(RICSC_Account__c = localAccount.Id,RICSC_TransactionCategory__c = 'Sale',RICSC_AmountWithTax__c = 220000,RICSC_CurrencyKey__c = 'EUR',RICSC_Channel__c = 'WEB');
      transactionsList.add(testTransaction1);
      RICSC_Transaction__c testTransaction2 = new RICSC_Transaction__c(RICSC_Account__c = localAccount.Id,RICSC_TransactionCategory__c = 'Sale',RICSC_AmountWithTax__c = 220000,RICSC_CurrencyKey__c = 'EUR',RICSC_Channel__c = 'CC');
      transactionsList.add(testTransaction2);
      insert transactionsList;
      Account goldenAccount = [SELECT Id FROM Account WHERE Id = :localAccount.RICSC_GoldenRecord__c LIMIT 1];
      goldenAccount.RICSC_DataOrigin__c = 'NOT-WS';
      update goldenAccount;
      goldenAccount = [SELECT Id, RICSC_ClassCode__c,RICSC_TotalNumberOfRepairs__c FROM Account WHERE Id = :goldenAccount.Id];
      System.assertEquals(UtilityConstants.CLASS_CODE_ECOM, goldenAccount.RICSC_ClassCode__c, 'Wrong class code');
      Test.stopTest();
    }

    static testmethod void classCodeCalculationTransactionSalesBoutiqueCCChannel(){
      Test.startTest();
      Account localAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c, RICSC_GoldenRecord__c FROM Account WHERE LastName LIKE 'VanCleefAndArpelsAccount%' AND RICSC_GoldenRecord__c != null LIMIT 1];
      List<RICSC_Transaction__c> transactionsList = new List<RICSC_Transaction__c>();
      RICSC_Transaction__c testTransaction1 = new RICSC_Transaction__c(RICSC_Account__c = localAccount.Id,RICSC_TransactionCategory__c = 'Sale',RICSC_AmountWithTax__c = 220000,RICSC_CurrencyKey__c = 'EUR',RICSC_Channel__c = 'Boutique');
      transactionsList.add(testTransaction1);
      RICSC_Transaction__c testTransaction2 = new RICSC_Transaction__c(RICSC_Account__c = localAccount.Id,RICSC_TransactionCategory__c = 'Sale',RICSC_AmountWithTax__c = 220000,RICSC_CurrencyKey__c = 'EUR',RICSC_Channel__c = 'CC');
      transactionsList.add(testTransaction2);
      insert transactionsList;
      Account goldenAccount = [SELECT Id FROM Account WHERE Id = :localAccount.RICSC_GoldenRecord__c LIMIT 1];
      goldenAccount.RICSC_DataOrigin__c = 'NOT-WS';
      update goldenAccount;
      goldenAccount = [SELECT Id, RICSC_ClassCode__c,RICSC_TotalNumberOfRepairs__c FROM Account WHERE Id = :goldenAccount.Id];
      System.assertEquals(UtilityConstants.CLASS_CODE_MCLNT, goldenAccount.RICSC_ClassCode__c, 'Wrong class code');
      Test.stopTest();
    }

    static testmethod void classCodeCalculationTransactionSalesBoutiqueWholesalerChannel(){
      Test.startTest();
      Account localAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c, RICSC_GoldenRecord__c FROM Account WHERE LastName LIKE 'VanCleefAndArpelsAccount%' AND RICSC_GoldenRecord__c != null LIMIT 1];
      List<RICSC_Transaction__c> transactionsList = new List<RICSC_Transaction__c>();
      RICSC_Transaction__c testTransaction1 = new RICSC_Transaction__c(RICSC_Account__c = localAccount.Id,RICSC_TransactionCategory__c = 'Sale',RICSC_AmountWithTax__c = 220000,RICSC_CurrencyKey__c = 'EUR',RICSC_Channel__c = 'Boutique');
      transactionsList.add(testTransaction1);
      RICSC_Transaction__c testTransaction2 = new RICSC_Transaction__c(RICSC_Account__c = localAccount.Id,RICSC_TransactionCategory__c = 'Sale',RICSC_AmountWithTax__c = 220000,RICSC_CurrencyKey__c = 'EUR',RICSC_Channel__c = 'Wholesaler');
      transactionsList.add(testTransaction2);
      insert transactionsList;
      Account goldenAccount = [SELECT Id FROM Account WHERE Id = :localAccount.RICSC_GoldenRecord__c LIMIT 1];
      goldenAccount.RICSC_DataOrigin__c = 'NOT-WS';
      update goldenAccount;
      goldenAccount = [SELECT Id, RICSC_ClassCode__c,RICSC_TotalNumberOfRepairs__c FROM Account WHERE Id = :goldenAccount.Id];
      System.assertEquals(UtilityConstants.CLASS_CODE_MCLNT, goldenAccount.RICSC_ClassCode__c, 'Wrong class code');
      Test.stopTest();
    }

    static testmethod void classCodeCalculationTransactionSalesWEBBoutiqueChannel(){
      Test.startTest();
      Account localAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c, RICSC_GoldenRecord__c FROM Account WHERE LastName LIKE 'VanCleefAndArpelsAccount%' AND RICSC_GoldenRecord__c != null LIMIT 1];
      List<RICSC_Transaction__c> transactionsList = new List<RICSC_Transaction__c>();
      RICSC_Transaction__c testTransaction1 = new RICSC_Transaction__c(RICSC_Account__c = localAccount.Id,RICSC_TransactionCategory__c = 'Sale',RICSC_AmountWithTax__c = 220000,RICSC_CurrencyKey__c = 'EUR',RICSC_Channel__c = 'WEB');
      transactionsList.add(testTransaction1);
      RICSC_Transaction__c testTransaction2 = new RICSC_Transaction__c(RICSC_Account__c = localAccount.Id,RICSC_TransactionCategory__c = 'Sale',RICSC_AmountWithTax__c = 220000,RICSC_CurrencyKey__c = 'EUR',RICSC_Channel__c = 'Boutique');
      transactionsList.add(testTransaction2);
      insert transactionsList;
      Account goldenAccount = [SELECT Id FROM Account WHERE Id = :localAccount.RICSC_GoldenRecord__c LIMIT 1];
      goldenAccount.RICSC_DataOrigin__c = 'NOT-WS';
      update goldenAccount;
      goldenAccount = [SELECT Id, RICSC_ClassCode__c,RICSC_TotalNumberOfRepairs__c FROM Account WHERE Id = :goldenAccount.Id];
      System.assertEquals(UtilityConstants.CLASS_CODE_MCLNT, goldenAccount.RICSC_ClassCode__c, 'Wrong class code');
      Test.stopTest();
    }

    static testmethod void classCodeCalculationTransactionSalesWEBBoutiqueCCWholesalerChannel(){
      Test.startTest();
      Account localAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c, RICSC_GoldenRecord__c FROM Account WHERE LastName LIKE 'VanCleefAndArpelsAccount%' AND RICSC_GoldenRecord__c != null LIMIT 1];
      List<RICSC_Transaction__c> transactionsList = new List<RICSC_Transaction__c>();
      RICSC_Transaction__c testTransaction1 = new RICSC_Transaction__c(RICSC_Account__c = localAccount.Id,RICSC_TransactionCategory__c = 'Sale',RICSC_AmountWithTax__c = 220000,RICSC_CurrencyKey__c = 'EUR',RICSC_Channel__c = 'WEB');
      transactionsList.add(testTransaction1);
      RICSC_Transaction__c testTransaction2 = new RICSC_Transaction__c(RICSC_Account__c = localAccount.Id,RICSC_TransactionCategory__c = 'Sale',RICSC_AmountWithTax__c = 220000,RICSC_CurrencyKey__c = 'EUR',RICSC_Channel__c = 'CC');
      transactionsList.add(testTransaction2);
      RICSC_Transaction__c testTransaction3 = new RICSC_Transaction__c(RICSC_Account__c = localAccount.Id,RICSC_TransactionCategory__c = 'Sale',RICSC_AmountWithTax__c = 220000,RICSC_CurrencyKey__c = 'EUR',RICSC_Channel__c = 'Boutique');
      transactionsList.add(testTransaction3);
      RICSC_Transaction__c testTransaction4 = new RICSC_Transaction__c(RICSC_Account__c = localAccount.Id,RICSC_TransactionCategory__c = 'Sale',RICSC_AmountWithTax__c = 220000,RICSC_CurrencyKey__c = 'EUR',RICSC_Channel__c = 'Wholesaler');
      transactionsList.add(testTransaction4);
      insert transactionsList;
      Account goldenAccount = [SELECT Id FROM Account WHERE Id = :localAccount.RICSC_GoldenRecord__c LIMIT 1];
      goldenAccount.RICSC_DataOrigin__c = 'NOT-WS';
      update goldenAccount;
      goldenAccount = [SELECT Id, RICSC_ClassCode__c,RICSC_TotalNumberOfRepairs__c FROM Account WHERE Id = :goldenAccount.Id];
      System.assertEquals(UtilityConstants.CLASS_CODE_MCLNT, goldenAccount.RICSC_ClassCode__c, 'Wrong class code');
      Test.stopTest();
    }

    static testmethod void classCodeCalculationTransactionSalesCharityChannel(){
      Test.startTest();
      Account localAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c, RICSC_GoldenRecord__c FROM Account WHERE LastName LIKE 'VanCleefAndArpelsAccount%' AND RICSC_GoldenRecord__c != null LIMIT 1];
      RICSC_Transaction__c testTransaction1 = new RICSC_Transaction__c(RICSC_Account__c = localAccount.Id,RICSC_TransactionCategory__c = 'Sale',RICSC_AmountWithTax__c = 220000,RICSC_CurrencyKey__c = 'EUR',RICSC_Channel__c = 'Charity');
      insert testTransaction1;
      Account goldenAccount = [SELECT Id FROM Account WHERE Id = :localAccount.RICSC_GoldenRecord__c LIMIT 1];
      goldenAccount.RICSC_DataOrigin__c = 'NOT-WS';
      update goldenAccount;
      goldenAccount = [SELECT Id, RICSC_ClassCode__c,RICSC_TotalNumberOfRepairs__c FROM Account WHERE Id = :goldenAccount.Id];
      System.assertEquals(UtilityConstants.CLASS_CODE_CHARY, goldenAccount.RICSC_ClassCode__c, 'Wrong class code');
      Test.stopTest();
    }

    static testmethod void classCodeCalculationTransactionNullChannel(){
      Test.startTest();
      Account localAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c, RICSC_GoldenRecord__c FROM Account WHERE LastName LIKE 'VanCleefAndArpelsAccount%' AND RICSC_GoldenRecord__c != null LIMIT 1];
      RICSC_Transaction__c testTransaction1 = new RICSC_Transaction__c(RICSC_Account__c = localAccount.Id,RICSC_TransactionCategory__c = 'Sale',RICSC_AmountWithTax__c = 220000,RICSC_CurrencyKey__c = 'EUR');
      insert testTransaction1;
      Account goldenAccount = [SELECT Id FROM Account WHERE Id = :localAccount.RICSC_GoldenRecord__c LIMIT 1];
      goldenAccount.RICSC_DataOrigin__c = 'NOT-WS';
      update goldenAccount;
      goldenAccount = [SELECT Id, RICSC_ClassCode__c,RICSC_TotalNumberOfRepairs__c FROM Account WHERE Id = :goldenAccount.Id];
      System.assertEquals(null, goldenAccount.RICSC_ClassCode__c, 'Wrong class code');
      Test.stopTest();
    }

    static testmethod void classCodeCalculationTransactionNoneOfTheAbove(){
      Test.startTest();
      Account localAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c, RICSC_GoldenRecord__c FROM Account WHERE LastName LIKE 'VanCleefAndArpelsAccount%' AND RICSC_GoldenRecord__c != null LIMIT 1];
      List<RICSC_Transaction__c> transactionsList = new List<RICSC_Transaction__c>();
      RICSC_Transaction__c testTransaction1 = new RICSC_Transaction__c(RICSC_Account__c = localAccount.Id,RICSC_TransactionCategory__c = 'Sale',RICSC_AmountWithTax__c = 220000,RICSC_CurrencyKey__c = 'EUR',RICSC_Channel__c = 'Charity');
      transactionsList.add(testTransaction1);
      RICSC_Transaction__c testTransaction2 = new RICSC_Transaction__c(RICSC_Account__c = localAccount.Id,RICSC_TransactionCategory__c = 'Sale',RICSC_AmountWithTax__c = 220000,RICSC_CurrencyKey__c = 'EUR',RICSC_Channel__c = 'Boutique');
      transactionsList.add(testTransaction2);
      insert transactionsList;
      Account goldenAccount = [SELECT Id FROM Account WHERE Id = :localAccount.RICSC_GoldenRecord__c LIMIT 1];
      goldenAccount.RICSC_DataOrigin__c = 'NOT-WS';
      update goldenAccount;
      goldenAccount = [SELECT Id, RICSC_ClassCode__c,RICSC_TotalNumberOfRepairs__c FROM Account WHERE Id = :goldenAccount.Id];
      System.assertEquals(UtilityConstants.CLASS_CODE_MCLNT, goldenAccount.RICSC_ClassCode__c, 'Wrong class code');
      Test.stopTest();
    }

    static testmethod void countryOfOriginPropagation(){

     Test.startTest();
      Account myowner = [SELECT id FROM Account WHERE LastName = 'AccountCountryofOriginPropagation'];
      myowner.RICSC_CountryofOrigin__c='Greece';
      update myowner;
     Test.stopTest();

      System.assertEquals([SELECT RICSC_CountryofOrigin__c FROM RICSC_Email__c WHERE RICSC_Account__c = :myowner.Id][0].RICSC_CountryOfOrigin__c,'Greece');
      System.assertEquals([SELECT RICSC_CountryofOrigin__c FROM RICSC_Email__c WHERE RICSC_Account__c = :myowner.Id][1].RICSC_CountryOfOrigin__c,'Greece');
      System.assertEquals([SELECT RICSC_CountryofOrigin__c FROM RICSC_Activity__c WHERE RICSC_Account__c = :myowner.Id][0].RICSC_CountryOfOrigin__c,'Greece');
      System.assertEquals([SELECT RICSC_CountryofOrigin__c FROM RICSC_SocialMediaID__c WHERE RICSC_Account__c = :myowner.Id][0].RICSC_CountryOfOrigin__c,'Greece');
      System.assertEquals([SELECT RICSC_CountryofOrigin__c FROM RICSC_Address__c WHERE RICSC_Account__c = :myowner.Id][0].RICSC_CountryOfOrigin__c,'Greece');
      System.assertEquals([SELECT RICSC_CountryofOrigin__c FROM RICSC_Wishlist__c WHERE RICSC_Account__c = :myowner.Id][0].RICSC_CountryOfOrigin__c,'Greece');
      System.assertEquals([SELECT RICSC_CountryofOrigin__c FROM RICSC_Relation__c WHERE RICSC_Account__c = :myowner.Id][0].RICSC_CountryOfOrigin__c,'Greece');
      System.assertEquals([SELECT RICSC_CountryofOrigin__c FROM RICSC_Phone__c WHERE RICSC_Account__c = :myowner.Id][0].RICSC_CountryOfOrigin__c,'Greece');
    }

}