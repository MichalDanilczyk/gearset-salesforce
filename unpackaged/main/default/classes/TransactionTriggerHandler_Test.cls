@isTest
public with sharing class TransactionTriggerHandler_Test {

@testSetup

  static void setup() {
    //Note pier: we should improve the setup here. group records to be inserted in lists when possible

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

    Account newVanCleefAndArpelsGoldenRecordAccount = UtilityTests.getPersonAccount();
    newVanCleefAndArpelsGoldenRecordAccount.LastName = 'VanCleefAndArpelsFranceGoldenRecordAccount';
    newVanCleefAndArpelsGoldenRecordAccount.RICSC_VIP__c = true;
    newVanCleefAndArpelsGoldenRecordAccount.RICSC_ReferenceSA__c = newFrenchSalesAssociate.Id;
    insert newVanCleefAndArpelsGoldenRecordAccount;

    Account newCARGoldenRecordAccount = UtilityTests.getPersonAccount(UtilityConstants.PERSON_ACCOUNT_CAR_RT);
    newCARGoldenRecordAccount.LastName = 'CARAVGBasketGoldenRecordAccount';
    newCARGoldenRecordAccount.RICSC_HasLocalRecords__c = true;
    insert newCARGoldenRecordAccount;

    Account newCARAccount = UtilityTests.getPersonAccount(UtilityConstants.PERSON_ACCOUNT_CAR_RT);
    newCARAccount.LastName = 'CARAVGBasketAccount';
    newCARAccount.RICSC_GoldenRecord__c = newCARGoldenRecordAccount.Id;
    newCARAccount.RICSC_IsGoldenRecord__c = false;
    insert newCARAccount;

    RICSC_Transaction__c afterUpdateVCATestingTransaction = UtilityTests.getTransaction();
    afterUpdateVCATestingTransaction.RICSC_Account__c = newVanCleefAndArpelsAccount.Id;
    afterUpdateVCATestingTransaction.RICSC_AmountWithTaxEUR__c = 251235;
    afterUpdateVCATestingTransaction.RICSC_TransactionCategory__c = UtilityConstants.TRANSACTION_TYPE_SALES;
    afterUpdateVCATestingTransaction.RICSC_TransactionDate__c = Date.newInstance(2017,2,3);
    afterUpdateVCATestingTransaction.RICSC_CurrencyKey__c = 'EUR';
    afterUpdateVCATestingTransaction.RICSC_Maison__c = 'Van Cleef & Arpels';
    insert afterUpdateVCATestingTransaction;

    RICSC_Transaction__c afterUpdateTestingTransaction = UtilityTests.getTransaction();
    afterUpdateTestingTransaction.RICSC_Account__c = newCARAccount.Id;
    afterUpdateTestingTransaction.RICSC_AmountWithTaxEUR__c = 251234;
    afterUpdateTestingTransaction.RICSC_TransactionCategory__c = UtilityConstants.TRANSACTION_TYPE_SALES;
    afterUpdateTestingTransaction.RICSC_TransactionDate__c = Date.newInstance(2017,2,3);
    afterUpdateTestingTransaction.RICSC_CurrencyKey__c = 'EUR';
    afterUpdateTestingTransaction.RICSC_Maison__c = 'Cartier';
    insert afterUpdateTestingTransaction;

    RICSC_Transaction__c afterUpdateTestingTransaction1 = UtilityTests.getTransaction();
    afterUpdateTestingTransaction1.RICSC_Account__c = newCARAccount.Id;
    afterUpdateTestingTransaction1.RICSC_AmountWithTaxEUR__c = 260000;
    afterUpdateTestingTransaction1.RICSC_TransactionCategory__c = UtilityConstants.TRANSACTION_TYPE_SALES;
    afterUpdateTestingTransaction1.RICSC_TransactionDate__c = Date.newInstance(2017,2,3);
    afterUpdateTestingTransaction1.RICSC_CurrencyKey__c = 'EUR';
    afterUpdateTestingTransaction1.RICSC_Maison__c = 'Cartier';
    insert afterUpdateTestingTransaction1;

    Account newVanCleefAndArpelsMonacoAccount = UtilityTests.getPersonAccount();
    newVanCleefAndArpelsMonacoAccount.LastName = 'VanCleefAndArpelsMonacoAccount';
    newVanCleefAndArpelsMonacoAccount.RICSC_VIP__c = true;
    newVanCleefAndArpelsMonacoAccount.RICSC_ReferenceSA__c = newMonacoSalesAssociate.Id;
    insert newVanCleefAndArpelsMonacoAccount;

    Account newVanCleefAndArpelsFrenchAccount = new Account();
    newVanCleefAndArpelsFrenchAccount.LastName = 'VanCleefAndArpelsFranceAccountNonVip';
    newVanCleefAndArpelsFrenchAccount.RICSC_VIP__c = false;
    newVanCleefAndArpelsFrenchAccount.RICSC_ReferenceSA__c = newMonacoSalesAssociate.Id;
    insert newVanCleefAndArpelsFrenchAccount;

    Account mrScore1 = UtilityTests.getPersonAccount();
    mrScore1.LastName = 'MRScore1';
    insert mrScore1;
    Account mrScore2 = UtilityTests.getPersonAccount();
    mrScore2.LastName = 'MRScore2';
    insert mrScore2;
    Account mrScore3 = UtilityTests.getPersonAccount();
    mrScore3.LastName = 'MRScore3';
    insert mrScore3;


  }

  static testmethod void afterInsertSharingRulesCreateOnTransactionObject() {
    Test.startTest();
    Contact frenchAccount = [SELECT Id FROM Contact WHERE RICSC_CountryOfOrigin__c = 'France' LIMIT 1];
    Account vanCleefAndArpelsAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c FROM Account WHERE Name = 'VanCleefAndArpelsFranceAccount'];
    RICSC_Transaction__c testTransaction = UtilityTests.getTransaction();
    testTransaction.RICSC_CountryOfOrigin__c = 'Monaco';
    testTransaction.RICSC_Account__c = VanCleefAndArpelsAccount.Id;
    testTransaction.RICSC_AmountWithTaxEUR__c=22222222;
    testTransaction.RICSC_CurrencyKey__c='EUR';
    testTransaction.RICSC_TransactionCategory__c='Sale';
    insert testTransaction;

    List<Group> gp = [SELECT DeveloperName FROM Group WHERE Id IN (SELECT UserOrGroupId FROM RICSC_Transaction__share)];
    Test.stopTest();
    System.assertEquals(gp.isEmpty(),false);
  }

  static testmethod void afterUpdateSharingRulesCreateOnTransactionObject() {
    Test.startTest();
    //BeforeUpdate
    List<Group> gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMMonaco' AND Id IN (SELECT UserOrGroupId FROM RICSC_Transaction__share)];
    System.assertEquals(gp.isEmpty(),true);


    Account acc = [SELECT Id FROM Account WHERE Name = 'VanCleefAndArpelsMonacoAccount'];
    RICSC_Transaction__c updateTransaction = [SELECT Id,RICSC_Account__c FROM RICSC_Transaction__c WHERE RICSC_AmountWithTaxEUR__c = 251234];
    updateTransaction.RICSC_Account__c = acc.Id;
    update updateTransaction;

    //AfterUpdate
    gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMMonaco' AND Id IN (SELECT UserOrGroupId FROM RICSC_Transaction__share)];
    Test.stopTest();
    System.assertEquals(gp.isEmpty(),false);
  }

  static testmethod void afterUpdateSharingRulesCreateOnTransactionObjectOnCountryOfOriginChange() {
    Test.startTest();
    //BeforeUpdate
    List<Group> gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMUSA' AND Id IN (SELECT UserOrGroupId FROM RICSC_Transaction__share)];
    System.assertEquals(gp.isEmpty(),true);

    RICSC_Transaction__c updateTransaction = [SELECT Id,RICSC_CountryOfOrigin__c FROM RICSC_Transaction__c WHERE RICSC_AmountWithTaxEUR__c = 251235];
    updateTransaction.RICSC_CountryOfOrigin__c = 'USA';
    update updateTransaction;

    //AfterUpdate
    gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMUSA' AND Id IN (SELECT UserOrGroupId FROM RICSC_Transaction__share)];
    Test.stopTest();
    System.assertEquals(gp.isEmpty(),false);
  }

  static testmethod void afterUpdateSharingRulesCreateOnTransactionObjectToNonVip() {
    Test.startTest();
    //BeforeUpdate
    List<Group> gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMMonaco' AND Id IN (SELECT UserOrGroupId FROM RICSC_Transaction__share)];
    System.assertEquals(gp.isEmpty(),true);

    Account acc = [SELECT Id FROM Account WHERE Name = 'VanCleefAndArpelsFranceAccountNonVip'];
    RICSC_Transaction__c updateTransaction = [SELECT Id,RICSC_Account__c FROM RICSC_Transaction__c WHERE RICSC_AmountWithTaxEUR__c = 251234];
    updateTransaction.RICSC_Account__c = acc.Id;
    update updateTransaction;

    //AfterUpdate
    gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMMonaco' AND Id IN (SELECT UserOrGroupId FROM RICSC_Transaction__share)];
    Test.stopTest();
    System.assertEquals(gp.isEmpty(),true);
  }

  static testmethod void afterInsertMRScoreCalculation(){
    Test.startTest();

    List<Account> acc = [SELECT id FROM Account Where Name = 'MRScore1' OR Name = 'MRScore2' OR Name = 'MRScore3' Order By Name DESC];
    List<RICSC_Transaction__c> instrans = new List<RICSC_Transaction__c>();
    RICSC_Transaction__c trCARNor = new RICSC_Transaction__c(RICSC_Account__c=acc[0].id,RICSC_Maison__c='Cartier',RICSC_AmountWithTaxEUR__c=1000,RICSC_TransactionCategory__c=UtilityConstants.TRANSACTION_TYPE_SALES,RICSC_TransactionDate__c=System.now().date(),RICSC_SerialNumber__c='1000',RICSC_CurrencyKey__c='EUR');
    RICSC_Transaction__c trCARRep = new RICSC_Transaction__c(RICSC_Account__c=acc[0].id,RICSC_Maison__c='Cartier',RICSC_AmountWithTaxEUR__c=1000,RICSC_TransactionCategory__c=UtilityConstants.TRANSACTION_TYPE_RETURN,RICSC_TransactionDate__c=System.now().date(),RICSC_SerialNumber__c='1000',RICSC_CurrencyKey__c='EUR');
    RICSC_Transaction__c trCARNor2 = new RICSC_Transaction__c(RICSC_Account__c=acc[0].id,RICSC_Maison__c='Cartier',RICSC_AmountWithTaxEUR__c=1000,RICSC_TransactionCategory__c=UtilityConstants.TRANSACTION_TYPE_SALES,RICSC_TransactionDate__c=System.now().date(),RICSC_SerialNumber__c='1001',RICSC_CurrencyKey__c='EUR');
    RICSC_Transaction__c trCARNor2nullAm = new RICSC_Transaction__c(RICSC_Account__c=acc[0].id,RICSC_Maison__c='Cartier',RICSC_TransactionCategory__c=UtilityConstants.TRANSACTION_TYPE_SALES,RICSC_TransactionDate__c=System.now().adddays(-5).date(),RICSC_SerialNumber__c='1002',RICSC_CurrencyKey__c='EUR');
    RICSC_Transaction__c trCARNorbef = new RICSC_Transaction__c(RICSC_Account__c=acc[0].id,RICSC_Maison__c='Cartier',RICSC_AmountWithTaxEUR__c=1000,RICSC_TransactionCategory__c=UtilityConstants.TRANSACTION_TYPE_SALES,RICSC_TransactionDate__c=System.now().addyears(-6).date(),RICSC_SerialNumber__c='1003',RICSC_CurrencyKey__c='EUR');
    RICSC_Transaction__c trJLCNor = new RICSC_Transaction__c(RICSC_Account__c=acc[1].id,RICSC_Maison__c='Jaeger Le Coultre',RICSC_AmountWithTaxEUR__c=1000,RICSC_TransactionCategory__c=UtilityConstants.TRANSACTION_TYPE_SALES,RICSC_TransactionDate__c=System.now().date(),RICSC_SerialNumber__c='3000',RICSC_CurrencyKey__c='EUR');
    RICSC_Transaction__c trJLCNorbef = new RICSC_Transaction__c(RICSC_Account__c=acc[1].id,RICSC_Maison__c='Jaeger Le Coultre',RICSC_AmountWithTaxEUR__c=1000,RICSC_TransactionCategory__c=UtilityConstants.TRANSACTION_TYPE_SALES,RICSC_TransactionDate__c=System.now().addyears(-7).date(),RICSC_SerialNumber__c='3003',RICSC_CurrencyKey__c='EUR');
    RICSC_Transaction__c trJLCNorGR = new RICSC_Transaction__c(RICSC_Account__c=acc[2].id,RICSC_Maison__c='Jaeger Le Coultre',RICSC_AmountWithTaxEUR__c=1000,RICSC_TransactionCategory__c=UtilityConstants.TRANSACTION_TYPE_SALES,RICSC_TransactionDate__c=System.now().date(),RICSC_SerialNumber__c='3001',RICSC_CurrencyKey__c='EUR');
    RICSC_Transaction__c trJLCNorGRnullAm = new RICSC_Transaction__c(RICSC_Account__c=acc[2].id,RICSC_Maison__c='Jaeger Le Coultre',RICSC_AmountWithTaxEUR__c=1000,RICSC_TransactionCategory__c=UtilityConstants.TRANSACTION_TYPE_SALES,RICSC_TransactionDate__c=System.now().date(),RICSC_SerialNumber__c='3002',RICSC_CurrencyKey__c='EUR');
    RICSC_Transaction__c trJLCCSGRnullAm = new RICSC_Transaction__c(RICSC_Account__c=acc[2].id, RICSC_Maison__c='Jaeger Le Coultre',RICSC_AmountWithTaxEUR__c=1000,RICSC_TransactionCategory__c=UtilityConstants.TRANSACTION_TYPE_REPAIR,RICSC_TransactionDate__c=System.now().date(),RICSC_SerialNumber__c='3003',RICSC_CurrencyKey__c='EUR');
    instrans.add(trCARNor);
    instrans.add(trCARNor2);
    instrans.add(trCARNor2nullAm);
    instrans.add(trCARRep);
    instrans.add(trCARNorbef);
    instrans.add(trJLCNorbef);
    instrans.add(trJLCNor);
    instrans.add(trJLCNorGR);
    instrans.add(trJLCNorGRnullAm);
    instrans.add(trJLCCSGRnullAm);
    insert instrans;
    List<Account> resins = [SELECT Id,RICSC_MasterRecordScore__c FROM Account Where Name = 'MRScore1' OR Name = 'MRScore2' OR Name = 'MRScore3' Order By Name DESC];
    System.assertEquals(3000,resins[0].RICSC_MasterRecordScore__c);
    System.assertEquals(4000,resins[1].RICSC_MasterRecordScore__c);
    System.assertEquals(2000,resins[2].RICSC_MasterRecordScore__c);

    List<RICSC_Transaction__c> updtrans = [Select id,RICSC_AmountWithTaxEUR__c,RICSC_Maison__c,RICSC_GoldenRecord__c,RICSC_SerialNumber__c
                                                  From RICSC_Transaction__c
                                                  Where RICSC_SerialNumber__c = '1001' OR RICSC_SerialNumber__c = '1003' OR RICSC_SerialNumber__c='3001'
                                                  ORDER By RICSC_SerialNumber__c ASC];
    updtrans[0].RICSC_AmountWithTaxEUR__c=2000;
    updtrans[1].RICSC_AmountWithTaxEUR__c=3000;
    updtrans[2].RICSC_AmountWithTaxEUR__c=4000;
    update updtrans;
    List<Account> resupd = [SELECT Id,RICSC_MasterRecordScore__c FROM Account Where Name = 'MRScore1' OR Name = 'MRScore2' OR Name = 'MRScore3' Order By Name DESC];
    Test.stopTest();
    System.assertEquals(4000,resupd[0].RICSC_MasterRecordScore__c);
    System.assertEquals(4000,resupd[1].RICSC_MasterRecordScore__c);
    System.assertEquals(5000,resupd[2].RICSC_MasterRecordScore__c);

  }

  //----------------------------------- Calculating fields --------------------------------------------//

  static testmethod void localGoldenRecordAverageBasketTurnoverOnUpdate(){
    Test.startTest();
    // acc have already 2 transaction linked (1:amount 260000 2:amount 251234 both transactions in the same day)
    Account acc = [SELECT Id,RICSC_Turnover__c,RICSC_AverageBasket__c FROM Account WHERE Name = 'CARAVGBasketAccount'];
    
    Account goldenRecord2 = [SELECT Id,RICSC_Turnover__c,RICSC_AverageBasket__c FROM Account WHERE Name = 'CARAVGBasketGoldenRecordAccount'];
    // 1 of the 2 transaction is updated
    RICSC_Transaction__c updateTransaction = [SELECT Id,RICSC_TransactionCategory__c FROM RICSC_Transaction__c WHERE RICSC_AmountWithTaxEUR__c = 251234];
    updateTransaction.RICSC_TransactionCategory__c = UtilityConstants.TRANSACTION_TYPE_SALES;
    updateTransaction.RICSC_GoldenRecord__c = goldenRecord2.Id;
    updateTransaction.RICSC_AmountWithTaxEUR__c=250000;
    update updateTransaction;


    Account accAfter = [SELECT Id,RICSC_Turnover__c,RICSC_AverageBasket__c FROM Account WHERE Name = 'CARAVGBasketAccount'];
    Account goldenRecordAfter2 = [SELECT Id,RICSC_Turnover__c,RICSC_AverageBasket__c FROM Account WHERE Name = 'CARAVGBasketGoldenRecordAccount'];
    Test.stopTest();
    //avg basket logic:
    //JLC, CAR, IWC  sum of transactions amount (all categories)  / number of transactions  (all categories)
    //VCA: sum of transactions (only SALES and Only high Jewelery., Jewelery, watches, Bridal)  / number of transactions  (only SALES and ONLY high Jewelery., Jewelery, watches, Bridal)
    
    System.assertEquals(510000, accAfter.RICSC_Turnover__c);
    System.assertEquals(255000, accAfter.RICSC_AverageBasket__c);
    
    //same calculation on golden record as only 1 acc related
    //NOTE Pier we should this to test on cases with more than 1 local record
    System.assertEquals(510000, goldenRecordAfter2.RICSC_Turnover__c);
    System.assertEquals(255000, goldenRecordAfter2.RICSC_AverageBasket__c);
  }

  static testmethod void localGoldenRecordAverageBasketTurnoverOnDelete(){
    Test.startTest();
    Account acc = [SELECT Id FROM Account WHERE Name = 'CARAVGBasketAccount'];
    Account goldenRecord2 = [SELECT Id FROM Account WHERE Name = 'CARAVGBasketGoldenRecordAccount'];


    RICSC_Transaction__c updateTransaction = [SELECT Id,RICSC_CountryOfOrigin__c FROM RICSC_Transaction__c WHERE RICSC_AmountWithTaxEUR__c = 260000];
    delete updateTransaction;


    Account accAfter = [SELECT Id,RICSC_Turnover__c,RICSC_AverageBasket__c FROM Account WHERE Name = 'CARAVGBasketAccount'];
    Account goldenRecordAfter2 = [SELECT Id,RICSC_Turnover__c,RICSC_AverageBasket__c FROM Account WHERE Name = 'CARAVGBasketGoldenRecordAccount'];
    Test.stopTest();
    // after deletion only 1 transaction  related to both local and golden
    System.assertEquals(251234, accAfter.RICSC_AverageBasket__c);
    System.assertEquals(251234, accAfter.RICSC_Turnover__c);
    System.assertEquals(251234, goldenRecordAfter2.RICSC_AverageBasket__c);
    System.assertEquals(251234, goldenRecordAfter2.RICSC_Turnover__c);

  }
}