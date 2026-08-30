@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Order Creation - Order Pricing Log'
@Metadata.allowExtensions: true
define view entity ZC_ZSDE002_ORDPRC_LOG
  as projection on ZI_ZSDE002_ORDPRC_LOG
{
  key OrderPricingUUID,
      OrderUUID,

      ConditionType,
      ConditionAmount,
      ConditionCurrency,
      ConditionPricingUnit,
      ConditionUnitOfMeasure,

      LocalLastChangedAt,

      /* Associations */
      _OrderLog : redirected to parent ZC_ZSDE002_ORDER_LOG
}
