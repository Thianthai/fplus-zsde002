@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Order Creation - Order Pricing Log'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_ZSDE002_ORDMSG_LOG 
  as select from ztsd_e002_ordmsg
  
  association to parent ZR_ZSDE002_ORDER_LOG as _OrderLog
    on $projection.OrderUUID = _OrderLog.OrderUUID
{
  key order_message_uuid as OrderMessageUUID,
      order_uuid         as OrderUUID,
      status             as Status,
      message            as Message,
      
      _OrderLog
}
