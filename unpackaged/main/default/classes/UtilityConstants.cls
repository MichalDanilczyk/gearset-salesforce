/**********************************************************************************************
* @author       Piergiorgio Lisanti
* @date         26/Aug/2019
* @description  This class tracks all constant field items in a centralized way
**********************************************************************************************/
public without sharing class UtilityConstants {

    // Functional Scopes
    public enum FunctionalScopes {
        GL, PRD, SBX
    }
    // Fields filter for dynamic SOQL
    public enum SOQLFieldsFilter {
        ALL, CREATABLE, GOLDENRECORD
    }

    //Group Names
    public static final String NON_CHINA_GROUP_REGULAR_NAME = 'RICSC_VCACRMNonChinaRoles';


    //Record Types
    public static final String ACCOUNTBOUTIQUE_RT = 'RICSC_Boutique';
    public static final String PERSON_ACCOUNT_VCA_RT = 'RICSC_VanCleefAndArpels';
    public static final String PERSON_ACCOUNT_CAR_RT = 'RICSC_Cartier';
    public static final String PERSON_ACCOUNT_JLC_RT = 'RICSC_JaegerLeCoultre';
    public static final String ACCOUNTBOUTIQUE_RT_ID = RecordTypeHelper.getRTId('Account', UtilityConstants.ACCOUNTBOUTIQUE_RT);
    public static final String PERSON_ACCOUNT_VCA_RT_ID = RecordTypeHelper.getRTId('Account',UtilityConstants.PERSON_ACCOUNT_VCA_RT);
    public static final String PERSON_ACCOUNT_CAR_RT_ID = RecordTypeHelper.getRTId('Account',UtilityConstants.PERSON_ACCOUNT_CAR_RT);
    public static final String PERSON_ACCOUNT_JLC_RT_ID = RecordTypeHelper.getRTId('Account',UtilityConstants.PERSON_ACCOUNT_JLC_RT);
    public static final Set<String> PERSON_ACCOUNT_RT_SET = new Set<String>{PERSON_ACCOUNT_VCA_RT,PERSON_ACCOUNT_CAR_RT,PERSON_ACCOUNT_JLC_RT};
    public static final Set<String> PERSON_ACCOUNT_RT_SET_ID = new Set<String>{PERSON_ACCOUNT_VCA_RT_ID,PERSON_ACCOUNT_CAR_RT_ID,PERSON_ACCOUNT_JLC_RT_ID};

    //Client Flags
    public static final String CLIENT_FLAG_TOP_VIP = 'Top VIP';
    public static final String CLIENT_FLAG_VIP = 'VIP';
    public static final String CLIENT_FLAG_POTENTIAL_VIP = 'Potential VIP';
    public static final Set<String> CLIENT_FLAG_VIP_SET = new Set<String>{CLIENT_FLAG_TOP_VIP,CLIENT_FLAG_VIP,CLIENT_FLAG_POTENTIAL_VIP};

    //Global Segment
    public static final String GLOBAL_SEGMENT_VIP = 'VIP';
    public static final String GLOBAL_SEGMENT_TOP_VIP = 'TOP VIP';

    //Apex Reason
    public static final String VCA_APEX_REASON_GOLDEN_RECORD = 'RICSC_VCASharingGolden__c';
    public static final String VCA_APEX_REASON_LOCAL_RECORD = 'RICSC_VCASharingLocal__c';

    //Transaction Types
    public static final String TRANSACTION_TYPE_SALES = 'Sale';
    public static final String TRANSACTION_TYPE_RETURN = 'Return';
    public static final String TRANSACTION_TYPE_REPAIR = 'Repair';

    //Product Types
    public static final String PRODUCT_TYPE_HIGH_JEWELLERY = 'High Jewellery';
    public static final String PRODUCT_TYPE_JMF = 'JMF';
    public static final String PRODUCT_TYPE_JEWELLERY = 'Jewellery';
    public static final String PRODUCT_TYPE_WATCHES = 'Watches';
    public static final String PRODUCT_TYPE_BRIDAL = 'Bridal';
    public static final String PRODUCT_TYPE_ACCESSORIES = 'Accessories';
    public static final String PRODUCT_TYPE_BIJOUX = 'Bijoux';
    public static final Set<String> PRODUCT_TYPE_SET_TURNOVER = new Set<String>{PRODUCT_TYPE_JMF,PRODUCT_TYPE_HIGH_JEWELLERY,PRODUCT_TYPE_JEWELLERY,PRODUCT_TYPE_WATCHES,PRODUCT_TYPE_BRIDAL};

    //Product Family
    public static final String PRODUCT_FAMILY_HMF = 'HMF';
    public static final String PRODUCT_FAMILY_JMF = 'JMF';
    public static final String PRODUCT_FAMILY_WMF = 'WMF';
    public static final Set<String> PRODUCT_FAMILY_SET_TURNOVER = new Set<String>{PRODUCT_FAMILY_JMF,PRODUCT_FAMILY_HMF,PRODUCT_FAMILY_WMF};

    public static final String PRODUCT_FAMILY_OMF = 'OMF';
    public static final String PRODUCT_FAMILY_LMF = 'LMF';
    public static final String PRODUCT_FAMILY_FMF = 'FMF';
    public static final String PRODUCT_FAMILY_EMF = 'EMF';

    //Product Segment
    public static final String PRODUCT_SEGMENT_BJ = 'BJ';

    //SourceCRM
    public static final String SOURCE_CRM_SAP = 'SAP_CRM';

    //Class Codes
    public static final String CLASS_CODE_WHLSL = 'Wholesaler';
    public static final String CLASS_CODE_PROSP = 'Prospect';
    public static final String CLASS_CODE_SCLNT = 'Customer Service Client';
    public static final String CLASS_CODE_RCLNT = 'Boutique Client';
    public static final String CLASS_CODE_CCLNT = 'Contact Center Client';
    public static final String CLASS_CODE_WCLNT = 'Web Client';
    public static final String CLASS_CODE_ECOM  = 'E-Commerce Client';
    public static final String CLASS_CODE_MCLNT = 'Multi-Channel Client';
    public static final String CLASS_CODE_CHARY = 'Charity Client';

    //Transaction Channel
    public static final String TRANSACTION_CHANNEL_BOUTIQUE = 'Boutique';
    public static final String TRANSACTION_CHANNEL_CC = 'CC';
    public static final String TRANSACTION_CHANNEL_WEB = 'Web';
    public static final String TRANSACTION_CHANNEL_WHOLESALER = 'Wholesaler';
    public static final String TRANSACTION_CHANNEL_CHARITY = 'Charity';

    //Maison Name
    public static final String MAISON_CARTIER = 'Cartier';
    public static final String MAISON_VAN_CLEEF_ARPELS = 'Van Cleef & Arpels';
    public static final String MAISON_JAEGER_LE_COULTRE = 'Jaeger Le Coultre';

    //Segmentation highest turnover group
    public static final Map<String,String> SEGMENTATION_TURNOVER_GROUPS = new Map<String,String>{
      PRODUCT_FAMILY_OMF=>PRODUCT_TYPE_ACCESSORIES,
      PRODUCT_FAMILY_LMF=>PRODUCT_TYPE_ACCESSORIES,
      PRODUCT_FAMILY_FMF=>PRODUCT_TYPE_ACCESSORIES,
      PRODUCT_FAMILY_EMF=>PRODUCT_TYPE_ACCESSORIES,
      PRODUCT_FAMILY_WMF=>PRODUCT_TYPE_WATCHES,
      PRODUCT_TYPE_JMF=>PRODUCT_TYPE_JEWELLERY,
      PRODUCT_SEGMENT_BJ=>PRODUCT_TYPE_BIJOUX
    };

    //Recency value to exclude JLC accessories/repair transaction older than 3 years
    public static final Integer RECENCY_FOR_ACCESSORY_REPAIR_JLC = 36;
}