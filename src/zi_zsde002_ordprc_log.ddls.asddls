@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Order Creation - Order Pricing Log'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_ZSDE002_ORDPRC_LOG 
  as select from ztsd_e002_ordprc
  
  association to parent ZR_ZSDE002_ORDER_LOG as _OrderLog
    on $projection.OrderUUID = _OrderLog.OrderUUID
{
  key order_pricing_uuid as OrderPricingUUID,
      order_uuid         as OrderUUID,
      conditiontype      as ConditionType,
      
      _OrderLog
}
