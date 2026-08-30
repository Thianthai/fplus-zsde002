@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Order Creation - Order Log'
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: [ 'RequestId', 'SfHeaderIdRef' ]
define root view entity ZC_ZSDE002_ORDER_LOG
  provider contract transactional_query
  as projection on ZR_ZSDE002_ORDER_LOG
{
  key OrderUUID,

      @Search.defaultSearchElement: true
      RequestId,
      RequestBody,

      @Search.defaultSearchElement: true
      SfHeaderIdRef,
      SalesOrderTempId,
      ProcessType,
      TranType,
      SalesOrderType,
      SalesOrganization,
      DistributionChannel,
      Division,
      SoldToParty,
      CustomerBranch,
      ShipToParty,
      BillToParty,
      Payer,
      StockVan,
      @Search.defaultSearchElement: true
      CustomerReference,
      CustomerReferenceDate,
      DocumentDate,
      ReqDeliveryDate,
      ShippingConditions,
      PaymentTransactionReference,
      TaxDocumentNo,
      RelatedDocumentReference,
      Currency,
      PaymentTerm,
      OriginalSalesDocument,
      OrderReason,
      OrderReasonText,
      CustomerPO,

      @Search.defaultSearchElement: true
      SalesOrderNumber,
      OrderStatus,

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,

      /* Associations */
      _ItemLog         : redirected to composition child ZC_ZSDE002_ITEM_LOG,
      _OrderPricingLog : redirected to composition child ZC_ZSDE002_ORDPRC_LOG,
      _OrderMessageLog : redirected to composition child ZC_ZSDE002_ORDMSG_LOG
}
