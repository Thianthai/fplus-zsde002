@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Order Creation - Item Log'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_ZSDE002_ITEM_LOG 
  as select from ztsd_e002_item
  
  composition [0..*] of ZI_ZSDE002_ITMPRC_LOG as _ItemPricingLog
  
  association to parent ZR_ZSDE002_ORDER_LOG as _OrderLog
    on $projection.OrderUUID = _OrderLog.OrderUUID
{
  key item_uuid  as ItemUUID,
      order_uuid as OrderUUID,
      item       as Item,

      
      
      _ItemPricingLog,
      _OrderLog
}
