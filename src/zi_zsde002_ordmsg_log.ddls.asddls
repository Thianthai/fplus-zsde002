@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Order Creation - Order Message Log'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_ZSDE002_ORDMSG_LOG
  as select from ztsd_e002_ordmsg

  association to parent ZR_ZSDE002_ORDER_LOG as _OrderLog
    on $projection.OrderUUID = _OrderLog.OrderUUID
{
      @EndUserText.label: 'Order Message Log UUID'
  key order_message_uuid    as OrderMessageUUID,

      @EndUserText.label: 'Order Log UUID'
      order_uuid            as OrderUUID,

      @EndUserText.label: 'Sequence'
      msg_seq               as MsgSeq,
      @EndUserText.label: 'Message Area'
      message_area          as MessageArea,
      @EndUserText.label: 'Status'
      status                as Status,
      @EndUserText.label: 'Message'
      message               as Message,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      _OrderLog
}
