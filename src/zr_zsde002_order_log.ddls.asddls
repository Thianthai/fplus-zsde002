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
  key order_uuid                    as OrderUUID,

      @EndUserText.label: 'Request ID'
      request_id                    as RequestId,
      @EndUserText.label: 'Request Body (JSON)'
      request_body                  as RequestBody,

      @EndUserText.label: 'SF Header ID Ref.'
      sf_header_id_ref              as SfHeaderIdRef,
      @EndUserText.label: 'Sales Order Temp ID'
      sales_order_temp_id           as SalesOrderTempId,
      @EndUserText.label: 'Process Type'
      process_type                  as ProcessType,
      @EndUserText.label: 'Transaction Type'
      tran_type                     as TranType,
      @EndUserText.label: 'Sales Order Type'
      sales_order_type              as SalesOrderType,
      @EndUserText.label: 'Sales Organization'
      sales_organization            as SalesOrganization,
      @EndUserText.label: 'Distribution Channel'
      distribution_channel          as DistributionChannel,
      @EndUserText.label: 'Division'
      division                      as Division,
      @EndUserText.label: 'Sold-to Party'
      sold_to_party                 as SoldToParty,
      @EndUserText.label: 'Customer Branch'
      customer_branch               as CustomerBranch,
      @EndUserText.label: 'Ship-to Party'
      ship_to_party                 as ShipToParty,
      @EndUserText.label: 'Bill-to Party'
      bill_to_party                 as BillToParty,
      @EndUserText.label: 'Payer'
      payer                         as Payer,
      @EndUserText.label: 'Stock Van'
      stock_van                     as StockVan,
      @EndUserText.label: 'Customer Reference'
      customer_reference            as CustomerReference,
      @EndUserText.label: 'Customer Reference Date'
      customer_reference_date       as CustomerReferenceDate,
      @EndUserText.label: 'Document Date'
      document_date                 as DocumentDate,
      @EndUserText.label: 'Req. Delivery Date'
      req_delivery_date             as ReqDeliveryDate,
      @EndUserText.label: 'Shipping Conditions'
      shipping_conditions           as ShippingConditions,
      @EndUserText.label: 'Payment Transaction Ref.'
      payment_transaction_reference as PaymentTransactionReference,
      @EndUserText.label: 'Tax Document No.'
      tax_document_no               as TaxDocumentNo,
      @EndUserText.label: 'Related Document Ref.'
      related_document_reference    as RelatedDocumentReference,
      @EndUserText.label: 'Currency'
      currency                      as Currency,
      @EndUserText.label: 'Payment Term'
      payment_term                  as PaymentTerm,
      @EndUserText.label: 'Original Sales Document'
      original_sales_document       as OriginalSalesDocument,
      @EndUserText.label: 'Order Reason'
      order_reason                  as OrderReason,
      @EndUserText.label: 'Order Reason Text'
      order_reason_text             as OrderReasonText,
      @EndUserText.label: 'Customer PO'
      customer_po                   as CustomerPO,

      @EndUserText.label: 'Sales Order Number'
      sales_order_number            as SalesOrderNumber,
      @EndUserText.label: 'Status'
      order_status                  as OrderStatus,

      @Semantics.user.createdBy: true
      @EndUserText.label: 'Created By'
      created_by                    as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      @EndUserText.label: 'Created At'
      created_at                    as CreatedAt,
      @Semantics.user.lastChangedBy: true
      @EndUserText.label: 'Last Changed By'
      last_changed_by               as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      @EndUserText.label: 'Last Changed At'
      last_changed_at               as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      @EndUserText.label: 'Local Last Changed At'
      local_last_changed_at         as LocalLastChangedAt,

      _OrderPricingLog,
      _OrderMessageLog,
      _ItemLog
}
