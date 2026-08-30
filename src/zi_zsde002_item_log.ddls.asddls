@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Order Creation - Item Log'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_ZSDE002_ITEM_LOG
  as select from ztsd_e002_item

  composition [0..*] of ZI_ZSDE002_ITMPRC_LOG as _ItemPricingLog

  association to parent ZR_ZSDE002_ORDER_LOG as _OrderLog
    on $projection.OrderUUID = _OrderLog.OrderUUID
{
      @EndUserText.label: 'Item Log UUID'
  key item_uuid             as ItemUUID,

      @EndUserText.label: 'Order Log UUID'
      order_uuid            as OrderUUID,

      @EndUserText.label: 'Item'
      item                  as Item,
      @EndUserText.label: 'Material Number'
      materialnumber        as MaterialNumber,
      @EndUserText.label: 'Customer Material'
      customermaterial      as CustomerMaterial,
      @EndUserText.label: 'Item Category'
      itemcategory          as ItemCategory,
      @EndUserText.label: 'Requested Quantity'
      requestedquantity     as RequestedQuantity,
      @EndUserText.label: 'Sales Unit'
      salesunit             as SalesUnit,
      @EndUserText.label: 'Plant'
      plant                 as Plant,
      @EndUserText.label: 'Storage Location'
      storagelocation       as StorageLocation,
      @EndUserText.label: 'Material Tax Class'
      mattaxclass           as MatTaxClass,
      @EndUserText.label: 'Sales Text'
      salestext             as SalesText,
      @EndUserText.label: 'Unit Text'
      unittext              as UnitText,
      @EndUserText.label: 'Promotion ID Text'
      promotionidtext       as PromotionIdText,
      @EndUserText.label: 'Batch'
      batch                 as Batch,
      @EndUserText.label: 'Route'
      route                 as Route,
      @EndUserText.label: 'SF Item ID Ref.'
      sfitemidref           as SfItemIdRef,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      _ItemPricingLog,
      _OrderLog
}
