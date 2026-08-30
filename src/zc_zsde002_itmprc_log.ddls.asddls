@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Order Creation - Item Pricing Log'
@Metadata.allowExtensions: true
define view entity ZC_ZSDE002_ITMPRC_LOG
  as projection on ZI_ZSDE002_ITMPRC_LOG
{
  key ItemPricingUUID,
      ItemUUID,
      OrderUUID,

      ConditionType,
      ConditionAmount,
      ConditionCurrency,
      ConditionPricingUnit,
      ConditionUnitOfMeasure,

      LocalLastChangedAt,

      /* Associations */
      _ItemLog  : redirected to parent ZC_ZSDE002_ITEM_LOG,
      _OrderLog : redirected to ZC_ZSDE002_ORDER_LOG
}
