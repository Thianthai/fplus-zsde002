@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Order Creation - Item Log'
@Metadata.allowExtensions: true
define view entity ZC_ZSDE002_ITEM_LOG
  as projection on ZI_ZSDE002_ITEM_LOG
{
  key ItemUUID,
      OrderUUID,

      Item,
      MaterialNumber,
      CustomerMaterial,
      ItemCategory,
      RequestedQuantity,
      SalesUnit,
      Plant,
      StorageLocation,
      MatTaxClass,
      SalesText,
      UnitText,
      PromotionIdText,
      Batch,
      Route,
      SfItemIdRef,

      LocalLastChangedAt,

      /* Associations */
      _ItemPricingLog : redirected to composition child ZC_ZSDE002_ITMPRC_LOG,
      _OrderLog       : redirected to parent ZC_ZSDE002_ORDER_LOG
}
