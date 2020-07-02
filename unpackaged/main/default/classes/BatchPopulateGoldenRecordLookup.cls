public class BatchPopulateGoldenRecordLookup implements Database.Batchable<SObject>, Schedulable {

    public Integer MAXSCOPE = 100;
    private Set<String> recordTypeSet = UtilityConstants.PERSON_ACCOUNT_RT_SET_ID;
    public String query = 'SELECT Id, RecordTypeId, RICSC_GoldenRecord__c, RICSC_Turnover__c, RICSC_ClientFlag__c, RICSC_GlobalSegment__c, RICSC_Vip__c FROM Account';
    public Boolean skipTriggers = false;

    public Iterable<SObject> start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public BatchPopulateGoldenRecordLookup(Boolean skipParam, String queryStr) {
        this.query = queryStr == null ? this.query : queryStr;
        skipTriggers = skipParam;
    }

    public void execute(SchedulableContext sc) {
        BatchPopulateGoldenRecordLookup b = new BatchPopulateGoldenRecordLookup(false,null);
        Database.executeBatch(b, MAXSCOPE);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
      try{
        Map<Id,Account> scopeMap = new Map<Id,Account>(scope);
        List<Account> accountWithObjects= [SELECT Id, (SELECT id,RICSC_GoldenRecord__c,RICSC_Account__c FROM RICSC_ActivitiesAccount__r),
                                              (SELECT RICSC_GR__c, RICSC_Account__c FROM RICSC_EmailsAccount__r),
                                              (SELECT RICSC_GR__c, RICSC_Account__c FROM RICSC_SocialMediaIDsAccount__r),
                                              (SELECT RICSC_GR__c, RICSC_Account__c FROM RICSC_AddressesAccount__r),
                                              (SELECT RICSC_GR__c, RICSC_Account__c FROM RICSC_PhonesAccount__r),
                                              (SELECT RICSC_GoldenRecord__c, RICSC_Account__c FROM RICSC_TransactionsAccount__r),
                                              (SELECT RICSC_GoldenRecord__c, AccountId FROM Assets),
                                              (SELECT RICSC_GoldenRecord__c, RICSC_Account__c FROM RICSC_WishlistsAccount__r),
                                              (SELECT RICSC_GoldenRecord__c, RICSC_Account__c FROM RICSC_RelationsAccount__r),
                                              (SELECT RICSC_GoldenRecord__c, AccountId FROM Cases)
                                              FROM Account where Id in :scopeMap.keySet()];
        List<RICSC_Activity__c> activities = new List<RICSC_Activity__c>();
        List<RICSC_Address__c> addresses = new List<RICSC_Address__c>();
        List<RICSC_Email__c> emails = new List<RICSC_Email__c>();
        List<RICSC_Phone__c> phones = new List<RICSC_Phone__c>();
        List<Asset> assets = new List<Asset>();
        List<RICSC_Relation__c> relations = new List<RICSC_Relation__c>();
        List<RICSC_SocialMediaID__c> socialMediaIDs = new List<RICSC_SocialMediaID__c>();
        List<RICSC_Transaction__c> transactions = new List<RICSC_Transaction__c>();
        List<RICSC_Wishlist__c> wishlists = new List<RICSC_Wishlist__c>();
        List<Case> cases = new List<Case>();
        for(Account acc : accountWithObjects){
          activities.addAll(acc.RICSC_ActivitiesAccount__r);
          addresses.addall(acc.RICSC_AddressesAccount__r);
          emails.addall(acc.RICSC_EmailsAccount__r);
          phones.addall(acc.RICSC_PhonesAccount__r);
          assets.addall(acc.Assets);
          relations.addall(acc.RICSC_RelationsAccount__r);
          socialMediaIDs.addall(acc.RICSC_SocialMediaIDsAccount__r);
          transactions.addall(acc.RICSC_TransactionsAccount__r);
          wishlists.addall(acc.RICSC_WishlistsAccount__r);
          cases.addAll(acc.Cases);
        }
        UtilityAccount.goldenRecordLookUpPopulate('RICSC_ActivitiesAccount__r','RICSC_Account__c','RICSC_GoldenRecord__c','ActivityTriggerHandler',activities);
        UtilityAccount.goldenRecordLookUpPopulate('RICSC_AddressesAccount__r','RICSC_Account__c','RICSC_GR__c','AddressTriggerHandler',addresses);
        UtilityAccount.goldenRecordLookUpPopulate('RICSC_EmailsAccount__r','RICSC_Account__c','RICSC_GR__c','EmailTriggerHandler',emails);
        UtilityAccount.goldenRecordLookUpPopulate('RICSC_PhonesAccount__r','RICSC_Account__c','RICSC_GR__c','PhoneTriggerHandler',phones);
        UtilityAccount.goldenRecordLookUpPopulate('Assets','AccountId','RICSC_GoldenRecord__c','ProductPortfolioTriggerHandler',assets);
        UtilityAccount.goldenRecordLookUpPopulate('RICSC_RelationsAccount__r','RICSC_Account__c','RICSC_GoldenRecord__c','RelationTriggerHandler',relations);
        UtilityAccount.goldenRecordLookUpPopulate('RICSC_SocialMediaIDsAccount__r','RICSC_Account__c','RICSC_GR__c','SocialMediaIDTriggerHandler',socialMediaIDs);
        UtilityAccount.goldenRecordLookUpPopulate('Cases','AccountId','RICSC_GoldenRecord__c','TicketTriggerHandler', cases);
        UtilityAccount.goldenRecordLookUpPopulate('RICSC_TransactionsAccount__r','RICSC_Account__c','RICSC_GoldenRecord__c','TransactionTriggerHandler',transactions);
        UtilityAccount.goldenRecordLookUpPopulate('RICSC_WishlistsAccount__r','RICSC_Account__c','RICSC_GoldenRecord__c','WishlistTriggerHandler',wishlists);
        List<SObject> objects = new List<SObject>();
        objects.addAll(activities);
        objects.addAll(addresses);
        objects.addAll(emails);
        objects.addAll(phones);
        objects.addAll(assets);
        objects.addAll(relations);
        objects.addAll(socialMediaIDs);
        objects.addAll(cases);
        objects.addAll(transactions);
        objects.addAll(wishlists);
        if(skipTriggers){
          TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Activity__c',true);
          TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Address__c',true);
          TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Email__c',true);
          TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Phone__c',true);
          TRG_TriggerDispatcher.skipTriggerMap.put('Asset',true);
          TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Relation__c',true);
          TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_SocialMediaID__c',true);
          TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Transaction__c',true);
          TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Wishlist__c',true);
          TRG_TriggerDispatcher.skipTriggerMap.put('Case',true);
        }
        Database.SaveResult[] srList = Database.update(objects);
        UtilityLogger.logAllErrors(srList, false, 'BatchPopulateGoldenRecordLookup','execute');
        if(skipTriggers){
          TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Activity__c',false);
          TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Address__c',false);
          TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Email__c',false);
          TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Phone__c',false);
          TRG_TriggerDispatcher.skipTriggerMap.put('Asset',false);
          TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Relation__c',false);
          TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_SocialMediaID__c',false);
          TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Transaction__c',false);
          TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Wishlist__c',false);
          TRG_TriggerDispatcher.skipTriggerMap.put('Case',false);
        }

      } catch(Exception e) {
        UtilityLogger.logException(e,e.getMessage(),'BatchPopulateGoldenRecordLookup','execute');
      }
    }

    public void finish(Database.BatchableContext bc) {
    }
}