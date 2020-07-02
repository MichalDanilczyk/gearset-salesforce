public with sharing class ProductPicture {
   public class CustomWrapper {
      @AuraEnabled
      public String name {set; get;}
      @AuraEnabled
      public String url {set; get;}

}

  @AuraEnabled(cacheable=true)
    public static CustomWrapper getProductURL(String id) {
      Id obid = (Id) id;
      String objectType = obid.getSObjectType().getDescribe().getName();
      Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectType);
      SObject newSobject = sObjectType.newSObject();
      CustomWrapper product = new CustomWrapper();
      product.name = '';
      product.url = '';
      if(objectType == 'RICSC_Transaction__c'){
        if(Schema.sObjectType.RICSC_Transaction__c.isAccessible()){
          newSobject =[SELECT Id,RICSC_ProductName__r.Name, RICSC_ProductName__r.RICSC_FrontPictureURL__c  FROM RICSC_Transaction__c WHERE id = :Id];
          if(newSobject.getSObject('RICSC_ProductName__r') != null){
            product.name = newSObject.getSobject('RICSC_ProductName__r').get('Name').toString();
          }
          if (newSobject.getSObject('RICSC_ProductName__r') != null && newSObject.getSobject('RICSC_ProductName__r').get('RICSC_FrontPictureURL__c')!=null){
            product.url = newSObject.getSobject('RICSC_ProductName__r').get('RICSC_FrontPictureURL__c').toString();
          }
        }
      }
      else if(objectType == 'RICSC_Wishlist__c'){
        if(Schema.sObjectType.RICSC_Wishlist__c.isAccessible()){
          newSobject =[SELECT Id,RICSC_ProductName__r.Name, RICSC_ProductName__r.RICSC_FrontPictureURL__c  FROM RICSC_Wishlist__c WHERE id = :Id];
          product.name = newSObject.getSobject('RICSC_ProductName__r').get('Name').toString();
          if (newSObject.getSobject('RICSC_ProductName__r') != null && newSObject.getSobject('RICSC_ProductName__r').get('RICSC_FrontPictureURL__c')!=null){
            product.url = newSObject.getSobject('RICSC_ProductName__r').get('RICSC_FrontPictureURL__c').toString();
          }
        }
      }
      else if(objectType == 'Asset'){
        if(Schema.sObjectType.Asset.isAccessible()){
          newSobject =[SELECT Id,Product2.Name, Product2.RICSC_FrontPictureURL__c  FROM Asset WHERE id = :Id];
          product.name = newSObject.getSobject('Product2').get('Name').toString();
          if(newSObject.getSobject('Product2') != null && newSObject.getSobject('Product2').get('RICSC_FrontPictureURL__c')!=null){
            product.url = newSObject.getSobject('Product2').get('RICSC_FrontPictureURL__c').toString();
          }
        }
      }
      return product;
    }

}