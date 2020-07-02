/****************************************************************************************************************************
* @author       Piergiorgio Lisanti
* @date         26/Aug/2019
* @description  General Utility class for TESTS
*****************************************************************************************************************************/
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class UtilityTests {

    @TestVisible
    private static void testSetup(){

        setupGeneralSettings();
        setupTriggerSettings();

    }


    private static void setupGeneralSettings(){

        GeneralSettings__c generalSetting = GeneralSettings__c.getOrgDefaults();

        //**Attention: Change scope accroding to the organization**//
        Boolean isProd = ([SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox == false);
        String scopeStr = isProd ? UtilityConstants.FunctionalScopes.PRD.name() : UtilityConstants.FunctionalScopes.SBX.name();
        generalSetting.Scope__c = scopeStr;
        generalSetting.RICSC_ProductPortfolioIntegrationDate__c = Date.newInstance(2014, 9, 9);
        generalSetting.Logger_DebugEnabled__c = true;
        generalSetting.Logger_ExceptionEnabled__c = true;
        generalSetting.RICSC_RunSegmentationAfterDCJob__c = true;
        generalSetting.RICSC_RunConsentsAlignmentAfterDCJob__c = true;
        generalSetting.RICSC_VCACRMNonChinaPublicGroupNoMembers__c = 'RICSC_VCACRMAmericasRegion,RICSC_VCACRMAsiaPacificRegion,RICSC_VCACRMEuropeCIS,RICSC_VCACRMFranceRegion,RICSC_VCACRMHongKongMacao,RICSC_VCACRMHQ,RICSC_VCACRMMiddleEastRegion,RICSC_VCACRMSouthEastAsiaAustralia,RICSC_VCACRMWorld,RICSC_VCACRMChina';

        for(Group g : [Select Id,DeveloperName From Group where DeveloperName = 'AllInternalUsers' limit 1]){

            if(g.developerName == 'AllInternalUsers'){

                generalSetting.GroupId_AllInternalUsers__c  = g.Id;

            }
        }

        upsert generalSetting  GeneralSettings__c.Id;
    }

    private static void setupTriggerSettings(){

        TRG_TriggerSettings__c triggerSetting = TRG_TriggerSettings__c.getOrgDefaults();

        triggerSetting.DisableAllProcessBuilders__c = false;
        triggerSetting.DisableAllTriggers__c = false;
        triggerSetting.DisableAllWorkflows__c = false;
        triggerSetting.CheckEnabledOnLeanLoad__c = false;
        triggerSetting.PrintLimitsInDebug__c = true;
        triggerSetting.DisableTriggerMethods__c = '';
        triggerSetting.DisableTriggerObjects__c = '';

        upsert triggerSetting  TRG_TriggerSettings__c.Id;
    }

    @TestVisible
    private static User getUser(String profileName){

        return new User(
                LastName            = 'PREFIX' + System.now().millisecond(),
                Email               = 'PREFIX'+ System.now().millisecond() +'@test.com',
                Username            = 'PREFIX'+ string.valueOf(Crypto.getRandomInteger()) +'@test.com',
                Alias               = 'alias' + System.now().millisecond(),
                ProfileId           =  profileMap.get(profileName).Id,
                LocaleSidKey        = 'en_TZ',
                EmailEncodingKey    = 'ISO-8859-1',
                TimeZoneSidKey      = 'GMT',
                LanguageLocaleKey   = 'en_US'
                );
    }

    private static Map<String,Profile> profileMap {

        get {

            if(profileMap == null){

                profileMap = new Map<String,Profile>();

                for(Profile p : [SELECT Id, Name FROM Profile]){
                    profileMap.put(p.Name, p);
                }
            }

            return profileMap;

        }
        private set;

    }

    @TestVisible
    private static Account getAccount(){
      return new Account(
        Name = 'Account_' + System.now().millisecond()
      );
    }

    @TestVisible
    private static List<Account> getAccounts(integer size){
        List<Account> accounts = new List<Account>();
        for(Integer i=0; i<size; i++){ accounts.add(getAccount()); }
        return accounts;
    }

    @TestVisible
    private static Account getPersonAccount(){
      return getPersonAccount(UtilityConstants.PERSON_ACCOUNT_VCA_RT);
    }

    @TestVisible
    private static List<Account> getPersonAccounts(integer size){
        List<Account> accounts = new List<Account>();
        for(Integer i=0; i<size; i++){ accounts.add(getAccount()); }
        return accounts;
    }

    @TestVisible
    private static Account getPersonAccount(String rtDevName){
      return new Account(
        LastName = 'Account_' + System.now().millisecond(),
        RecordTypeId = RecordTypeHelper.getRTId('Account', rtDevName)
      );
    }

    @TestVisible
    private static Contact getContact(){
      return new Contact(
        LastName  = 'Contact_' + System.now().millisecond()
      );
    }

    @TestVisible
    private static List<Contact> getContacts(integer size){
        List<Contact> contacts = new List<Contact>();
        for(Integer i=0; i<size; i++){ contacts.add(getContact()); }
        return contacts;
    }

    @TestVisible
    private static RICSC_Email__c getEmail(){
      return new RICSC_Email__c(
      );
    }

    @TestVisible
    private static List<RICSC_Email__c> getEmails(integer size){
        List<RICSC_Email__c> emails = new List<RICSC_Email__c>();
        for(Integer i=0; i<size; i++){ emails.add(getEmail()); }
        return emails;
    }

    @TestVisible
    private static RICSC_Transaction__c getTransaction(){
      return new RICSC_Transaction__c(
        RICSC_CountryOfOrigin__c = 'France'
      );
    }

    @TestVisible
    private static Product2 getProduct(){
      return new Product2();
    }

    @TestVisible
    private static List<Product2> getProducts(integer size){
        List<Product2> products = new List<Product2>();
        for(Integer i=0; i<size; i++){ products.add(getProduct()); }
        return products;
    }

    @TestVisible
    private static RICSC_Wishlist__c getWishlist(){
      return new RICSC_Wishlist__c();
    }

    @TestVisible
    private static RICSC_Relation__c getRelation(){
      return new RICSC_Relation__c();
    }

    @TestVisible
    private static RICSC_Activity__c getActivity(){
      return new RICSC_Activity__c();
    }

    @TestVisible
    private static List<RICSC_Wishlist__c> getWishlists(integer size){
        List<RICSC_Wishlist__c> wishlists = new List<RICSC_Wishlist__c>();
        for(Integer i=0; i<size; i++){ wishlists.add(getWishlist()); }
        return wishlists;
    }


    @TestVisible
    private static Asset getAsset(){
      return new Asset();
    }

    @TestVisible
    private static List<Asset> getAssets(integer size){
        List<Asset> assets = new List<Asset>();
        for(Integer i=0; i<size; i++){ assets.add(getAsset()); }
        return assets;
    }

    @TestVisible
    private static List<RICSC_Transaction__c> getTransactions(integer size){
        List<RICSC_Transaction__c> transactions = new List<RICSC_Transaction__c>();
        for(Integer i=0; i<size; i++){ transactions.add(getTransaction()); }
        return transactions;
    }

    @TestVisible
    private static Account getBoutique(){
      return new Account(
        Name  = 'Boutique_' + System.now().millisecond(),
        RecordTypeId = RecordTypeHelper.getRTID('Account',UtilityConstants.ACCOUNTBOUTIQUE_RT)
      );
    }

    @TestVisible
    private static List<Account> getBoutiques(integer size){
        List<Account> boutiques = new List<Account>();
        for(Integer i=0; i<size; i++){ boutiques.add(getBoutique()); }
        return boutiques;
    }

    @TestVisible
    private static RICSC_SocialMediaID__c getSocialMediaID(){
      return new RICSC_SocialMediaID__c(
      );
    }

    @TestVisible
    private static List<RICSC_SocialMediaID__c> getSocialMediaIDs(integer size){
        List<RICSC_SocialMediaID__c> socialMediaIDs = new List<RICSC_SocialMediaID__c>();
        for(Integer i=0; i<size; i++){ SocialMediaIDs.add(getSocialMediaID()); }
        return SocialMediaIDs;
    }

    @TestVisible
    private static RICSC_Address__c getAddress(){
      return new RICSC_Address__c(
      );
    }

    @TestVisible
    private static List<RICSC_Address__c> getAddresses(integer size){
        List<RICSC_Address__c> addresss = new List<RICSC_Address__c>();
        for(Integer i=0; i<size; i++){ Addresss.add(getAddress()); }
        return Addresss;
    }

    @TestVisible
    private static RICSC_Phone__c getPhone(){
      return new RICSC_Phone__c(
      );
    }

    @TestVisible
    private static List<RICSC_Phone__c> getPhones(integer size){
        List<RICSC_Phone__c> phones = new List<RICSC_Phone__c>();
        for(Integer i=0; i<size; i++){ Phones.add(getPhone()); }
        return Phones;
    }

    @TestVisible
    private static PermissionSet getPermSet(String permSetName){
        return permSetMap.get(permSetName);
    }

    private static Map<String,PermissionSet> permSetMap {
        get {
            if(permSetMap == null){
                permSetMap = new Map<String,PermissionSet>();
                for(PermissionSet ps : [SELECT Id, Name FROM PermissionSet]){
                    permSetMap.put(ps.Name, ps);
                }
            }
            return permSetMap;
        }
        private set;
}

}