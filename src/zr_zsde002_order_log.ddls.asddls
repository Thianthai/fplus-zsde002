@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Order Creation - Order Log'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZR_ZSDE002_ORDER_LOG
  as select from ztsd_e002_order

  composition [0..*] of ZI_ZSDE002_ORDPRC_LOG as _OrderPricingLog
  composition [0..*] of ZI_ZSDE002_ORDMSG_LOG as _OrderMessageLog
  composition [0..*] of ZI_ZSDE002_ITEM_LOG   as _ItemLog
{
      @EndUserText.label: 'Order Log UUID'
  key order_uuid                  as OrderUUID,

      @EndUserText.label: 'Request ID'
      request_id                  as RequestId,
      @EndUserText.label: 'Request Body (JSON)'
      request_body                as RequestBody,

      @EndUserText.label: 'SF Header ID Ref.'
      sfheaderidref               as SfHeaderIdRef,
      @EndUserText.label: 'Sales Order Temp ID'
      salesordertempid            as SalesOrderTempId,
      @EndUserText.label: 'Process Type'
      processtype                 as ProcessType,
      @EndUserText.label: 'Transaction Type'
      trantype                    as TranType,
      @EndUserText.label: 'Sales Order Type'
      salesordertype              as SalesOrderType,
      @EndUserText.label: 'Sales Organization'
      salesorganization           as SalesOrganization,
      @EndUserText.label: 'Distribution Channel'
      distributionchannel         as DistributionChannel,
      @EndUserText.label: 'Division'
      division                    as Division,
      @EndUserText.label: 'Sold-to Party'
      soldtoparty                 as SoldToParty,
      @EndUserText.label: 'Customer Branch'
      customerbranch              as CustomerBranch,
      @EndUserText.label: 'Ship-to Party'
      shiptoparty                 as ShipToParty,
      @EndUserText.label: 'Bill-to Party'
      billtoparty                 as BillToParty,
      @EndUserText.label: 'Payer'
      payer                       as Payer,
      @EndUserText.label: 'Stock Van'
      stockvan                    as StockVan,
      @EndUserText.label: 'Customer Reference'
      customerreference           as CustomerReference,
      @EndUserText.label: 'Customer Reference Date'
      customerreferencedate       as CustomerReferenceDate,
      @EndUserText.label: 'Document Date'
      documentdate                as DocumentDate,
      @EndUserText.label: 'Req. Delivery Date'
      reqdeliverydate             as ReqDeliveryDate,
      @EndUserText.label: 'Shipping Conditions'
      shippingconditions          as ShippingConditions,
      @EndUserText.label: 'Payment Transaction Ref.'
      paymenttransactionreference as PaymentTransactionReference,
      @EndUserText.label: 'Tax Document No.'
      taxdocumentno               as TaxDocumentNo,
      @EndUserText.label: 'Related Document Ref.'
      relateddocumentreference    as RelatedDocumentReference,
      @EndUserText.label: 'Currency'
      currency                    as Currency,
      @EndUserText.label: 'Payment Term'
      paymentterm                 as PaymentTerm,
      @EndUserText.label: 'Original Sales Document'
      originalsalesdocument       as OriginalSalesDocument,
      @EndUserText.label: 'Order Reason'
      orderreason                 as OrderReason,
      @EndUserText.label: 'Order Reason Text'
      orderreasontext             as OrderReasonText,
      @EndUserText.label: 'Customer PO'
      customerpo                  as CustomerPO,

      @EndUserText.label: 'Sales Order Number'
      salesordernumber            as SalesOrderNumber,
      @EndUserText.label: 'Status'
      order_status                as OrderStatus,

      @Semantics.user.createdBy: true
      @EndUserText.label: 'Created By'
      created_by                  as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      @EndUserText.label: 'Created At'
      created_at                  as CreatedAt,
      @Semantics.user.lastChangedBy: true
      @EndUserText.label: 'Last Changed By'
      last_changed_by             as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      @EndUserText.label: 'Last Changed At'
      last_changed_at             as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      @EndUserText.label: 'Local Last Changed At'
      local_last_changed_at       as LocalLastChangedAt,

      _OrderPricingLog,
      _OrderMessageLog,
      _ItemLog
}
