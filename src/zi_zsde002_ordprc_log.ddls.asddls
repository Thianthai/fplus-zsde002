@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Order Creation - Order Pricing Log'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_ZSDE002_ORDPRC_LOG
  as select from ztsd_e002_ordprc

  association to parent ZR_ZSDE002_ORDER_LOG as _OrderLog
    on $projection.OrderUUID = _OrderLog.OrderUUID
{
      @EndUserText.label: 'Order Pricing Log UUID'
  key order_pricing_uuid     as OrderPricingUUID,

      @EndUserText.label: 'Order Log UUID'
      order_uuid             as OrderUUID,

      @EndUserText.label: 'Condition Type'
      conditiontype          as ConditionType,
      @EndUserText.label: 'Condition Amount'
      conditionamount        as ConditionAmount,
      @EndUserText.label: 'Condition Currency'
      conditioncurrency      as ConditionCurrency,
      @EndUserText.label: 'Pricing Unit'
      conditionpricingunit   as ConditionPricingUnit,
      @EndUserText.label: 'Unit of Measure'
      conditionunitofmeasure as ConditionUnitOfMeasure,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at  as LocalLastChangedAt,

      _OrderLog
}
