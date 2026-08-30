@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Order Creation - Order Log'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZR_ZSDE002_ORDER_LOG 
  as select from ztsd_e002_order
  
  composition [0..*] of ZI_ZSDE002_ORDPRC_LOG as _OrderPricingLog
  composition [0..*] of ZI_ZSDE002_ORDMSG_LOG as _OrderMessageLog
  composition [0..*] of ZI_ZSDE002_ITEM_LOG   as _ItemLog
{
  key order_uuid        as OrderUUID,
  sfheaderidref         as SfHeaderIdRef,
      
  @Semantics.user.createdBy: true
  created_by            as CreatedBy,
  @Semantics.systemDateTime.createdAt: true
  created_at            as CreatedAt,
  @Semantics.user.lastChangedBy: true
  last_changed_by       as LastChangedBy,
  @Semantics.systemDateTime.lastChangedAt: true
  last_changed_at       as LastChangedAt,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  local_last_changed_at as LocalLastChangedAt,
  
  _OrderPricingLog,
  _OrderMessageLog,
  _ItemLog  
}
