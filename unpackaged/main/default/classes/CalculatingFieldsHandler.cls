public without sharing class CalculatingFieldsHandler {

  //Container class for calculated fields values from account
  public without sharing class CalculatedAccountFieldCont {
    public Id accountId {get;set;}
    public Boolean processConcatFields {get;set;}
    public Boolean processVipFlag {get;set;}
    public String notes {get;set;}
    public String spotNotes {get;set;}
    public Boolean ecard {get;set;}
    public Set<String> collectionOfInterests {get;set;}
    public Set<String> hobbies {get;set;}
    public Set<String> productOfInterests {get;set;}
    public Boolean vip {get;set;}
    public Boolean localvip {get;set;}

    public CalculatedAccountFieldCont(Id accId){
      this.accountId = accId;
      this.notes = '';
      this.spotNotes = '';
      this.ecard = false;
      this.collectionOfInterests = new Set<String>();
      this.hobbies = new Set<String>();
      this.productOfInterests = new Set<String>();
      this.vip = false;
      this.processConcatFields = false;
      this.processVipFlag = false;
      this.localvip = false;
    }
  }

  //given a list of CalculatedAccountFieldCont returns a list of Accounts with caluculated fields computed and ready to be updated
  public static List<Account> getComputedAccounts(List<CalculatedAccountFieldCont> cafcLst){
    List<Account> accLst = new List<Account>();

    for(CalculatedAccountFieldCont cafc : cafcLst){
      Account updatedAcc = new Account();
      updatedAcc.put('Id',cafc.accountId);
      if(cafc.processConcatFields){
        updatedAcc.put('RICSC_Notes__c',cafc.notes);
        updatedAcc.put('RICSC_SpotNotes__c',cafc.spotnotes);
        updatedAcc.put('RICSC_ECard__c',cafc.ecard);
        updatedAcc.put('RICSC_CollectionOfInterests__c',String.join(new List<String>(cafc.collectionOfInterests), ';'));
        updatedAcc.put('RICSC_ProductOfInterests__c',String.join(new List<String>(cafc.productOfInterests), ';'));
        updatedAcc.put('RICSC_Hobbies__c',String.join(new List<String>(cafc.hobbies), ';'));
        updatedAcc.put('RICSC_LocalVIP__c',cafc.localvip);
      }
      if(cafc.processVipFlag){
        updatedAcc.put('RICSC_VIP__c',cafc.vip);
      }

      accLst.add(updatedAcc);
    }
    return accLst;
  }

  public static List<Account> computeFieldsFromTransactionRecords(Set<Id> accIds){
    List<RICSC_Transaction__c> transactionList = [SELECT Id, RICSC_Account__c, RICSC_GoldenRecord__c, RICSC_GoldenRecord__r.RICSC_HasLocalRecords__c,
                                                      RICSC_TransactionCategory__c, RICSC_AmountWithTaxEUR__c, RICSC_SalesAssociate__c,
                                                      RICSC_Maison__c,RICSC_TransactionDate__c,RICSC_Channel__c,
                                                      RICSC_ProductName__c, RICSC_ProductName__r.RICSC_TechnicalProductType__c,
                                                      RICSC_ProductName__r.RICSC_TechnicalProductFamily__c,
                                                      RICSC_Boutique__c, RICSC_Boutique__r.RICSC_Localisation__c,
                                                      RICSC_Account__r.RecordTypeId, RICSC_GoldenRecord__r.RecordTypeId
                                                 FROM RICSC_Transaction__c
                                                 WHERE RICSC_Account__c IN: accIds OR RICSC_GoldenRecord__c IN:accIds];

    List<Account> accountsToBeUpdated = new List<Account>();
    Map<Id,Set<RICSC_Transaction__c>> transactionsXAccountG = new Map<Id,Set<RICSC_Transaction__c>>();
    Map<Id,Set<RICSC_Transaction__c>> transactionsXAccountL = new Map<Id,Set<RICSC_Transaction__c>>();
    Map<Id,Id> localizationXboutiqueId = new  Map<Id,Id>();
    Map<Id,Id> recTypeXaccId = new  Map<Id,Id>();
    Map<Id,Boolean> isGoldenLocalXaccId = new  Map<Id,Boolean>();
    Set<Id> vcaSalesAssociates = new Set<Id>();
    Map<Id,Id> boutiqueXsalesAssociate = new  Map<Id,Id>();

    for(RICSC_Transaction__c trans : transactionList){

      if(trans.RICSC_GoldenRecord__c != null && accIds.contains(trans.RICSC_GoldenRecord__c)){
        if(!transactionsXAccountG.containsKey(trans.RICSC_GoldenRecord__c)){
          transactionsXAccountG.put(trans.RICSC_GoldenRecord__c, new Set<RICSC_Transaction__c>());
        }
        transactionsXAccountG.get(trans.RICSC_GoldenRecord__c).add(trans);

        recTypeXaccId.put(trans.RICSC_GoldenRecord__c,trans.RICSC_GoldenRecord__r.RecordTypeId);
        isGoldenLocalXaccId.put(trans.RICSC_GoldenRecord__c,!trans.RICSC_GoldenRecord__r.RICSC_HasLocalRecords__c);
        if(transactionsXAccountL.containsKey(trans.RICSC_GoldenRecord__c)){
          transactionsXAccountL.remove(trans.RICSC_GoldenRecord__c);
        }
      }

      if(trans.RICSC_Account__c != null && accIds.contains(trans.RICSC_Account__c) && !transactionsXAccountG.containsKey(trans.RICSC_Account__c)){
        if(trans.RICSC_Account__c != trans.RICSC_GoldenRecord__c){
          if(!transactionsXAccountL.containsKey(trans.RICSC_Account__c)){
            transactionsXAccountL.put(trans.RICSC_Account__c, new Set<RICSC_Transaction__c>());
          }
          transactionsXAccountL.get(trans.RICSC_Account__c).add(trans);
        }

        recTypeXaccId.put(trans.RICSC_Account__c,trans.RICSC_Account__r.RecordTypeId);
      }

      if(trans.RICSC_Boutique__c != null && trans.RICSC_Boutique__r.RICSC_Localisation__c != null){
        localizationXboutiqueId.put(trans.RICSC_Boutique__c,trans.RICSC_Boutique__r.RICSC_Localisation__c);
      }

      if(trans.RICSC_Account__r.RecordTypeId == UtilityConstants.PERSON_ACCOUNT_VCA_RT_ID){
        vcaSalesAssociates.add(trans.RICSC_SalesAssociate__c);
      }
    }

    for(Contact c : [SELECT Id, AccountId, Account.RICSC_Localisation__c FROM Contact WHERE Id IN: vcaSalesAssociates]){
      if(c.AccountId != null){
        if(c.Account.RICSC_Localisation__c != null){
          localizationXboutiqueId.put(c.AccountId,c.Account.RICSC_Localisation__c);
        }
      }
      boutiqueXsalesAssociate.put(c.Id, c.AccountId);
    }

    for(String accId : transactionsXAccountL.keySet()){
      accountsToBeUpdated.add(getAccountWithCalcFields(accId, recTypeXaccId.get(accId), true, false, transactionsXAccountL.get(accId), localizationXboutiqueId,boutiqueXsalesAssociate));
    }
    for(String accId : transactionsXAccountG.keySet()){
      accountsToBeUpdated.add(getAccountWithCalcFields(accId, recTypeXaccId.get(accId), false, isGoldenLocalXaccId.get(accId), transactionsXAccountG.get(accId), localizationXboutiqueId,boutiqueXsalesAssociate));
    }
    return accountsToBeUpdated;
  }

  public static Account getAccountWithCalcFields(String accId, Id accRecType, Boolean isLocalRecord, Boolean isGoldenLocal, Set<RICSC_Transaction__c> transactionSet, Map<Id,Id> boutiquesLocalisations, Map<Id,Id> boutiqueXsalesAssociate){

    Boolean isGoldenRecordWithLocalRecords = !isGoldenLocal && !isLocalRecord;
    Boolean saleTransactionExist = false;
    Map<String,Decimal> frequencyXBoutiqueId = new Map<String,Decimal>();
    Map<String,Decimal> turnoverXBoutiqueId = new Map<String,Decimal>();
    Map<String,Decimal> frequencyXsaId = new Map<String,Decimal>();
    Map<String,Decimal> turnoverXsaId = new Map<String,Decimal>();
    Map<String,Decimal> frequencyXmarketName = new Map<String,Decimal>();
    Map<String,Decimal> turnoverXmarketName = new Map<String,Decimal>();
    Map<String,Decimal> frequencyXregionName = new Map<String,Decimal>();
    Map<String,Decimal> turnoverXregionName = new Map<String,Decimal>();
    DateTime dateTimeFiveYearsAgo = System.now().addYears(-5);
    Date dateFiveYearsAgo = Date.newinstance(dateTimeFiveYearsAgo.year(), dateTimeFiveYearsAgo.month(), dateTimeFiveYearsAgo.day());
    Double sum = 0;
    Double turnover = 0;
    Integer counter = 0;
    Date firstTransactionDate = Date.newInstance(3000, 12, 9);
    Date lastTransactionDate = Date.newInstance(1700, 12, 9);
    Date firstSalesDate = Date.newInstance(3000, 12, 9);
    Date lastSalesDate = Date.newInstance(1700, 12, 9);
    Integer numberOfRepairs = 0;
    Double turnoverOfRepairs = 0;
    Integer numberOfSales = 0;
    Double turnoverOfSales = 0;
    Double turnoverOfReturns = 0;
    String lastPurchaseMarket = null;
    String lastPurchaseBoutique = null;
    Boolean hasSalesDate = false;
    Integer highJewCount = 0;
    Double highJewSum = 0;
    Double highJewMax = 0;
    Set<String> salesChannelVariety = new Set<String>();

    Map<String,Set<Date>> uniqueBoutiqueTransactionDates = new  Map<String,Set<Date>>();
    Map<String,Set<Date>> uniqueSATransactionDates = new  Map<String,Set<Date>>();
    Map<String,Set<Date>> uniqueMarketTransactionDates = new  Map<String,Set<Date>>();
    Map<String,Set<Date>> uniqueRegionTransactionDates = new  Map<String,Set<Date>>();

    Account updatedAcc = new Account(Id = accId);

    for(RICSC_Transaction__c tr : transactionSet){
      if(tr.RICSC_AmountWithTaxEUR__c != null){

        if(accRecType == UtilityConstants.PERSON_ACCOUNT_CAR_RT_ID || accRecType == UtilityConstants.PERSON_ACCOUNT_JLC_RT_ID){
          sum += tr.RICSC_AmountWithTaxEUR__c;
          counter ++;
        } else if(accRecType == UtilityConstants.PERSON_ACCOUNT_VCA_RT_ID &&
              tr.RICSC_TransactionCategory__c == UtilityConstants.TRANSACTION_TYPE_SALES &&
              UtilityConstants.PRODUCT_FAMILY_SET_TURNOVER.contains(tr.RICSC_ProductName__r.RICSC_TechnicalProductFamily__c)){
          sum += tr.RICSC_AmountWithTaxEUR__c;
          counter ++;
          if (tr.RICSC_ProductName__r.RICSC_TechnicalProductFamily__c == UtilityConstants.PRODUCT_FAMILY_HMF){
            highJewCount++;
            highJewMax = ((tr.RICSC_AmountWithTaxEUR__c > highjewmax) ? tr.RICSC_AmountWithTaxEUR__c : highjewmax );
            highJewSum = highJewSum + tr.RICSC_AmountWithTaxEUR__c;
          }
        }

          turnover = turnover + tr.RICSC_AmountWithTaxEUR__c;
      }

      if(tr.RICSC_Channel__c != null){
        salesChannelVariety.add(tr.RICSC_Channel__c);
      }

      firstTransactionDate = ((firstTransactionDate > tr.RICSC_TransactionDate__c) ? tr.RICSC_TransactionDate__c : firstTransactionDate);
      lastTransactionDate = ((lastTransactionDate < tr.RICSC_TransactionDate__c) ? tr.RICSC_TransactionDate__c : lastTransactionDate);
      if(tr.RICSC_TransactionCategory__c == UtilityConstants.TRANSACTION_TYPE_SALES){
        numberOfSales = numberOfSales + 1;
        if(tr.RICSC_AmountWithTaxEur__c != null){
          turnoverOfSales = turnoverOfSales + tr.RICSC_AmountWithTaxEur__c;
        }
        firstSalesDate = ((firstSalesDate > tr.RICSC_TransactionDate__c) ? tr.RICSC_TransactionDate__c : firstSalesDate);
        hasSalesDate = true;
        if(lastSalesDate < tr.RICSC_TransactionDate__c){
          lastSalesDate = tr.RICSC_TransactionDate__c;
          lastPurchaseMarket = ((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))!=null)?(Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Name: null);
          lastPurchaseBoutique = tr.RICSC_Boutique__c;
        }
      }

      if(tr.RICSC_TransactionCategory__c == UtilityConstants.TRANSACTION_TYPE_REPAIR){
        numberOfRepairs = numberOfRepairs + 1;
        if(tr.RICSC_AmountWithTaxEur__c != null){
          turnoverOfRepairs = turnoverOfRepairs + tr.RICSC_AmountWithTaxEur__c;
        }
      }

      if(tr.RICSC_TransactionCategory__c == UtilityConstants.TRANSACTION_TYPE_RETURN){
        if(tr.RICSC_AmountWithTaxEur__c != null){
          turnoverOfReturns = turnoverOfReturns + tr.RICSC_AmountWithTaxEur__c;
        }
      }

      if((isGoldenRecordWithLocalRecords || isGoldenLocal) && (accRecType == UtilityConstants.PERSON_ACCOUNT_JLC_RT_ID || tr.RICSC_TransactionDate__c >= dateFiveYearsAgo)){

        if(tr.RICSC_Boutique__c != null && tr.RICSC_AmountWithTaxEUR__c != null && tr.RICSC_TransactionCategory__c != UtilityConstants.TRANSACTION_TYPE_REPAIR){
          if(frequencyXBoutiqueId.get(tr.RICSC_Boutique__c) == null){
            frequencyXBoutiqueId.put(tr.RICSC_Boutique__c, 0);
            turnoverXBoutiqueId.put(tr.RICSC_Boutique__c, 0.00);
            uniqueBoutiqueTransactionDates.put(tr.RICSC_Boutique__c, new Set<Date>());
          }

          if(tr.RICSC_AmountWithTaxEUR__c != null && tr.RICSC_AmountWithTaxEUR__c != 0 && tr.RICSC_TransactionCategory__c != UtilityConstants.TRANSACTION_TYPE_RETURN){
            Set<Date> setOfDates = new Set<Date>();
            setOfDates.add(tr.RICSC_TransactionDate__c);
            if(uniqueBoutiqueTransactionDates.get(tr.RICSC_Boutique__c) != null){
              setOfDates.addAll(uniqueBoutiqueTransactionDates.get(tr.RICSC_Boutique__c));
            }
            uniqueBoutiqueTransactionDates.put(tr.RICSC_Boutique__c,setOfDates);
            frequencyXBoutiqueId.put(tr.RICSC_Boutique__c, uniqueBoutiqueTransactionDates.get(tr.RICSC_Boutique__c).size());
          }

          if(tr.RICSC_TransactionCategory__c == UtilityConstants.TRANSACTION_TYPE_RETURN && tr.RICSC_AmountWithTaxEUR__c > 0){
            turnoverXBoutiqueId.put(tr.RICSC_Boutique__c, turnoverXBoutiqueId.get(tr.RICSC_Boutique__c) - tr.RICSC_AmountWithTaxEUR__c);
          }else{
            turnoverXBoutiqueId.put(tr.RICSC_Boutique__c, turnoverXBoutiqueId.get(tr.RICSC_Boutique__c) + tr.RICSC_AmountWithTaxEUR__c);
          }
        }

        if(tr.RICSC_SalesAssociate__c != null && tr.RICSC_AmountWithTaxEUR__c != null && tr.RICSC_TransactionCategory__c != UtilityConstants.TRANSACTION_TYPE_REPAIR){
          if(frequencyXsaId.get(tr.RICSC_SalesAssociate__c) == null){
            frequencyXsaId.put(tr.RICSC_SalesAssociate__c, 0);
            turnoverXsaId.put(tr.RICSC_SalesAssociate__c, 0.00);
            uniqueSATransactionDates.put(tr.RICSC_SalesAssociate__c, new Set<Date>());
          }

          if(tr.RICSC_AmountWithTaxEUR__c != 0 && tr.RICSC_TransactionCategory__c != UtilityConstants.TRANSACTION_TYPE_RETURN){
            Set<Date> setOfDates = new Set<Date>();
            setOfDates.add(tr.RICSC_TransactionDate__c);
            if(uniqueSATransactionDates.get(tr.RICSC_SalesAssociate__c) != null){
              setOfDates.addAll(uniqueSATransactionDates.get(tr.RICSC_SalesAssociate__c));
            }
            uniqueSATransactionDates.put(tr.RICSC_SalesAssociate__c,setOfDates);
            frequencyXsaId.put(tr.RICSC_SalesAssociate__c, uniqueSATransactionDates.get(tr.RICSC_SalesAssociate__c).size());
          }

          if(tr.RICSC_TransactionCategory__c == UtilityConstants.TRANSACTION_TYPE_RETURN && tr.RICSC_AmountWithTaxEUR__c > 0){
            turnoverXsaId.put(tr.RICSC_SalesAssociate__c, turnoverXsaId.get(tr.RICSC_SalesAssociate__c) - tr.RICSC_AmountWithTaxEUR__c);
          }else{
            turnoverXsaId.put(tr.RICSC_SalesAssociate__c, turnoverXsaId.get(tr.RICSC_SalesAssociate__c) + tr.RICSC_AmountWithTaxEUR__c);
          }
        }

        if(tr.RICSC_Boutique__c != null && tr.RICSC_Boutique__r.RICSC_Localisation__c != null && tr.RICSC_AmountWithTaxEUR__c != null && tr.RICSC_TransactionCategory__c != UtilityConstants.TRANSACTION_TYPE_REPAIR){
          // Top 1 , 2 , 3 Market Fix
          if(frequencyXmarketName.get((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Name) == null){
            frequencyXmarketName.put((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Name, 0);
            turnoverXmarketName.put((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Name, 0.00);
            uniqueMarketTransactionDates.put((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Name, new Set<Date>());
          }

          if(tr.RICSC_AmountWithTaxEUR__c != 0 && tr.RICSC_TransactionCategory__c != UtilityConstants.TRANSACTION_TYPE_RETURN){
            Set<Date> setOfDates = new Set<Date>();
            setOfDates.add(tr.RICSC_TransactionDate__c);
            if(uniqueMarketTransactionDates.get((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Name) != null){
              setOfDates.addAll(uniqueMarketTransactionDates.get((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Name));
            }
            uniqueMarketTransactionDates.put((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Name,setOfDates);
            frequencyXmarketName.put((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Name, uniqueMarketTransactionDates.get((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Name).size());
          }

          if(tr.RICSC_TransactionCategory__c == UtilityConstants.TRANSACTION_TYPE_RETURN && tr.RICSC_AmountWithTaxEUR__c > 0){
            turnoverXmarketName.put((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Name, turnoverXmarketName.get((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Name) - tr.RICSC_AmountWithTaxEUR__c);
          }else{
            turnoverXmarketName.put((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Name, turnoverXmarketName.get((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Name) + tr.RICSC_AmountWithTaxEUR__c);
          }

          // Top 1 , 2 , 3 Region Fix
          if((accRecType == UtilityConstants.PERSON_ACCOUNT_CAR_RT_ID || accRecType == UtilityConstants.PERSON_ACCOUNT_JLC_RT_ID)){
            if(frequencyXregionName.get((Utility.getLocalisationParent((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Id)).Name) == null){
              frequencyXregionName.put((Utility.getLocalisationParent((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Id)).Name, 0);
              turnoverXregionName.put((Utility.getLocalisationParent((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Id)).Name, 0.00);
              uniqueRegionTransactionDates.put((Utility.getLocalisationParent((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Id)).Name, new Set<Date>());
            }

            if(tr.RICSC_AmountWithTaxEUR__c != 0 && tr.RICSC_TransactionCategory__c != UtilityConstants.TRANSACTION_TYPE_RETURN){
              Set<Date> setOfDates = new Set<Date>();
              setOfDates.add(tr.RICSC_TransactionDate__c);
              if(uniqueRegionTransactionDates.get((Utility.getLocalisationParent((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Id)).Name) != null){
                setOfDates.addAll(uniqueRegionTransactionDates.get((Utility.getLocalisationParent((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Id)).Name));
              }
              uniqueRegionTransactionDates.put((Utility.getLocalisationParent((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Id)).Name,setOfDates);
              frequencyXregionName.put((Utility.getLocalisationParent((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Id)).Name, uniqueRegionTransactionDates.get((Utility.getLocalisationParent((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Id)).Name).size());
            }

            if(tr.RICSC_TransactionCategory__c == UtilityConstants.TRANSACTION_TYPE_RETURN && tr.RICSC_AmountWithTaxEUR__c > 0){
              turnoverXregionName.put((Utility.getLocalisationParent((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Id)).Name, turnoverXregionName.get((Utility.getLocalisationParent((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Id)).Name) - tr.RICSC_AmountWithTaxEUR__c);
            }else{
              turnoverXregionName.put((Utility.getLocalisationParent((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Id)).Name, turnoverXregionName.get((Utility.getLocalisationParent((Utility.getLocalisationParent(boutiquesLocalisations.get(tr.RICSC_Boutique__c))).Id)).Name) + tr.RICSC_AmountWithTaxEUR__c);
            }
          }
        }
      }
    }

    updatedAcc.RICSC_LastTransactionDate__c = lastTransactionDate;
    updatedAcc.RICSC_FirstTransactionDate__c = firstTransactionDate;
    updatedAcc.RICSC_LastPurchaseMarket__c = lastPurchaseMarket;
    updatedAcc.RICSC_LastPurchaseBoutique__c = lastPurchaseBoutique;
    updatedAcc.RICSC_HighJeweleryTurnover__c = highJewSum;
    updatedAcc.RICSC_HighJeweleryPieces__c = highJewCount;
    updatedAcc.RICSC_HighestJeweleryTicket__c = highJewMax;
    updatedAcc.RICSC_TotalTurnoverRepairs__c = turnoverOfRepairs;
    updatedAcc.RICSC_TotalTurnoverSales__c = turnoverOfSales + turnoverOfReturns;
    updatedAcc.RICSC_Turnover__c = turnover;
    updatedAcc.RICSC_TransactionChannelsSelected__c = String.join(new List<String>(salesChannelVariety), ';');

    if(counter != 0){
      updatedAcc.RICSC_AverageBasket__c = (Double)(sum/counter);
    }else{
      updatedAcc.RICSC_AverageBasket__c = 0;
    }

    if(isGoldenRecordWithLocalRecords){
      updatedAcc.RICSC_FirstSalesDate__c = hasSalesDate ? firstSalesDate : null;
      updatedAcc.RICSC_LastSalesDate__c = hasSalesDate ? lastSalesDate : null;
      updatedAcc.RICSC_TotalNumberOfRepairs__c = numberOfRepairs;
      updatedAcc.RICSC_TotalNumberOfSales__c = numberOfSales;
      List<Utility.Pair> topRatedSA = Utility.sortPairsList(Utility.mapToListOfPairs(Utility.getResultMapValuesMultiplied(frequencyXsaId,turnoverXsaId)));
      updatedAcc.RICSC_ReferenceSA__c = topRatedSA.size() > 0 ? topRatedSA.get(topRatedSA.size()-1).key : null;
    }

    if(isGoldenRecordWithLocalRecords || isGoldenLocal){
      List<Utility.Pair> topRatedMarkets = Utility.sortPairsList(Utility.mapToListOfPairs(Utility.getResultMapValuesMultiplied(frequencyXmarketName,turnoverXmarketName)));
      List<Utility.Pair> topRatedBoutiques = Utility.sortPairsList(Utility.mapToListOfPairs(Utility.getResultMapValuesMultiplied(frequencyXBoutiqueId,turnoverXBoutiqueId)));
      List<Utility.Pair> topRatedSA = Utility.sortPairsList(Utility.mapToListOfPairs(Utility.getResultMapValuesMultiplied(frequencyXsaId,turnoverXsaId)));

      updatedAcc.RICSC_Top1Market__c = topRatedMarkets.size() > 0 ? topRatedMarkets.get(topRatedMarkets.size()-1).key : null;
      updatedAcc.RICSC_Top2Market__c = topRatedMarkets.size() > 1 ? topRatedMarkets.get(topRatedMarkets.size()-2).key : null;
      updatedAcc.RICSC_Top3Market__c = topRatedMarkets.size() > 2 ? topRatedMarkets.get(topRatedMarkets.size()-3).key : null;

      updatedAcc.RICSC_Top1Boutique__c = topRatedBoutiques.size() > 0 ? topRatedBoutiques.get(topRatedBoutiques.size()-1).key : null;
      updatedAcc.RICSC_Top2Boutique__c = topRatedBoutiques.size() > 1 ? topRatedBoutiques.get(topRatedBoutiques.size()-2).key : null;
      updatedAcc.RICSC_Top3Boutique__c = topRatedBoutiques.size() > 2 ? topRatedBoutiques.get(topRatedBoutiques.size()-3).key : null;

      updatedAcc.RICSC_Top1SA__c = topRatedSA.size() > 0 ? topRatedSA.get(topRatedSA.size()-1).key : null;
      updatedAcc.RICSC_Top2SA__c = topRatedSA.size() > 1 ? topRatedSA.get(topRatedSA.size()-2).key : null;
      updatedAcc.RICSC_Top3SA__c = topRatedSA.size() > 2 ? topRatedSA.get(topRatedSA.size()-3).key : null;

      if((accRecType == UtilityConstants.PERSON_ACCOUNT_CAR_RT_ID || accRecType == UtilityConstants.PERSON_ACCOUNT_JLC_RT_ID)){
        List<Utility.Pair> topRatedRegions = Utility.sortPairsList(Utility.mapToListOfPairs(Utility.getResultMapValuesMultiplied(frequencyXregionName,turnoverXregionName)));

        if(!isGoldenLocal){
          updatedAcc.RICSC_ReferenceBoutique__c = updatedAcc.RICSC_Top1Boutique__c;
        }

        updatedAcc.RICSC_ReferenceMarket__c = updatedAcc.RICSC_Top1Market__c;
        updatedAcc.RICSC_ReferenceRegion__c = topRatedRegions.size() > 0 ? topRatedRegions.get(topRatedRegions.size()-1).key : null;
      }else if(updatedAcc.RICSC_ReferenceSA__c != null){

        if(!isGoldenLocal){
          updatedAcc.RICSC_ReferenceBoutique__c = boutiqueXsalesAssociate.get(updatedAcc.RICSC_ReferenceSA__c);
        }
        if(updatedAcc.RICSC_ReferenceBoutique__c != null && boutiquesLocalisations.get(updatedAcc.RICSC_ReferenceBoutique__c) != null){
          updatedAcc.RICSC_ReferenceMarket__c = Utility.getLocalisationParent(boutiquesLocalisations.get(updatedAcc.RICSC_ReferenceBoutique__c)).Name;
          updatedAcc.RICSC_ReferenceRegion__c = Utility.getLocalisationParent(Utility.getLocalisationParent(boutiquesLocalisations.get(updatedAcc.RICSC_ReferenceBoutique__c)).Id).Name;
        }
      }
    }

    return updatedAcc;
  }

  public static void computeConcatenatedFieldsOnGR(Set<Id> accIds, Map<Id,CalculatedAccountFieldCont> workingMap){
    List<Account> accList = new List<Account>();
    if (Schema.sObjectType.Account.isAccessible()){
      accList = [SELECT Id, RICSC_GoldenRecord__c,
                                    RecordTypeId,RICSC_ECard__c,
                                    RICSC_Notes__c,RICSC_SpotNotes__c,RICSC_ProductOfInterests__c,
                                    RICSC_CollectionOfInterests__c,RICSC_Hobbies__c,RICSC_LocalVIP__c,RICSC_VIP__c
                             FROM Account
                             WHERE RICSC_GoldenRecord__c IN:accIds];
    }
    Map<Id,Set<Account>> accountsXAccountG = new Map<Id,Set<Account>>();

    for(Account acc : accList){

      if(acc.RICSC_GoldenRecord__c != null){
        if(!accountsXAccountG.containsKey(acc.RICSC_GoldenRecord__c)){
          accountsXAccountG.put(acc.RICSC_GoldenRecord__c, new Set<Account>());
        }
        accountsXAccountG.get(acc.RICSC_GoldenRecord__c).add(acc);

        CalculatedAccountFieldCont cafc;
        if(!workingMap.containsKey(acc.RICSC_GoldenRecord__c)){
          cafc = new CalculatedAccountFieldCont(acc.RICSC_GoldenRecord__c);
          workingMap.put(acc.RICSC_GoldenRecord__c, cafc);
        }
        cafc = workingMap.get(acc.RICSC_GoldenRecord__c);
        cafc.processConcatFields = true;
      }
    }

    for(String accId : accountsXAccountG.keySet()){
      populateConcatValues(accountsXAccountG.get(accId),workingMap.get(accId),accId);
    }
  }

  public static void populateConcatValues(Set<Account> accountSet,CalculatedAccountFieldCont cont, String accId){
    for(Account ac : AccountSet){
      if(ac.RICSC_Notes__c != null){
          cont.notes = cont.notes +' '+ ac.RICSC_Notes__c;
        }
      if(ac.RICSC_SpotNotes__c != null){
          cont.spotNotes = cont.spotNotes +' '+ ac.RICSC_SpotNotes__c;
      }
      if(ac.RICSC_ECard__c == true){
          cont.ecard = true;
      }
      if(ac.RICSC_CollectionOfInterests__c != null){
        for (String temp : ac.RICSC_CollectionOfInterests__c.split(';')){
          cont.collectionOfInterests.add(temp);
        }
      }
      if(ac.RICSC_ProductOfInterests__c != null){
        for (String temp : ac.RICSC_ProductOfInterests__c.split(';')){
          cont.productOfInterests.add(temp);
        }
      }
      if(ac.RICSC_Hobbies__c != null){
        for (String temp : ac.RICSC_Hobbies__c.split(';')){
          cont.hobbies.add(temp);
        }
      }
      if(ac.RICSC_VIP__c == true){
          cont.localvip = true;
      }
    }
  }

  public static void computeVipFlag(Set<Account> changedAccs, Map<Id,CalculatingFieldsHandler.CalculatedAccountFieldCont> workingMap){

    for(Account tempAcc : changedAccs){
      Boolean setVip = false;
      if((tempAcc.RecordTypeId == RecordTypeHelper.getRTId('Account',UtilityConstants.PERSON_ACCOUNT_VCA_RT) && (tempAcc.RICSC_Turnover__c >= 200000 || UtilityConstants.CLIENT_FLAG_VIP_SET.contains(tempAcc.RICSC_ClientFlag__c))) ||
          (tempAcc.RecordTypeId == RecordTypeHelper.getRTId('Account',UtilityConstants.PERSON_ACCOUNT_JLC_RT) && tempAcc.RICSC_Turnover__c >= 150000) ||
          (tempAcc.RecordTypeId == RecordTypeHelper.getRTId('Account',UtilityConstants.PERSON_ACCOUNT_CAR_RT) && (tempAcc.RICSC_GlobalSegment__c == UtilityConstants.GLOBAL_SEGMENT_VIP || tempAcc.RICSC_GlobalSegment__c == UtilityConstants.GLOBAL_SEGMENT_TOP_VIP))
        ){

        setVip = true;
      }

      if(setVip!=tempAcc.RICSC_Vip__c){
        CalculatedAccountFieldCont cafc;
        if(!workingMap.containsKey(tempAcc.Id)){
          cafc = new CalculatedAccountFieldCont(tempAcc.Id);
          workingMap.put(tempAcc.Id, cafc);
        }

        cafc = workingMap.get(tempAcc.Id);
        cafc.processVipFlag = true;
        cafc.vip = setVip;
      }
    }
  }

  /******************************************************************************
  * @author       Piergiorgio Lisanti
  * @date         17/Oct/2019
  * @description  Computes ResidenceNonResidence (and optionally also ResidencyType)
  *               fields on the set of accounts accIds based on related addresses (and transactions)
  *               linked to the accounts through the 'lookupName' lookup field
  * @return       accountsToBeUpdated, list of accounts ready to be updated
  ******************************************************************************/
  public static List<Account> computeResidenceNonResidence(Set<Id> accIds,String lookUpName, Boolean computeResType){

    String transactionlookup = (lookUpName == 'RICSC_GR__c') ? 'RICSC_GoldenRecord__c' : 'RICSC_Account__c';

    List<RICSC_Address__c> addressList = Database.query(' SELECT Id,'+lookUpName+',RICSC_AddressType__c,RICSC_Country__c '+
                                                        ' FROM RICSC_Address__c '+
                                                        ' WHERE RICSC_AddressType__c = \'Residency\' AND '+lookUpName +
                                                        ' IN :accIds');

    List<RICSC_Transaction__c> transactionList = Database.query(' SELECT Id,'+transactionlookup+',RICSC_CountryOfOrigin__c '+
                                                                ' FROM RICSC_Transaction__c '+
                                                                ' WHERE '+transactionlookup +
                                                                ' IN :accIds');

    List<Account> accountsToBeUpdated = new List<Account>();

    Map<Id, Set<String>> transCountriesXaccId = new Map<Id, Set<String>>();
    Map<Id, Set<String>> addrCountriesXaccId = new Map<Id, Set<String>>();

    for(RICSC_Transaction__c trans : transactionList){
      if(transCountriesXaccId.get(String.valueOf(trans.get(transactionlookup))) == null){
        transCountriesXaccId.put(String.valueOf(trans.get(transactionlookup)),new Set<String>());
      }
      if(String.isNotBlank(trans.RICSC_CountryOfOrigin__c)){
        transCountriesXaccId.get(String.valueOf(trans.get(transactionlookup))).add(trans.RICSC_CountryOfOrigin__c);
      }
    }

    for(RICSC_Address__c addr : addressList){
      if(addrCountriesXaccId.get(String.valueOf(addr.get(lookUpName))) == null){
        addrCountriesXaccId.put(String.valueOf(addr.get(lookUpName)),new Set<String>());
      }
      if(String.isNotBlank(addr.RICSC_Country__c)){
        addrCountriesXaccId.get(String.valueOf(addr.get(lookUpName))).add(addr.RICSC_Country__c);
      }
    }

    for(Id accId : accIds){
      if(transCountriesXaccId.get(accId) == null){
        transCountriesXaccId.put(accId,new Set<String>());
      }
      if(addrCountriesXaccId.get(accId) == null){
        addrCountriesXaccId.put(accId,new Set<String>());
      }

      Account accToUpdate = new Account(Id = accId);
      if(transCountriesXaccId.get(accId).equals(addrCountriesXaccId.get(accId)) ||
        addrCountriesXaccId.get(accId).containsAll(transCountriesXaccId.get(accId))
      ){
        accToUpdate.put('RICSC_ResidentNonResident__c','Resident');
      } else {
        Set<String> transCountriesInResidencyOnly = new Set<String>(transCountriesXaccId.get(accId));
        transCountriesInResidencyOnly.retainAll(addrCountriesXaccId.get(accId));
        if(transCountriesXaccId.get(accId).size() > 0 && transCountriesInResidencyOnly.size() == 0){

          accToUpdate.put('RICSC_ResidentNonResident__c','Non-Resident');
        } else {
          accToUpdate.put('RICSC_ResidentNonResident__c','Traveller');
        }
      }

      if(computeResType){
        if(addrCountriesXaccId.get(accId).size() == 0){
          accToUpdate.put('RICSC_ResidencyType__c',null);
        }
        else if(addrCountriesXaccId.get(accId).size() == 1){
          accToUpdate.put('RICSC_ResidencyType__c','Mono-Residency');
        }
        else{
          accToUpdate.put('RICSC_ResidencyType__c','Multi-Residency');
        }
      }

      accountsToBeUpdated.add(accToUpdate);

    }

    return accountsToBeUpdated;
  }


  public static void setDefaultRecordForObject(String objectName,String parentChildRelationShip,Set<Id> goldenRecordIds,String checkBoxFieldNameLR,String checkBoxFieldNameGR){

    String query = 'SELECT id,RICSC_HasLocalRecords__c,(SELECT id,Name,'+checkBoxFieldNameLR+','+checkBoxFieldNameGR+',RICSC_Account__c,LastModifiedDate FROM '+parentChildRelationShip+' ORDER BY RICSC_Account__r.RICSC_MasterRecordScore__c DESC) FROM Account WHERE Id IN : goldenRecordIds';
    List<Account> relatedAccountSObjectList = Database.query(query);
    Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
    Set<SObject> sObjectsToBeUpdated = new Set<SObject>();


    for(Account currentRelatedAccount : relatedAccountSObjectList){

      SObject defaultRecord = sObjectType.newSObject();
      Id highestScoreAccount = null;
      Datetime maxModifiedDate = Datetime.newInstance(1920, 9, 15, 12, 30, 0);
      Boolean hasDefaultRecord = false;

      //Gets the highest Score Account with related records
      if(highestScoreAccount == null && currentRelatedAccount.getSObjects(parentChildRelationShip) != null){
        //i am using 0 index because anyway all the related records for the current local account has the same account id
        highestScoreAccount = currentRelatedAccount.getSObjects(parentChildRelationShip).get(0).get('RICSC_Account__c').toString();
      }

      //in this loop i am making all related emails,addresses etc goldenRecord checkbox to false
      //the if statement on the outter of the loop determins if the current account has any email
      //so in case the default record goes to the next lower from the highest account

      if(currentRelatedAccount.getSObjects(parentChildRelationShip) != null){

        //this is in case the highest score account has a default checkbox on his local records
        for(SObject currentRelatedSObject :  (List<SObject>) currentRelatedAccount.getSObjects(parentChildRelationShip)){
          if(highestScoreAccount == currentRelatedSObject.get('RICSC_Account__c') && currentRelatedSObject.get(checkBoxFieldNameLR) != false){
            defaultRecord = currentRelatedSObject;
            hasDefaultRecord = true;
          }
          currentRelatedSObject.put(checkBoxFieldNameGR,false);
          sObjectsToBeUpdated.add(currentRelatedSObject);
        }

        //this is the case that if the default checkbox is false
        if(hasDefaultRecord == false){
          for(SObject currentRelatedSObject : (List<SObject>)currentRelatedAccount.getSObjects(parentChildRelationShip)){
            if(highestScoreAccount == currentRelatedSObject.get('RICSC_Account__c') && DateTime.valueOf(currentRelatedSObject.get('LastModifiedDate')) > maxModifiedDate){
              maxModifiedDate = DateTime.valueOf(currentRelatedSObject.get('LastModifiedDate'));
              defaultRecord = currentRelatedSObject;
            }
          }
        }

        // here i am deleted the email with the flag false that got imported from the previus loop because there were no default emails
        // so that email was last modified so got the true flag
        defaultRecord.put(checkBoxFieldNameGR,false);
        sObjectsToBeUpdated.remove(defaultRecord);
        defaultRecord.put(checkBoxFieldNameGR,true);
        if(hasDefaultRecord == false && currentRelatedAccount.RICSC_HasLocalRecords__c == false){
          defaultRecord.put(checkBoxFieldNameLR,true);
        }
        sObjectsToBeUpdated.add(defaultRecord);
      }
    }

    if(sObjectsToBeUpdated.size()>0){
      TRG_TriggerDispatcher.skipTriggerMap.put(objectName,true);
      Boolean allOrNone = Utility.isAsync() ? false : true;
      Database.SaveResult[] srList = Database.update(new List<SObject>(sObjectsToBeUpdated),allOrNone);
      if(Utility.isAsync()){
        UtilityLogger.logAllErrors(srList, false, 'DefaultRecord For '+sObjectType,'execute');
      }
      TRG_TriggerDispatcher.skipTriggerMap.put(objectName,false);
    }
  }

  /******************************************************************************
  * @author       Silvan Sholla
  * @date         21/Nov/2019
  * @description
  *               Class code caclulation based on the channel of the related
  *               transactions also based on if the related asset has the
  *               tranasctionId field poppulated
  * @return       Account , that got updated based on the following contitions
                  In case its called from asset, On the other hand if the method
                  is called from account its getting updated without dmls be
                  because the trigger is before update
  ******************************************************************************/
   public static Account calculateClassCode(Account accToBeUpdated){
    Double totalNumberOfRepairs = (accToBeUpdated.RICSC_TotalNumberOfRepairs__c == null)?0:accToBeUpdated.RICSC_TotalNumberOfRepairs__c;
    Double totalNumberOfSales = (accToBeUpdated.RICSC_TotalNumberOfSales__c == null)?0:accToBeUpdated.RICSC_TotalNumberOfSales__c;
    Double totalNumberOfTransactions = totalNumberOfRepairs + totalNumberOfSales;
    if(totalNumberOfTransactions == 0){
      if(accToBeUpdated.RICSC_ClassCode__c != UtilityConstants.CLASS_CODE_WHLSL){
        accToBeUpdated.RICSC_ClassCode__c = UtilityConstants.CLASS_CODE_PROSP;
      }
    } else {
      // Yes , No
      if(accToBeUpdated.RICSC_TotalNumberOfSales__c == 0 && accToBeUpdated.RICSC_TransactionChannelsSelected__c == null){
        accToBeUpdated.RICSC_ClassCode__c = UtilityConstants.CLASS_CODE_SCLNT;
      // Yes , Yes
      }else if(accToBeUpdated.RICSC_TransactionChannelsSelected__c != null && accToBeUpdated.RICSC_TotalNumberOfSales__c != 0){
        // Yes , Yes , Boutique
        if(accToBeUpdated.RICSC_TransactionChannelsSelected__c.contains(UtilityConstants.TRANSACTION_CHANNEL_BOUTIQUE) && accToBeUpdated.RICSC_TransactionChannelsSelected__c.split(';').size() == 1){
          accToBeUpdated.RICSC_ClassCode__c = UtilityConstants.CLASS_CODE_RCLNT;
        }
        // Yes , Yes , CC
        else if(accToBeUpdated.RICSC_TransactionChannelsSelected__c.contains(UtilityConstants.TRANSACTION_CHANNEL_CC) && accToBeUpdated.RICSC_TransactionChannelsSelected__c.split(';').size() == 1){
          accToBeUpdated.RICSC_ClassCode__c = UtilityConstants.CLASS_CODE_CCLNT;
        }
        // Yes , Yes , Web
        else if(accToBeUpdated.RICSC_TransactionChannelsSelected__c.contains(UtilityConstants.TRANSACTION_CHANNEL_WEB) && accToBeUpdated.RICSC_TransactionChannelsSelected__c.split(';').size() == 1){
          accToBeUpdated.RICSC_ClassCode__c = UtilityConstants.CLASS_CODE_WCLNT;
        }
        // Yes , Yes , Web , CC
        else if(accToBeUpdated.RICSC_TransactionChannelsSelected__c.contains(UtilityConstants.TRANSACTION_CHANNEL_WEB) && accToBeUpdated.RICSC_TransactionChannelsSelected__c.contains(UtilityConstants.TRANSACTION_CHANNEL_CC) && accToBeUpdated.RICSC_TransactionChannelsSelected__c.split(';').size() == 2){
          accToBeUpdated.RICSC_ClassCode__c = UtilityConstants.CLASS_CODE_ECOM;
        }
          // Yes , Yes , Boutique , Wholesaler , ...
        else if(accToBeUpdated.RICSC_TransactionChannelsSelected__c.contains(UtilityConstants.TRANSACTION_CHANNEL_BOUTIQUE) && accToBeUpdated.RICSC_TransactionChannelsSelected__c.contains(UtilityConstants.TRANSACTION_CHANNEL_WHOLESALER) && accToBeUpdated.RICSC_TransactionChannelsSelected__c.split(';').size() >= 2){
          accToBeUpdated.RICSC_ClassCode__c = UtilityConstants.CLASS_CODE_MCLNT;
        }
          // Yes , Yes , Boutique , CC , ...
        else if(accToBeUpdated.RICSC_TransactionChannelsSelected__c.contains(UtilityConstants.TRANSACTION_CHANNEL_BOUTIQUE) && accToBeUpdated.RICSC_TransactionChannelsSelected__c.contains(UtilityConstants.TRANSACTION_CHANNEL_CC) && accToBeUpdated.RICSC_TransactionChannelsSelected__c.split(';').size() >= 2){
          accToBeUpdated.RICSC_ClassCode__c = UtilityConstants.CLASS_CODE_MCLNT;
        }
          // Yes , Yes , Boutique , WEB , ...
        else if(accToBeUpdated.RICSC_TransactionChannelsSelected__c.contains(UtilityConstants.TRANSACTION_CHANNEL_BOUTIQUE) && accToBeUpdated.RICSC_TransactionChannelsSelected__c.contains(UtilityConstants.TRANSACTION_CHANNEL_WEB) && accToBeUpdated.RICSC_TransactionChannelsSelected__c.split(';').size() >= 2){
          accToBeUpdated.RICSC_ClassCode__c = UtilityConstants.CLASS_CODE_MCLNT;
        }
        // Yes , Yes , Charity , ...
        else if(accToBeUpdated.RICSC_TransactionChannelsSelected__c.contains(UtilityConstants.TRANSACTION_CHANNEL_CHARITY)  && accToBeUpdated.RICSC_TransactionChannelsSelected__c.split(';').size() == 1){
          accToBeUpdated.RICSC_ClassCode__c = UtilityConstants.CLASS_CODE_CHARY;
        }
        // all the other combos with more than two channels are multichanel
        else if(accToBeUpdated.RICSC_TransactionChannelsSelected__c.split(';').size() >= 2){
          accToBeUpdated.RICSC_ClassCode__c = UtilityConstants.CLASS_CODE_MCLNT;
        //all the remaining combos
        }else{
          accToBeUpdated.RICSC_ClassCode__c = '';
        }
      }else{
        accToBeUpdated.RICSC_ClassCode__c = '';
      }
    }
    return accToBeUpdated;
  }

 public static List<Account> referenceMarketCalculation(Set<Id> relatedAccounts){
   List<Account> accList = [SELECT RICSC_ReferenceBoutique__r.RICSC_Localisation__c FROM Account WHERE Id IN :relatedAccounts];
   List<Account> accToBeUpdated = new List<Account>();
   for(Account acc : accList){
    if(acc.RICSC_ReferenceBoutique__r.RICSC_Localisation__c != null){
      acc.RICSC_ReferenceMarket__c = Utility.getLocalisationParent(acc.RICSC_ReferenceBoutique__r.RICSC_Localisation__c).Name;
      acc.RICSC_ReferenceRegion__c = Utility.getLocalisationParent(Utility.getLocalisationParent(acc.RICSC_ReferenceBoutique__r.RICSC_Localisation__c).Id).Name;
    }else{
      acc.RICSC_ReferenceMarket__c = null;
      acc.RICSC_ReferenceRegion__c = null;
    }
    accToBeUpdated.add(acc);
   }
   return accToBeUpdated;
 }
}