/******************************************************************************
* @author       Luigi Giuliani
* @date         15/10/2019
* @description  This utility class contains utility method specifically related
                to the Account object.
******************************************************************************/
public without sharing class UtilityAccount {

    public class AlignConsentException extends Exception {}

    /* GENERIC UTILITY METHODS - START */

    /****************************************************************************************************************************
    @author       Maurizio D'Antonio
    @date         16/Oct/2019
    @description  Method used to calculate Account's segment based on its transactions
    @param GRIds  Ids of the golden records to whom calculate the segment
    *****************************************************************************************************************************/
    public static void calculateSegment(Set<Id> gRIds, Boolean allOrNone, Boolean skipTriggersOnAccount){
    List<Account> accountsToUpdate = new List<Account>();
    List<RICSC_Transaction__c> transactions = new List<RICSC_Transaction__c>();
    if (!Schema.sObjectType.RICSC_Transaction__c.fields.Name.isUpdateable()) {
      transactions = [SELECT Id, RICSC_Account__c, RICSC_AmountWithTaxEUR__c, RICSC_TransactionDate__c, RICSC_ProductName__c, RICSC_ProductName__r.RICSC_TechnicalProductType__c, RICSC_ProductName__r.RICSC_TechnicalProductSegment__c,RICSC_ProductName__r.RICSC_OrganizationCode__c, RICSC_ProductName__r.RICSC_TechnicalCollectionProductLine__c, RICSC_ProductName__r.RICSC_TechnicalProductFamily__c, RICSC_ProductName__r.RICSC_ArticleType__c, RICSC_GoldenRecord__c, RICSC_GoldenRecord__r.RecordType.DeveloperName, RICSC_TransactionCategory__c, RICSC_Maison__c FROM RICSC_Transaction__c WHERE RICSC_GoldenRecord__c IN :GRIds OR RICSC_Account__c IN :GRIds];
    }
    List<Account> grAccounts = new List<Account>();
    grAccounts = [SELECT Id, RICSC_GlobalSegment__c, RICSC_ClientSegment__c, RICSC_FirstSalesDate__c, RICSC_Potential__c, RecordType.DeveloperName, RICSC_CARSleepingVIP__c, RICSC_CARSleepingNonVIP__c, RICSC_JLCInactiveClient__c, RICSC_VCAFormerStar__c, RICSC_HasLocalRecords__c FROM Account WHERE Id IN :GRIds];
    Map<Id, List<RICSC_Transaction__c>> grIdToTransactionsList = new Map<Id, List<RICSC_Transaction__c>>();
    Map<Id, Decimal> grIdToTotalTurnover = new Map<Id, Decimal>();
    for(RICSC_Transaction__c tr : transactions){
      Id grId = tr.RICSC_GoldenRecord__c != null ? tr.RICSC_GoldenRecord__c : tr.RICSC_Account__c;
      if(!GRIdToTransactionsList.containsKey(GRId)){
        GRIdToTransactionsList.put(GRId, new List<RICSC_Transaction__c>());
      }
      if(!GRIdToTotalTurnover.containsKey(GRId)) {
        GRIdToTotalTurnover.put(GRId, 0);
      }
      List<RICSC_Transaction__c> trList = GRIdToTransactionsList.get(GRId);
      trList.add(tr);
      GRIdToTransactionsList.put(GRId, trList);

      Decimal turnover = GRIdToTotalTurnover.get(GRId);
      if (tr.RICSC_AmountWithTaxEUR__c == null){
        tr.RICSC_AmountWithTaxEUR__c = 0;
      }
      turnover = turnover + tr.RICSC_AmountWithTaxEUR__c;
      GRIdToTotalTurnover.put(GRId, turnover);
    }

    List<GlobalSegmentConfTable__mdt> mdtList = Utility.getGlobalSegmentConfTable();
    for(Account a : grAccounts){
      if(a.RICSC_HasLocalRecords__c){
        Map<String, Decimal> rangeToTurnover = new Map<String,Decimal>();
        Map<String, Integer> rangeToFrequency = new Map<String,Integer>();
        Map<String, Integer> rangeToRecency = new Map<String,Integer>();
        Map<String, List<String>> rangeToHighestTurnoverGroupList = new Map<String, List<String>>();
        Decimal totalTurnover = GRIdToTotalTurnover.get(a.Id);
        Integer firstSale = (a.RICSC_FirstSalesDate__c != null && a.RICSC_FirstSalesDate__c.monthsBetween(Date.today()) != null) ? a.RICSC_FirstSalesDate__c.monthsBetween(Date.today()) : -1;
        String segment = '';
        String potential = a.RICSC_Potential__c;
        for(Integer i=0; i<mdtList.size() && segment.equals(''); i++){
          GlobalSegmentConfTable__mdt mdt = mdtList.get(i);
          if(mdt.Flag__c == null && mdt.Maison__c.equalsIgnoreCase(a.RecordType.DeveloperName)){
            String range = mdt.RangeForTotalTurnoverFrom__c + '-' + mdt.RangeForTotalTurnoverTo__c;
            List<String> highestTurnoverGroupList = new List<String>();
            List<RICSC_Transaction__c> transactionsList = GRIdToTransactionsList.get(a.Id) != null ? GRIdToTransactionsList.get(a.Id) : new List<RICSC_Transaction__c>();
            if(!rangeToTurnover.containsKey(range)){
              updateRangeMaps(transactionsList, rangeToTurnover, rangeToRecency, rangeToFrequency, rangeToHighestTurnoverGroupList, range);
            }
            Decimal rangeTurnover = rangeToTurnover.get(range);
            Integer rangeRecency = rangeToRecency.get(range);
            Integer rangeFrequency = rangeToFrequency.get(range);
            highestTurnoverGroupList = rangeToHighestTurnoverGroupList.get(range);
            if(mdt.ProductParameterToInclude__c != null || mdt.ProductParameterToExclude__c != null){
              segment = getSegmentIfMatch(mdt, totalTurnover, rangeTurnover, rangeRecency, rangeFrequency, firstSale, potential, highestTurnoverGroupList, mdt.ProductParameterToInclude__c, mdt.ProductParameterToExclude__c, transactionsList);
            }
            else{
              segment = getSegmentIfMatch(mdt, totalTurnover, rangeTurnover, rangeRecency, rangeFrequency, firstSale, potential, highestTurnoverGroupList, null, null, transactionsList);
            }
          }
        }
        a.RICSC_GlobalSegment__c = segment;
        boolean flagSet = false;
        for(Integer i=0; i<mdtList.size() && !flagSet; i++){
          GlobalSegmentConfTable__mdt mdt = mdtList.get(i);
          if(mdt.Flag__c != null && mdt.Maison__c.equalsIgnoreCase(a.RecordType.DeveloperName)){
            String range = mdt.RangeForTotalTurnoverFrom__c + '-' + mdt.RangeForTotalTurnoverTo__c;
            List<String> highestTurnoverGroupList = new List<String>();
            List<RICSC_Transaction__c> transactionsList = GRIdToTransactionsList.get(a.Id) != null ? GRIdToTransactionsList.get(a.Id) : new List<RICSC_Transaction__c>();
            if(!rangeToTurnover.containsKey(range)){
              updateRangeMaps(transactionsList, rangeToTurnover, rangeToRecency, rangeToFrequency, rangeToHighestTurnoverGroupList, range);
            }
            Decimal rangeTurnover = rangeToTurnover.get(range);
            Integer rangeRecency = rangeToRecency.get(range);
            Integer rangeFrequency = rangeToFrequency.get(range);
            highestTurnoverGroupList = rangeToHighestTurnoverGroupList.get(range);
            if(mdt.ProductParameterToInclude__c != null || mdt.ProductParameterToExclude__c != null){
              segment = getSegmentIfMatch(mdt, totalTurnover, rangeTurnover, rangeRecency, rangeFrequency, firstSale, potential, highestTurnoverGroupList, mdt.ProductParameterToInclude__c, mdt.ProductParameterToExclude__c, transactionsList);
            }
            else{
              segment = getSegmentIfMatch(mdt, totalTurnover, rangeTurnover, rangeRecency, rangeFrequency, firstSale, potential, highestTurnoverGroupList, null, null, transactionsList);
            }
            if(!segment.equals('')){
              a.put(mdt.Flag__c, true);
              flagSet = true;
            }
            else{
              a.put(mdt.Flag__c, false);
            }
          }
        }
      }
      else{
        a.RICSC_GlobalSegment__c = a.RICSC_ClientSegment__c;
      }
      accountsToUpdate.add(a);
    }
    if(skipTriggersOnAccount){
      TRG_TriggerDispatcher.skipTriggerMap.put('Account',true);
    }
    Database.SaveResult[] srList = Database.update(accountsToUpdate, allOrNone);
    if(!allOrNone){
      UtilityLogger.logAllErrors(srList, false, 'UtilityAccount', 'calculateSegment');
    }
    if(skipTriggersOnAccount){
      TRG_TriggerDispatcher.skipTriggerMap.put('Account',false);
    }
  }

  public static void updateRangeMaps(List<RICSC_Transaction__c> transactionsList, Map<String, Decimal> rangeToTurnover, Map<String, Integer> rangeToRecency, Map<String, Integer> rangeToFrequency, Map<String, List<String>> rangeToHighestTurnoverGroup, String range){
    Decimal turnover = 0;
    Integer frequency = 0;
    Integer recency = -1;
    Map<String, Decimal> groupToTurnover = new Map <String, Decimal>();
    for(RICSC_Transaction__c tr : transactionsList){
      Integer transactionRecency = tr.RICSC_TransactionDate__c != null ? tr.RICSC_TransactionDate__c.monthsBetween(Date.today()): -1;
      if(((tr.RICSC_Maison__c != null && tr.RICSC_Maison__c.equalsIgnoreCase('Jaeger Le Coultre')
          && (!tr.RICSC_TransactionCategory__c.equalsIgnoreCase(UtilityConstants.TRANSACTION_TYPE_REPAIR) || transactionRecency < UtilityConstants.RECENCY_FOR_ACCESSORY_REPAIR_JLC)))
          || (tr.RICSC_TransactionCategory__c != null && !tr.RICSC_TransactionCategory__c.equalsIgnoreCase(UtilityConstants.TRANSACTION_TYPE_REPAIR))
          && transactionRecency >= Integer.valueOf(range.split('-')[0])
          && transactionRecency <= Integer.valueOf(range.split('-')[1])){
        if(tr.RICSC_ProductName__r.RICSC_TechnicalProductType__c != null){
          String key = UtilityConstants.SEGMENTATION_TURNOVER_GROUPS.containsKey(tr.RICSC_ProductName__r.RICSC_TechnicalProductType__c)
                      ? UtilityConstants.SEGMENTATION_TURNOVER_GROUPS.get(tr.RICSC_ProductName__r.RICSC_TechnicalProductType__c)
                      : tr.RICSC_ProductName__r.RICSC_TechnicalProductType__c;
          if(!groupToTurnover.containsKey(key)){
            groupToTurnover.put(key, 0);
          }
          Decimal typeTurnover = groupToTurnover.get(key) + tr.RICSC_AmountWithTaxEUR__c;
          groupToTurnover.put(key, typeTurnover);
        }
        if(tr.RICSC_ProductName__r.RICSC_TechnicalProductSegment__c != null){
          String key = UtilityConstants.SEGMENTATION_TURNOVER_GROUPS.containsKey(tr.RICSC_ProductName__r.RICSC_TechnicalProductSegment__c)
                      ? UtilityConstants.SEGMENTATION_TURNOVER_GROUPS.get(tr.RICSC_ProductName__r.RICSC_TechnicalProductSegment__c)
                      : tr.RICSC_ProductName__r.RICSC_TechnicalProductSegment__c;
          if(!groupToTurnover.containsKey(key)){
            groupToTurnover.put(key, 0);
          }
          Decimal segmentTurnover = groupToTurnover.get(key) + tr.RICSC_AmountWithTaxEUR__c;
          groupToTurnover.put(key, segmentTurnover);
        }
        else if(tr.RICSC_ProductName__r.RICSC_OrganizationCode__c != null){
          String key = UtilityConstants.SEGMENTATION_TURNOVER_GROUPS.containsKey(tr.RICSC_ProductName__r.RICSC_OrganizationCode__c)
                      ? UtilityConstants.SEGMENTATION_TURNOVER_GROUPS.get(tr.RICSC_ProductName__r.RICSC_OrganizationCode__c)
                      : tr.RICSC_ProductName__r.RICSC_OrganizationCode__c;
          if(!groupToTurnover.containsKey(key)){
            groupToTurnover.put(key, 0);
          }
          Decimal segmentTurnover = groupToTurnover.get(key) + tr.RICSC_AmountWithTaxEUR__c;
          groupToTurnover.put(key, segmentTurnover);
        }
        if(tr.RICSC_ProductName__r.RICSC_TechnicalCollectionProductLine__c != null){
          String key = UtilityConstants.SEGMENTATION_TURNOVER_GROUPS.containsKey(tr.RICSC_ProductName__r.RICSC_TechnicalCollectionProductLine__c)
                      ? UtilityConstants.SEGMENTATION_TURNOVER_GROUPS.get(tr.RICSC_ProductName__r.RICSC_TechnicalCollectionProductLine__c)
                      : tr.RICSC_ProductName__r.RICSC_TechnicalCollectionProductLine__c;
          if(!groupToTurnover.containsKey(key)){
            groupToTurnover.put(key, 0);
          }
          Decimal collectionProductLineTurnover = groupToTurnover.get(key) + tr.RICSC_AmountWithTaxEUR__c;
          groupToTurnover.put(key, collectionProductLineTurnover);
        }
        if(tr.RICSC_ProductName__r.RICSC_TechnicalProductFamily__c != null){
          String key = UtilityConstants.SEGMENTATION_TURNOVER_GROUPS.containsKey(tr.RICSC_ProductName__r.RICSC_TechnicalProductFamily__c)
                      ? UtilityConstants.SEGMENTATION_TURNOVER_GROUPS.get(tr.RICSC_ProductName__r.RICSC_TechnicalProductFamily__c)
                      : tr.RICSC_ProductName__r.RICSC_TechnicalProductFamily__c;
          if(!groupToTurnover.containsKey(key)){
            groupToTurnover.put(key, 0);
          }
          Decimal collectionProductLineTurnover = groupToTurnover.get(key) + tr.RICSC_AmountWithTaxEUR__c;
          groupToTurnover.put(key, collectionProductLineTurnover);
        }
        turnover = turnover + tr.RICSC_AmountWithTaxEUR__c;
        if(tr.RICSC_TransactionCategory__c.equalsIgnoreCase(UtilityConstants.TRANSACTION_TYPE_RETURN)){
          frequency = frequency - 1;
        }
        else{
          frequency = frequency + 1;
        }
        if(!tr.RICSC_TransactionCategory__c.equalsIgnoreCase(UtilityConstants.TRANSACTION_TYPE_RETURN) && (recency > transactionRecency || recency == -1)){
          recency = transactionRecency;
        }
      }
    }

    List<String> highestTurnoverGroupList = new List<String>();
    Decimal highestTurnover = 0;
    for(String gr : groupToTurnover.keySet()){
      if(groupToTurnover.get(gr)>highestTurnover){
        highestTurnover = groupToTurnover.get(gr);
        highestTurnoverGroupList = new List<String>{gr};
      }
      else if(groupToTurnover.get(gr)==highestTurnover){
        highestTurnoverGroupList.add(gr);
      }
    }

    rangeToTurnover.put(range, turnover);
    rangeToRecency.put(range, recency);
    rangeToFrequency.put(range, frequency);
    rangeToHighestTurnoverGroup.put(range, highestTurnoverGroupList);
  }

  public static String getSegmentIfMatch(GlobalSegmentConfTable__mdt mdt, Decimal totalTurnover, Decimal rangeTurnover, Integer rangeRecency, Integer rangeFrequency, Integer firstSale, String potential, List<String> highestTurnoverGroupList, String productParameterToInclude, String productParameterToExclude, List<RICSC_Transaction__c> transactions){
    if(productParameterToInclude == null && productParameterToExclude == null){
      if(totalTurnover >= mdt.TurnoverAllTimeFrom__c && totalTurnover <= mdt.TurnoverAllTimeTo__c && rangeTurnover >= mdt.RangeTurnoverFrom__c && rangeTurnover <= mdt.RangeTurnoverTo__c && rangeRecency >= mdt.RecencyFrom__c && rangeRecency <= mdt.RecencyTo__c && rangeFrequency >= mdt.FrequencyFrom__c && rangeFrequency <= mdt.FrequencyTo__c && firstSale >= mdt.FirstSaleFrom__c && firstSale <= mdt.FirstSaleTo__c && ((mdt.Potential__c == null || (potential != null && mdt.Potential__c.contains(potential)))) && (mdt.HighestTurnover__c == null || (highestTurnoverGroupList.contains(mdt.HighestTurnover__c)))){
        return mdt.Segment__c;
      }
      else{
        return '';
      }
    }
    List<String> typesForRecency = new List<String>();
    List<String> typesForRecencyToExclude = new List<String>();
    List<String> typesForTurnover = new List<String>();
    List<String> typesForTurnoverToExclude = new List<String>();
    List<String> typesForFrequency = new List<String>();
    List<String> typesForFrequencyToExclude = new List<String>();
    List<String> parametersToInclude = productParameterToInclude != null ? productParameterToInclude.split(';') : new List<String>();
    List<String> parametersToExclude = productParameterToExclude != null ? productParameterToExclude.split(';') : new List<String>();
    if(parametersToInclude.size() > 0){
      typesForRecency = parametersToInclude.get(0).split('\\+');
      if(parametersToInclude.size() > 1){
        typesForTurnover = parametersToInclude.get(1).split('\\+');
        if(parametersToInclude.size() > 2){
          typesForFrequency = parametersToInclude.get(2).split('\\+');
        }
      }
    }
    if(parametersToExclude.size() > 0){
      typesForRecencyToExclude = parametersToExclude.get(0).split('\\+');
      if(parametersToInclude.size() > 1){
        typesForTurnoverToExclude = parametersToExclude.get(1).split('\\+');
        if(parametersToInclude.size() > 2){
          typesForFrequencyToExclude = parametersToExclude.get(2).split('\\+');
        }
      }
    }

    Decimal ppTurnover = 0;
    Integer ppRecency;
    Integer ppFrequency = 0;
    String technicalProductSegment = '';
    for(RICSC_Transaction__c tr : transactions){
      if(((tr.RICSC_Maison__c != null && tr.RICSC_Maison__c.equalsIgnoreCase('Jaeger Le Coultre')) || (tr.RICSC_TransactionCategory__c != null && !tr.RICSC_TransactionCategory__c.equalsIgnoreCase(UtilityConstants.TRANSACTION_TYPE_REPAIR)))){
        if(tr.RICSC_ProductName__r.RICSC_TechnicalProductSegment__c != null){
          technicalProductSegment = tr.RICSC_ProductName__r.RICSC_TechnicalProductSegment__c;
        }
        else {
          technicalProductSegment = tr.RICSC_ProductName__r.RICSC_OrganizationCode__c;
        }
        if(isToExclude(typesForRecencyToExclude, typesForTurnoverToExclude, typesForFrequencyToExclude, tr.RICSC_ProductName__r.RICSC_TechnicalProductType__c, technicalProductSegment, tr.RICSC_ProductName__r.RICSC_TechnicalCollectionProductLine__c, tr.RICSC_ProductName__r.RICSC_TechnicalProductFamily__c, tr.RICSC_ProductName__r.RICSC_ArticleType__c, tr.RICSC_TransactionCategory__c)){
          return '';
        }
        else if (tr.RICSC_ProductName__c != null){
          if(typesForTurnover.size() == 0 || (typesForTurnover.size() == 1 && typesForTurnover.get(0).equals('')) || isToInclude(typesForTurnover, tr.RICSC_ProductName__r.RICSC_TechnicalProductType__c, technicalProductSegment, tr.RICSC_ProductName__r.RICSC_TechnicalCollectionProductLine__c, tr.RICSC_ProductName__r.RICSC_TechnicalProductFamily__c, tr.RICSC_ProductName__r.RICSC_ArticleType__c, tr.RICSC_TransactionCategory__c)){
            ppTurnover = ppTurnover + tr.RICSC_AmountWithTaxEUR__c;
          }
          if(!tr.RICSC_TransactionCategory__c.equalsIgnoreCase(UtilityConstants.TRANSACTION_TYPE_RETURN) && (typesForRecency.size() == 0 || (typesForRecency.size() == 1 && typesForRecency.get(0).equals('')) || isToInclude(typesForRecency, tr.RICSC_ProductName__r.RICSC_TechnicalProductType__c, technicalProductSegment, tr.RICSC_ProductName__r.RICSC_TechnicalCollectionProductLine__c, tr.RICSC_ProductName__r.RICSC_TechnicalProductFamily__c, tr.RICSC_ProductName__r.RICSC_ArticleType__c, tr.RICSC_TransactionCategory__c))){
            ppRecency = tr.RICSC_TransactionDate__c.monthsBetween(Date.today());
          }
          if(typesForFrequency.size() == 0 || (typesForFrequency.size() == 1 && typesForFrequency.get(0).equals(''))  || isToInclude(typesForFrequency, tr.RICSC_ProductName__r.RICSC_TechnicalProductType__c, technicalProductSegment, tr.RICSC_ProductName__r.RICSC_TechnicalCollectionProductLine__c, tr.RICSC_ProductName__r.RICSC_TechnicalProductFamily__c, tr.RICSC_ProductName__r.RICSC_ArticleType__c, tr.RICSC_TransactionCategory__c)){
            if(tr.RICSC_TransactionCategory__c.equalsIgnoreCase(UtilityConstants.TRANSACTION_TYPE_RETURN)){
              ppFrequency = ppFrequency - 1;
            }
            else{
              ppFrequency = ppFrequency + 1;
            }
          }
        }
      }
    }
    if(totalTurnover >= mdt.TurnoverAllTimeFrom__c && totalTurnover <= mdt.TurnoverAllTimeTo__c && rangeTurnover >= mdt.RangeTurnoverFrom__c && rangeTurnover <= mdt.RangeTurnoverTo__c && rangeRecency >= mdt.RecencyFrom__c && rangeRecency <= mdt.RecencyTo__c && rangeFrequency >= mdt.FrequencyFrom__c && rangeFrequency <= mdt.FrequencyTo__c && firstSale >= mdt.FirstSaleFrom__c && firstSale <= mdt.FirstSaleTo__c && (mdt.Potential__c == null || mdt.Potential__c.contains(potential)) && (mdt.HighestTurnover__c == null || (highestTurnoverGroupList.contains(mdt.HighestTurnover__c))) && pPTurnover >= mdt.PPTurnoverFrom__c && pPTurnover <= mdt.PPTurnoverTo__c && pPRecency >= mdt.PPRecencyFrom__c && pPRecency <= mdt.PPRecencyTo__c && pPFrequency >= mdt.PPFrequencyFrom__c && pPFrequency <= mdt.PPFrequencyTo__c){
      return mdt.Segment__c;
    }
    return '';
  }

  public static boolean isToInclude(List<String> typesToInclude, String type, String segment, String collectionProductLine, String family, String articleType, String transactionCategory){
    String typeToInclude = type;
    String segmentToInclude = segment;
    String collectionProductLineToInclude = collectionProductLine;
    String familyToInclude = family;
    String articleTypeToInclude = articleType;
    boolean hasParenthesis = false;
    for(String s : typesToInclude){
      if(s.contains('(')){
        hasParenthesis = true;
      }
    }
    if(hasParenthesis){
      typeToInclude = '(' + type + ':' + transactionCategory + ')';
      segmentToInclude = '(' + segment + ':' + transactionCategory + ')';
      collectionProductLineToInclude = '(' + collectionProductLine + ':' + transactionCategory + ')';
      familyToInclude = '(' + family + ':' + transactionCategory + ')';
      articleTypeToInclude = '(' + articleType + ':' + transactionCategory + ')';
    }

    return typesToInclude.contains(type) ||
          typesToInclude.contains(segment) ||
          typesToInclude.contains(collectionProductLine) ||
          typesToInclude.contains(family) ||
          typesToInclude.contains(articleType) ||
          typesToInclude.contains(typeToInclude) ||
          typesToInclude.contains(segmentToInclude) ||
          typesToInclude.contains(collectionProductLineToInclude) ||
          typesToInclude.contains(familyToInclude) ||
          typesToInclude.contains(articleTypeToInclude) ||
          typesToInclude.contains(transactionCategory);
  }

  public static boolean isToExclude(List<String> typesForRecencyToExclude, List<String> typesForTurnoverToExclude, List<String> typesForFrequencyToExclude, String type, String segment, String collectionProductLine, String family, String articleType, String transactionCategory){
    String typeForRecency = type;
    String typeForFrequency = type;
    String typeForTurnover = type;
    String segmentForRecency = segment;
    String segmentForFrequency = segment;
    String segmentForTurnover = segment;
    String collectionProductLineForRecency = collectionProductLine;
    String collectionProductLineForFrequency = collectionProductLine;
    String collectionProductLineForTurnover = collectionProductLine;
    String familyForRecency = family;
    String familyForFrequency = family;
    String familyForTurnover = family;
    String articleTypeForRecency = articleType;
    String articleTypeForFrequency = articleType;
    String articleTypeForTurnover = articleType;
    Boolean hasParenthesis = false;
    for(String s : typesForRecencyToExclude){
      if(s.contains('(')){
        hasParenthesis = true;
      }
    }
    if(hasParenthesis){
      typeForRecency = '(' + type + ':' + transactionCategory + ')';
      segmentForRecency = '(' + segment + ':' + transactionCategory + ')';
      collectionProductLineForRecency = '(' + collectionProductLine + ':' + transactionCategory + ')';
      familyForRecency = '(' + family + ':' + transactionCategory + ')';
      articleTypeForRecency = '(' + articleType + ':' + transactionCategory + ')';
    }
    hasParenthesis = false;
    for(String s : typesForTurnoverToExclude){
      if(s.contains('(')){
        hasParenthesis = true;
      }
    }
    if(hasParenthesis){
      typeForTurnover = '(' + type + ':' + transactionCategory + ')';
      segmentForTurnover = '(' + segment + ':' + transactionCategory + ')';
      collectionProductLineForTurnover = '(' + collectionProductLine + ':' + transactionCategory + ')';
      familyForTurnover = '(' + family + ':' + transactionCategory + ')';
      articleTypeForTurnover = '(' + articleType + ':' + transactionCategory + ')';
    }
    hasParenthesis = false;
    for(String s : typesForFrequencyToExclude){
      if(s.contains('(')){
        hasParenthesis = true;
      }
    }
    if(hasParenthesis){
      typeForFrequency = '(' + type + ':' + transactionCategory + ')';
      segmentForFrequency = '(' + segment + ':' + transactionCategory + ')';
      collectionProductLineForFrequency = '(' + collectionProductLine + ':' + transactionCategory + ')';
      familyForFrequency = '(' + family + ':' + transactionCategory + ')';
      articleTypeForFrequency = '(' + articleType + ':' + transactionCategory + ')';
    }
    return typesForRecencyToExclude.contains('*'+typeForRecency) ||
            typesForRecencyToExclude.contains('*'+type) ||
            typesForRecencyToExclude.contains('*'+segmentForRecency) ||
            typesForRecencyToExclude.contains('*'+segment) ||
            typesForRecencyToExclude.contains('*'+collectionProductLineForRecency) ||
            typesForRecencyToExclude.contains('*'+collectionProductLine) ||
            typesForRecencyToExclude.contains('*'+familyForRecency) ||
            typesForRecencyToExclude.contains('*'+family) ||
            typesForRecencyToExclude.contains('*'+articleTypeForRecency) ||
            typesForRecencyToExclude.contains('*'+articleType) ||
            typesForRecencyToExclude.contains('*'+transactionCategory) ||
            typesForTurnoverToExclude.contains('*'+typeForTurnover) ||
            typesForTurnoverToExclude.contains('*'+type) ||
            typesForTurnoverToExclude.contains('*'+segmentForTurnover) ||
            typesForTurnoverToExclude.contains('*'+segment) ||
            typesForTurnoverToExclude.contains('*'+collectionProductLineForTurnover) ||
            typesForTurnoverToExclude.contains('*'+collectionProductLine) ||
            typesForTurnoverToExclude.contains('*'+familyForTurnover) ||
            typesForTurnoverToExclude.contains('*'+family) ||
            typesForRecencyToExclude.contains('*'+articleTypeForTurnover) ||
            typesForRecencyToExclude.contains('*'+articleType) ||
            typesForTurnoverToExclude.contains('*'+transactionCategory) ||
            typesForFrequencyToExclude.contains('*'+typeForFrequency) ||
            typesForFrequencyToExclude.contains('*'+type) ||
            typesForFrequencyToExclude.contains('*'+segmentForFrequency) ||
            typesForFrequencyToExclude.contains('*'+segment) ||
            typesForFrequencyToExclude.contains('*'+collectionProductLineForFrequency) ||
            typesForFrequencyToExclude.contains('*'+collectionProductLine) ||
            typesForFrequencyToExclude.contains('*'+familyForFrequency) ||
            typesForFrequencyToExclude.contains('*'+family) ||
            typesForRecencyToExclude.contains('*'+articleTypeForFrequency) ||
            typesForRecencyToExclude.contains('*'+articleType) ||
            typesForFrequencyToExclude.contains('*'+transactionCategory);
  }

  public static void setupTypesForProducts(String productParameter, List<String> typesForRecency, List<String> typesForRecencyToExclude, List<String> typesForTurnover, List<String> typesForTurnoverToExclude, List<String> typesForFrequency, List<String> typesForFrequencyToExclude){
    List<String> parameters = productParameter.split(';');
    typesForRecency = parameters.get(0).split('\\|').get(0).split('\\+');
    if(parameters.get(0).contains('\\|')){
      typesForRecencyToExclude = parameters.get(0).split('\\|').get(1).split('\\+');
    }
    typesForTurnover = parameters.get(1).split('\\|').get(0).split('\\+');
    if(parameters.get(1).contains('\\|')){
      typesForTurnoverToExclude = parameters.get(1).split('\\|').get(1).split('\\+');
    }
    typesForFrequency = parameters.get(2).split('\\|').get(0).split('\\+');
    if(parameters.get(2).contains('\\|')){
      typesForFrequencyToExclude = parameters.get(2).split('\\|').get(1).split('\\+');
    }
  }

    /****************************************************************************************************************************
    @author                   Maurizio D'Antonio
    @date                     24/Sep/2019
    @description              Method used to manage the Golden Record creation and linking of related objects
    @param masterRecord       Account master record
    @param mergedAccounts     Local records
    @param masterClone        Clone of master record
    @param relatedObjectsMap  Map of objects related to account involved in the merge
    *****************************************************************************************************************************/
    public static void goldenRecordManagement(Account masterRecord, Map<Id, Account> mergedAccounts, Account masterClone, Map<Id, List<SObject>> relatedObjectsMap){
    Account newAccount;
    Map<SObjectType, List<SObject>> type2records = new Map<SObjectType, List<SObject>>();
    List<Account> accountsToDelete = new List<Account>();
    List<Schema.FieldSetMember> fields = Schema.SObjectType.Account.fieldSets.FieldsToCopyOnGR.getFields();
    List<String> fieldsToCopy = new List<String>();
    for(Schema.FieldSetMember m : fields){
      fieldsToCopy.add(m.getFieldPath());
    }

    boolean masterHasLocalRecords = mergedAccounts.get(masterRecord.Id) != null ? mergedAccounts.get(masterRecord.Id).RICSC_HasLocalRecords__c : masterRecord.RICSC_HasLocalRecords__c;
    if(masterHasLocalRecords){
      for(Account a : mergedAccounts.values()){
        if(a.Id != masterRecord.Id){
          a.RICSC_IsGoldenRecord__c = false;
          a.RICSC_HasLocalRecords__c = false;
          if(a.RICSC_MasterRecord__c && a.RICSC_GoldenRecord__c != null && a.RICSC_GoldenRecord__c != masterRecord.Id){
            Account depromotedGoldenRecord = mergedAccounts.get(a.RICSC_GoldenRecord__c);
            Map <String,Object> populatedFieldMap = a.getPopulatedFieldsAsMap();

            for (String v : populatedFieldMap.keySet()){
              if(fieldsToCopy.contains(v)){
                depromotedGoldenRecord.put(v,populatedFieldMap.get(v));
              }
            }
            depromotedGoldenRecord.RICSC_ClientID__c = a.RICSC_ClientID__c;
            depromotedGoldenRecord.RICSC_SWSEID__c = a.RICSC_SWSEID__c;
            depromotedGoldenRecord.RICSC_ExternalID__pc = a.RICSC_ExternalID__pc;
            depromotedGoldenRecord.RICSC_Externalid__c = a.RICSC_Externalid__c;
            depromotedGoldenRecord.RICSC_HistoricalExternalID__c = a.RICSC_HistoricalExternalID__c;
            accountsToDelete.add(a);
            updateDeletedRecordRelatedObjects(a, masterRecord.Id, depromotedGoldenRecord.Id, type2records, relatedObjectsMap);
          }
          else{
            updateAccountRelatedObjects(a, masterRecord.Id, null, type2records, relatedObjectsMap);
            a.RICSC_GoldenRecord__c = masterRecord.Id;
          }
        }
        else {
          Map <String,Object>  masterRecordMap = masterRecord.getPopulatedFieldsAsMap();
          for (String v : masterRecordMap.keySet()){
            if(fieldsToCopy.contains(v)){
              a.put(v,masterRecordMap.get(v));
            }
          }
          a.RICSC_GoldenRecord__c = null;
          a.RICSC_HasLocalRecords__c = true;
          a.RICSC_ClientID__c = null;
          a.RICSC_SWSEID__c = null;
          a.RICSC_ExternalID__pc = null;
          a.RICSC_Externalid__c = null;
          a.RICSC_HistoricalExternalID__c = null;
        }
      }
      if(accountsToDelete.size()>0){
        Database.delete(accountsToDelete);
      }
    }
    else{
      if(mergedAccounts.containsKey(masterRecord.Id)){
        newAccount = masterClone != null ? masterClone : (Account)(mergedAccounts.get(masterRecord.Id)).clone(false, true, false, false);
      }
      else{
        newAccount = masterClone != null ? masterClone : (Account)masterRecord.clone(false, true, false, false);
      }
      String externalID = newAccount.RICSC_ExternalID__c;
      //String externalIDp = newAccount.RICSC_ExternalID__pc;
      String clientID = newAccount.RICSC_ClientID__c;
      String swseid = newAccount.RICSC_SWSEID__c;
      String historicalExternalID = newAccount.RICSC_HistoricalExternalID__c;
      newAccount.RICSC_ExternalID__c = null;
      newAccount.RICSC_ClientID__c = null;
      newAccount.RICSC_SWSEID__c = null;
      newAccount.RICSC_HistoricalExternalID__c = null;
      //newAccount.RICSC_ExternalID__pc = null;
      newAccount = (Account)getAccountListWithOnlyEditableFields(new List<SObject>{newAccount}).get(0);
      newAccount.RICSC_MasterRecord__c = true;
      newAccount.RICSC_IsGoldenRecord__c = false;
      newAccount.RICSC_GoldenRecord__c = masterRecord.Id;
      Database.insert(newAccount);
      newAccount.RICSC_ExternalID__c = externalID;
      newAccount.RICSC_ClientID__c = clientID;
      newAccount.RICSC_SWSEID__c = swseid;
      newAccount.RICSC_HistoricalExternalID__c = historicalExternalID;
      //newAccount.RICSC_ExternalID__pc = externalIDp;
      Utility.addRecordToMap(type2records, newAccount);
      if(!mergedAccounts.keySet().contains(masterRecord.Id)){
        mergedAccounts.put(masterRecord.Id, masterRecord);
      }
      updateAccountsAndRelatedObjects(mergedAccounts, (Account)masterRecord, type2records, newAccount.Id, relatedObjectsMap);
    }
    List<SObject> recordsToUpdate = new List<SObject>();
    for(Integer i = 0; i < type2records.values().size(); i++) {
      recordsToUpdate.addAll(type2records.values()[i]);
    }
    if(!recordsToUpdate.isEmpty()) {
      TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.GRManualLink',true);
      TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.GRManualUnlink',true);
      recordsToUpdate = getAccountListWithOnlyEditableFields(recordsToUpdate);
      Database.update(recordsToUpdate);
      TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.GRManualLink',false);
      TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.GRManualUnlink',false);
    }
    Set<Id> grIds = new Set<Id>();
    for(Account a : mergedAccounts.values()){
      if(a.RICSC_IsGoldenRecord__c){
        grIds.add(a.Id);
      }
    }
    if(GeneralSettings__c.getInstance().RICSC_RunSegmentationAfterDCJob__c){
      calculateSegment(grIds, true, true);
    }

    if(GeneralSettings__c.getInstance().RICSC_RunConsentsAlignmentAfterDCJob__c){
      Map<Id, Account> updatedAccountsMap = new Map<Id, Account>();
      for(SObject obj : recordsToUpdate){
        if(obj.getSObjectType() == Schema.Account.getSObjectType()){
            updatedAccountsMap.put((Id)obj.get('Id'), (Account)obj);
        }
      }
      if(!updatedAccountsMap.keySet().contains(masterRecord.Id) && !mergedAccounts.containsKey(masterRecord.Id)){
        updatedAccountsMap.put(masterRecord.Id, masterRecord);
      }
      else if(!updatedAccountsMap.keySet().contains(masterRecord.Id)){
        updatedAccountsMap.put(masterRecord.Id, mergedAccounts.get(masterRecord.Id));
      }
      propagateConsents(updatedAccountsMap);
    }
  }

  public static void propagateConsents(Map<Id, Account> accountsMap){
    List<Account> accountsToUpdate = new List<Account>();
    Map<Id, List<Account>> mapGrToLocals = new Map<Id, List<Account>>();
    for(Account acc : accountsMap.values()){
      if(acc.RICSC_HasLocalRecords__c && !mapGrToLocals.containsKey(acc.Id)){
        mapGrToLocals.put(acc.Id, new List<Account>());
      }
      else if(!acc.RICSC_HasLocalRecords__c && acc.RICSC_GoldenRecord__c != null){
        if(!mapGrToLocals.containsKey(acc.RICSC_GoldenRecord__c)){
          mapGrToLocals.put(acc.RICSC_GoldenRecord__c, new List<Account>{acc});
        }
        else{
          List<Account> localRecords = mapGrToLocals.get(acc.RICSC_GoldenRecord__c);
          localRecords.add(acc);
          mapGrToLocals.put(acc.RICSC_GoldenRecord__c, localRecords);
        }
      }
    }

    for(Id goldenRecordId : mapGrToLocals.keySet()){
      List<Account> accountsGroup = mapGrToLocals.get(goldenRecordId);
      accountsGroup.add(accountsMap.get(goldenRecordId));
      Account master = getAccountWithMostRecentConsentUpdate(new Map<Id, Account>(accountsGroup));
      if(master.RICSC_ConsentTimestamp__c != null){
        for(Account slave : accountsGroup){
          if(slave.Id != master.Id){
            Account a = new Account(Id = slave.Id);
            a.RICSC_ConsentTimestamp__c = master.RICSC_ConsentTimestamp__c;
            a.RICSC_CanBeContacted__c = master.RICSC_CanBeContacted__c;
            a.RICSC_ElectronicContact__c = master.RICSC_ElectronicContact__c;
            a.RICSC_PostalContact__c = master.RICSC_PostalContact__c;
            a.RICSC_VoiceContact__c = master.RICSC_VoiceContact__c;
            accountsToUpdate.add(a);
          }
        }
      }
    }
    TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.PropagateConsentsOnRecords',true);
    Database.update(accountsToUpdate);
    TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.PropagateConsentsOnRecords',false);
  }

  public static Account getAccountWithMostRecentConsentUpdate(Map<Id, Account> accountsMap){
    Id masterId;
    DateTime mostRecentConsentTimestamp;
    for(Account acc : accountsMap.values()){
      if(mostRecentConsentTimestamp == null || mostRecentConsentTimestamp < acc.RICSC_ConsentTimestamp__c){
        mostRecentConsentTimestamp = acc.RICSC_ConsentTimestamp__c;
        masterId = acc.Id;
      }
    }
    return accountsMap.get(masterId);
  }

  public static void updateAccountsAndRelatedObjects(Map<Id, Account> mergedAccounts, Account masterRecord, Map<SObjectType, List<SObject>> type2records, Id newAccountId, Map<Id, List<SObject>> relatedObjectsMap){
    List<Schema.FieldSetMember> fields = Schema.SObjectType.Account.fieldSets.FieldsToCopyOnGR.getFields();
    List<String> fieldsToCopy = new List<String>();
    List<Account> accountsToDelete = new List<Account>();
    for(Schema.FieldSetMember m : fields){
      fieldsToCopy.add(m.getFieldPath());
    }
    for(Account a : mergedAccounts.values()){
      if(a.Id == masterRecord.id){
        Map <String,Object>  masterRecordMap = masterRecord.getPopulatedFieldsAsMap();
        for (String v : masterRecordMap.keySet()){
          if(fieldsToCopy.contains(v)){
            a.put(v,masterRecordMap.get(v));
          }
        }
        a.RICSC_HasLocalRecords__c = true;
        a.RICSC_IsGoldenRecord__c = true;
        a.RICSC_ClientID__c = null;
        a.RICSC_ExternalID__pc = null;
        a.RICSC_Externalid__c = null;
        a.RICSC_SWSEID__c = null;
        a.RICSC_HistoricalExternalID__c = null;
        updateAccountRelatedObjects(a, masterRecord.id, newAccountId, type2records, relatedObjectsMap);
      }
      else if(a.RICSC_MasterRecord__c && a.RICSC_GoldenRecord__c != null && a.RICSC_GoldenRecord__c != masterRecord.Id){
        updateDeletedRecordRelatedObjects(a, masterRecord.Id, a.RICSC_GoldenRecord__c, type2records, relatedObjectsMap);
        Account depromotedGoldenRecord = mergedAccounts.get(a.RICSC_GoldenRecord__c);
        depromotedGoldenRecord.RICSC_ClientID__c = a.RICSC_ClientID__c;
        depromotedGoldenRecord.RICSC_SWSEID__c = a.RICSC_SWSEID__c;
        depromotedGoldenRecord.RICSC_ExternalID__pc = a.RICSC_ExternalID__pc;
        depromotedGoldenRecord.RICSC_Externalid__c = a.RICSC_Externalid__c;
        depromotedGoldenRecord.RICSC_HistoricalExternalID__c = a.RICSC_HistoricalExternalID__c;
        accountsToDelete.add(a);
      }
      else{
        a.RICSC_GoldenRecord__c = masterRecord.id;
        a.RICSC_IsGoldenRecord__c = false;
        a.RICSC_HasLocalRecords__c = false;
        updateAccountRelatedObjects(a, masterRecord.id, newAccountId, type2records, relatedObjectsMap);
      }
    }
    if(accountsToDelete.size() > 0){
      Database.delete(accountsToDelete);
    }
  }

  public static void updateAccountRelatedObjects(Account acc, Id masterId, Id newAccountId, Map<SObjectType, List<SObject>> type2records, Map<Id, List<SObject>> relatedObjectsMap){
    List<SObject> objects = new List<SObject>();
    if(relatedObjectsMap.get(acc.Id) != null){
      objects.addAll(relatedObjectsMap.get(acc.Id));

      for(SObject obj : objects){
        Boolean recordHasChanged = false;
        if(obj.getSobjectType().getDescribe().fields.getMap().keySet().contains('ricsc_goldenrecord__c')){
          if(!obj.get('RICSC_GoldenRecord__c').toString().equals(masterId)){
            obj.put('RICSC_GoldenRecord__c', masterId);
            recordHasChanged = true;
          }
        }
        else if(obj.getSobjectType().getDescribe().fields.getMap().keySet().contains('ricsc_gr__c')){
          if(!obj.get('RICSC_GR__c').toString().equals(masterId)){
            obj.put('RICSC_GR__c', masterId);
            recordHasChanged = true;
          }
        }
        if(newAccountId != null && (masterId == null || acc.Id == masterId)){
          if(obj.getSobjectType().getDescribe().fields.getMap().keySet().contains('ricsc_account__c')){
            if(!obj.get('RICSC_Account__c').toString().equals(newAccountId)){
              obj.put('RICSC_Account__c', newAccountId);
              recordHasChanged = true;
            }
          }
          else if(obj.getSobjectType().getDescribe().fields.getMap().keySet().contains('accountid')){
            if(!obj.get('AccountId').toString().equals(newAccountId)){
              obj.put('AccountId', newAccountId);
              recordHasChanged = true;
            }
          }
        }
        if(recordHasChanged){
          Utility.addRecordToMap(type2records, obj);
        }
      }
    }
    Utility.addRecordToMap(type2Records, acc);
  }

  public static void updateDeletedRecordRelatedObjects(Account acc, Id masterId, Id newAccountId, Map<SObjectType, List<SObject>> type2records, Map<Id, List<SObject>> relatedObjectsMap){
    List<SObject> objects = new List<SObject>();
    if(relatedObjectsMap.get(acc.Id) != null){
      objects.addAll(relatedObjectsMap.get(acc.Id));

      for(SObject obj : objects){
        if(obj.getSobjectType().getDescribe().fields.getMap().keySet().contains('ricsc_goldenrecord__c')){
          obj.put('RICSC_GoldenRecord__c', masterId);
        }
        else if(obj.getSobjectType().getDescribe().fields.getMap().keySet().contains('ricsc_gr__c')){
          obj.put('RICSC_GR__c', masterId);
        }
        if(newAccountId != null){
          if(obj.getSobjectType().getDescribe().fields.getMap().keySet().contains('ricsc_account__c')){
            obj.put('RICSC_Account__c', newAccountId);
          }
          else if(obj.getSobjectType().getDescribe().fields.getMap().keySet().contains('accountid')){
            obj.put('AccountId', newAccountId);
          }
        }
        Utility.addRecordToMap(type2records, obj);
      }
    }
  }

  /****************************************************************************************************************************
  @author                   Maurizio D'Antonio
  @date                     08/Nov/2019
  @description              Method used to copy fields from the merged accounts to master record
                            using dupcheck API
  @param masterRecord       Account master record
  @param accountsToMerge    Local records
  @return                   Account with fields populated following the DC merge logic
  *****************************************************************************************************************************/
  public static Account copyFieldsOnMasterFromLocals(Account masterRecord, Map <Id, Account> accountsToMerge){
    List<Schema.FieldSetMember> fields = Schema.SObjectType.Account.fieldSets.FieldsToCopyOnGR.getFields();
    List<String> fieldsToCopy = new List<String>();
    for(Schema.FieldSetMember m : fields){
      fieldsToCopy.add(m.getFieldPath());
    }
    accountsToMerge.put(masterRecord.Id, masterRecord);
    dupcheck.dc3Api api = new dupcheck.dc3Api();
    Account mergeMaster = (Account)api.getMergeMaster(accountsToMerge.values());
    Account newMaster = masterRecord.clone(true);
    Map <String,Object> populatedFieldMap = accountsToMerge.get(mergeMaster.Id).getPopulatedFieldsAsMap();
    for (String f : populatedFieldMap.keySet()){
      if(fieldsToCopy.contains(f)){
        newMaster.put(f,populatedFieldMap.get(f));
      }
    }
    populatedFieldMap = mergeMaster.getPopulatedFieldsAsMap();
    for (String f : populatedFieldMap.keySet()){
      if(fieldsToCopy.contains(f)){
        newMaster.put(f,populatedFieldMap.get(f));
      }
    }
    return newMaster;
  }

  public static List<SObject> getAccountListWithOnlyEditableFields(List<SObject> recordsToUpdate){
    List<Schema.FieldSetMember> fields = Schema.SObjectType.Account.fieldSets.AllEditableFields.getFields();
    List<String> editableFields = new List<String>();
    for(Schema.FieldSetMember m : fields){
      editableFields.add(m.getFieldPath());
    }
    List<SObject> newRecordsToUpdate = new List<SObject>();

    for(SObject obj : recordsToUpdate){
      if(obj.getSObjectType() == Schema.Account.getSObjectType()){
        Account acc = new Account(Id = (Id)obj.get('Id'));
        for(String f : editableFields){
          acc.put(f, obj.get(f));
        }
        newRecordsToUpdate.add(acc);
      }
      else{
        newRecordsToUpdate.add(obj);
      }
    }

    return newRecordsToUpdate;
  }

  /****************************************************************************************************************************
  @author                   Maurizio D'Antonio
  @date                     20/Nov/2019
  @description              Check if in a set of records there is 1 or more pair of false duplicates
  @param recordsIds         Ids of records
  @return                   Boolean: true if the query founds a couple of false duplicates, false otherwise
  *****************************************************************************************************************************/
  public static Boolean falseDuplicatesInSet(Set<Id> recordsIds){
    List<dupcheck__dcDiscard__c> dcDiscardList = new List<dupcheck__dcDiscard__c>();
    if(Schema.sObjectType.dupcheck__dcDiscard__c.isAccessible()){
      dcDiscardList = [SELECT dupcheck__recordA__c, dupcheck__recordB__c, dupcheck__Relation__c
                                                  FROM dupcheck__dcDiscard__c
                                                  WHERE dupcheck__Relation__c = 'False Duplicate'
                                                    AND dupcheck__recordA__c IN :recordsIds
                                                    AND dupcheck__recordB__c IN :recordsIds];
    }
    return dcDiscardList.size()>0;
  }



  /****************************************************************************************************************************
  @author                   Silvan Sholla
  @date                     25/Nov/2019
  @description              Populates the golden record lookup on the related objects before insert based on the golden record
                            Lookup of the account
                            if the golden Record lookup on the account is empty fill the RICSC_GoldenRecord__c lookup with the
                            account id
                            otherwise fill it with the RICSC_GoldenRecord__c of the account
  @param recordsIds         parent Child relationship, local record lookup name, goldenrecord lookup name,trigger handler name
                            related records to the account
  *****************************************************************************************************************************/
  public static void goldenRecordLookUpPopulate(String parentChildRelationShip,String localRecordLookUp,String goldenRecordLookUp,String triggerHandlerName,List<SObject> relatedRecords){
    Set<Id> relatedAccounts = new Set<Id>();
    Set<Id> relatedObjects = new Set<Id>();

    List<SObject> objectsToBeUpdated = new List<SObject>();

    for(SObject currentRecord : (List<SObject>) relatedRecords){
      if(currentRecord.get(localRecordLookUp) != null){
        relatedAccounts.add(currentRecord.get(localRecordLookUp).toString());
      }
    }

    if(relatedAccounts.size()>0){

      Map<Id,Account> relatedAccountMap = new Map<Id,Account>([SELECT id,RICSC_GoldenRecord__c,RICSC_HasLocalRecords__c,RICSC_IsGoldenRecord__c FROM Account WHERE Id IN :relatedAccounts]);

      for(SObject currentRecord : (List<SObject>) relatedRecords){
        if(currentRecord.get(localRecordLookUp) != null){
          if(relatedAccountMap.get(currentRecord.get(localRecordLookUp).toString()).RICSC_HasLocalRecords__c == false &&
            relatedAccountMap.get(currentRecord.get(localRecordLookUp).toString()).RICSC_IsGoldenRecord__c == false){
              currentRecord.put(goldenRecordLookUp,relatedAccountMap.get(currentRecord.get(localRecordLookUp).toString()).RICSC_GoldenRecord__c);
          }else if(relatedAccountMap.get(currentRecord.get(localRecordLookUp).toString()).RICSC_HasLocalRecords__c == false &&
                   relatedAccountMap.get(currentRecord.get(localRecordLookUp).toString()).RICSC_IsGoldenRecord__c == true){
              currentRecord.put(goldenRecordLookUp,relatedAccountMap.get(currentRecord.get(localRecordLookUp).toString()).Id);
          }
        }
      }
    }
  }

  /****************************************************************************************************************************
  @author                   Maurizio D'Antonio
  @date                     13/Jan/2020
  @description              Returns the map of related objects of every account specified in the input
  @param accountIds         IDs of accounts to get related objects
  @return                   Map of objects related to every account specified in the input
  *****************************************************************************************************************************/
  public static Map<Id,List<SObject>> getAccountsRelatedObjects(Set<Id> accountIds){
    Map<Id,List<SObject>> relatedObjectsmap = new Map<Id,List<SObject>>();
    List<SObject> objects = new List<SObject>();
    objects.addAll([SELECT RICSC_GR__c, RICSC_Account__c FROM RICSC_Email__c WHERE RICSC_Account__c IN :accountIds]);
    objects.addAll([SELECT RICSC_GR__c, RICSC_Account__c FROM RICSC_SocialMediaID__c WHERE RICSC_Account__c IN :accountIds]);
    objects.addAll([SELECT RICSC_GR__c, RICSC_Account__c FROM RICSC_Phone__c WHERE RICSC_Account__c IN :accountIds]);
    objects.addAll([SELECT RICSC_GR__c, RICSC_Account__c FROM RICSC_Address__c WHERE RICSC_Account__c IN :accountIds]);
    objects.addAll([SELECT RICSC_GoldenRecord__c, RICSC_Account__c FROM RICSC_Transaction__c WHERE RICSC_Account__c IN :accountIds]);
    objects.addAll([SELECT RICSC_GoldenRecord__c, RICSC_Account__c FROM RICSC_Activity__c WHERE RICSC_Account__c IN :accountIds]);
    objects.addAll([SELECT RICSC_GoldenRecord__c, AccountId FROM Asset WHERE AccountId IN :accountIds]);
    objects.addAll([SELECT RICSC_GoldenRecord__c, RICSC_Account__c FROM RICSC_Wishlist__c WHERE RICSC_Account__c IN :accountIds]);
    objects.addAll([SELECT RICSC_GoldenRecord__c, RICSC_Account__c FROM RICSC_Relation__c WHERE RICSC_Account__c IN :accountIds]);
    for(SObject obj : objects){
      String accountLookup;
      if(obj.getSobjectType().getDescribe().fields.getMap().keySet().contains('ricsc_account__c')){
        accountLookup = 'RICSC_Account__c';
      }
      else if(obj.getSobjectType().getDescribe().fields.getMap().keySet().contains('accountid')){
        accountLookup = 'AccountId';
      }
      if(!relatedObjectsmap.containsKey((Id)obj.get(accountLookup))){
        relatedObjectsmap.put((Id)obj.get(accountLookup), new List<SObject>());
      }
      List<SObject> relatedObjects = relatedObjectsmap.get((Id)obj.get(accountLookup));
      relatedObjects.add(obj);
      relatedObjectsmap.put((Id)obj.get(accountLookup), relatedObjects);
    }
    return relatedObjectsmap;
  }
}