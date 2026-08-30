@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Order Creation - Item Pricing Log'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_ZSDE002_ITMPRC_LOG 
  as select from ztsd_e002_itmprc
  
  association to parent ZI_ZSDE002_ITEM_LOG as _ItemLog
    on $projection.ItemUUID = _ItemLog.ItemUUID
    
  association [1..1] to ZR_ZSDE002_ORDER_LOG as _OrderLog
    on $projection.OrderUUID = _OrderLog.OrderUUID
{
  key item_pricing_uuid   as ItemPricingUUID,
      item_uuid           as ItemUUID,
      _OrderLog.OrderUUID as OrderUUID,
      conditiontype       as ConditionType,
      
      _ItemLog,
      _OrderLog
}
