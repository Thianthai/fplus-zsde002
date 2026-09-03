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
  key order_pricing_uuid       as OrderPricingUUID,

      @EndUserText.label: 'Order Log UUID'
      order_uuid               as OrderUUID,

      @EndUserText.label: 'Condition Type'
      condition_type           as ConditionType,
      @EndUserText.label: 'Condition Amount'
      condition_amount         as ConditionAmount,
      @EndUserText.label: 'Condition Currency'
      condition_currency       as ConditionCurrency,
      @EndUserText.label: 'Pricing Unit'
      condition_pricing_unit   as ConditionPricingUnit,
      @EndUserText.label: 'Unit of Measure'
      condition_unit_of_measure as ConditionUnitOfMeasure,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at    as LocalLastChangedAt,

      _OrderLog
}
