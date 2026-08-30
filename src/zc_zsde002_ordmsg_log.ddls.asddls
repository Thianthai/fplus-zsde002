@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Order Creation - Order Message Log'
@Metadata.allowExtensions: true
define view entity ZC_ZSDE002_ORDMSG_LOG 
  as projection on ZI_ZSDE002_ORDMSG_LOG
{
  key OrderMessageUUID,
  OrderUUID,
  Status,
  Message,
  
  /* Associations */
  _OrderLog : redirected to parent ZC_ZSDE002_ORDER_LOG
}
