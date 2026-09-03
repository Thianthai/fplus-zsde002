CLASS zcl_zsde002_spike_log DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .

  PROTECTED SECTION.
  PRIVATE SECTION.

    CONSTANTS gc_request_id TYPE ztsd_e002_order-request_id VALUE 'SPIKE-LOG'.

    METHODS purge_all
      IMPORTING io_out TYPE REF TO if_oo_adt_classrun_out.

    METHODS create_test_data
      IMPORTING io_out TYPE REF TO if_oo_adt_classrun_out.

    METHODS verify
      IMPORTING io_out TYPE REF TO if_oo_adt_classrun_out.

    METHODS new_uuid
      RETURNING VALUE(rv_uuid) TYPE sysuuid_x16.

    METHODS create_full_sample
      IMPORTING io_out TYPE REF TO if_oo_adt_classrun_out.

ENDCLASS.



CLASS zcl_zsde002_spike_log IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    purge_all( out ).
    create_test_data( out ).
    create_full_sample( out ).
    verify( out ).

  ENDMETHOD.


  METHOD new_uuid.

    TRY.
        rv_uuid = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
        CLEAR rv_uuid.
    ENDTRY.

  ENDMETHOD.


  METHOD purge_all.

    " the five tables hold nothing but spike data until the handler starts logging
    DELETE FROM ztsd_e002_itmprc.
    DELETE FROM ztsd_e002_ordprc.
    DELETE FROM ztsd_e002_ordmsg.
    DELETE FROM ztsd_e002_item.
    DELETE FROM ztsd_e002_order.

    COMMIT WORK.

    io_out->write( |--- all 5 tables purged ---| ).

  ENDMETHOD.


  METHOD create_test_data.

    DATA lt_order   TYPE STANDARD TABLE OF ztsd_e002_order.
    DATA lt_item    TYPE STANDARD TABLE OF ztsd_e002_item.
    DATA lt_ordprc  TYPE STANDARD TABLE OF ztsd_e002_ordprc.
    DATA lt_itmprc  TYPE STANDARD TABLE OF ztsd_e002_itmprc.
    DATA lt_ordmsg  TYPE STANDARD TABLE OF ztsd_e002_ordmsg.

    DATA lv_now     TYPE timestampl.
    DATA lv_item_no TYPE n LENGTH 6.

    GET TIME STAMP FIELD lv_now.

    DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).

    DO 2 TIMES.

      DATA(lv_o)          = sy-index.
      DATA(lv_order_uuid) = new_uuid( ).

      APPEND VALUE #( order_uuid            = lv_order_uuid
                      request_id            = gc_request_id
                      request_body          = |\{ "sfHeaderIdRef": "SPIKE-{ lv_o }", "salesOrderType": "ZOR" \}|
                      sfheaderidref         = |SPIKE-{ lv_o }|
                      salesordertempid      = |TMP{ lv_o }|
                      processtype           = '01'
                      trantype              = 'N'
                      salesordertype        = 'ZOR'
                      salesorganization     = '1000'
                      distributionchannel   = '10'
                      division              = '00'
                      soldtoparty           = '0000001000'
                      shiptoparty           = '0000001000'
                      billtoparty           = '0000001000'
                      payer                 = '0000001000'
                      customerreference     = |PO-SPIKE-{ lv_o }|
                      documentdate          = '2026-08-30'
                      reqdeliverydate       = '2026-09-05'
                      shippingconditions    = '01'
                      currency              = 'THB'
                      paymentterm           = '0001'
                      salesordernumber      = COND #( WHEN lv_o = 1 THEN '0000004711' ELSE space )
                      order_status          = COND #( WHEN lv_o = 1 THEN 'S' ELSE 'E' )
                      created_by            = lv_user
                      created_at            = lv_now
                      last_changed_by       = lv_user
                      last_changed_at       = lv_now
                      local_last_changed_at = lv_now
                    ) TO lt_order.

      " ---------- header pricing ----------
      APPEND VALUE #( order_pricing_uuid     = new_uuid( )
                      order_uuid             = lv_order_uuid
                      conditiontype          = 'ZDI2'
                      conditionamount        = '100.00'
                      conditioncurrency      = 'THB'
                      conditionpricingunit   = '1'
                      conditionunitofmeasure = 'EA'
                      local_last_changed_at  = lv_now
                    ) TO lt_ordprc.

      APPEND VALUE #( order_pricing_uuid     = new_uuid( )
                      order_uuid             = lv_order_uuid
                      conditiontype          = 'ZDI3'
                      conditionamount        = '50.00'
                      conditioncurrency      = 'THB'
                      conditionpricingunit   = '1'
                      conditionunitofmeasure = 'EA'
                      local_last_changed_at  = lv_now
                    ) TO lt_ordprc.

      " ---------- messages ----------
      APPEND VALUE #( order_message_uuid    = new_uuid( )
                      order_uuid            = lv_order_uuid
                      msg_seq               = '0001'
                      area                  = 'HEADER'
                      status                = 'S'
                      message               = |Spike message 1 for order { lv_o }|
                      local_last_changed_at = lv_now
                    ) TO lt_ordmsg.

      APPEND VALUE #( order_message_uuid    = new_uuid( )
                      order_uuid            = lv_order_uuid
                      msg_seq               = '0002'
                      area                  = 'ITEM'
                      status                = 'W'
                      message               = |Spike message 2 for order { lv_o }|
                      local_last_changed_at = lv_now
                    ) TO lt_ordmsg.

      APPEND VALUE #( order_message_uuid    = new_uuid( )
                      order_uuid            = lv_order_uuid
                      msg_seq               = '0003'
                      area                  = 'COMMIT_HEADER'
                      status                = 'E'
                      message               = |Spike message 3 for order { lv_o }|
                      local_last_changed_at = lv_now
                    ) TO lt_ordmsg.

      " ---------- items ----------
      DO 2 TIMES.

        DATA(lv_i)         = sy-index.
        DATA(lv_item_uuid) = new_uuid( ).

        lv_item_no = lv_i * 10.

        APPEND VALUE #( item_uuid             = lv_item_uuid
                        order_uuid            = lv_order_uuid
                        item                  = lv_item_no
                        materialnumber        = |MAT-{ lv_o }{ lv_i }|
                        customermaterial      = |CMAT-{ lv_i }|
                        itemcategory          = 'ZTAN'
                        requestedquantity     = '10.000'
                        salesunit             = 'EA'
                        plant                 = '1000'
                        storagelocation       = '0001'
                        salestext             = |Spike sales text for item { lv_i }|
                        sfitemidref           = |SFITEM-{ lv_o }{ lv_i }|
                        local_last_changed_at = lv_now
                      ) TO lt_item.

        " ---------- item pricing : order_uuid filled directly, no RAP needed ----------
        APPEND VALUE #( item_pricing_uuid      = new_uuid( )
                        item_uuid              = lv_item_uuid
                        order_uuid             = lv_order_uuid
                        conditiontype          = 'ZPI1'
                        conditionamount        = '250.00'
                        conditioncurrency      = 'THB'
                        conditionpricingunit   = '1'
                        conditionunitofmeasure = 'EA'
                        local_last_changed_at  = lv_now
                      ) TO lt_itmprc.

        APPEND VALUE #( item_pricing_uuid      = new_uuid( )
                        item_uuid              = lv_item_uuid
                        order_uuid             = lv_order_uuid
                        conditiontype          = 'ZDI1'
                        conditionamount        = '25.00'
                        conditioncurrency      = 'THB'
                        conditionpricingunit   = '1'
                        conditionunitofmeasure = 'EA'
                        local_last_changed_at  = lv_now
                      ) TO lt_itmprc.

      ENDDO.
    ENDDO.

    INSERT ztsd_e002_order  FROM TABLE @lt_order.
    io_out->write( |INSERT order  : sy-subrc { sy-subrc }, { sy-dbcnt } row(s)| ).

    INSERT ztsd_e002_item   FROM TABLE @lt_item.
    io_out->write( |INSERT item   : sy-subrc { sy-subrc }, { sy-dbcnt } row(s)| ).

    INSERT ztsd_e002_ordprc FROM TABLE @lt_ordprc.
    io_out->write( |INSERT ordprc : sy-subrc { sy-subrc }, { sy-dbcnt } row(s)| ).

    INSERT ztsd_e002_itmprc FROM TABLE @lt_itmprc.
    io_out->write( |INSERT itmprc : sy-subrc { sy-subrc }, { sy-dbcnt } row(s)| ).

    INSERT ztsd_e002_ordmsg FROM TABLE @lt_ordmsg.
    io_out->write( |INSERT ordmsg : sy-subrc { sy-subrc }, { sy-dbcnt } row(s)| ).

    COMMIT WORK.

  ENDMETHOD.


  METHOD verify.

    SELECT COUNT(*) FROM ztsd_e002_order
      WHERE request_id = @gc_request_id
      INTO @DATA(lv_order_count).

    SELECT COUNT(*) FROM ztsd_e002_item  AS i
      INNER JOIN ztsd_e002_order AS o ON o~order_uuid = i~order_uuid
      WHERE o~request_id = @gc_request_id
      INTO @DATA(lv_item_count).

    SELECT COUNT(*) FROM ztsd_e002_ordprc AS p
      INNER JOIN ztsd_e002_order AS o ON o~order_uuid = p~order_uuid
      WHERE o~request_id = @gc_request_id
      INTO @DATA(lv_ordprc_count).

    SELECT COUNT(*) FROM ztsd_e002_ordmsg AS m
      INNER JOIN ztsd_e002_order AS o ON o~order_uuid = m~order_uuid
      WHERE o~request_id = @gc_request_id
      INTO @DATA(lv_ordmsg_count).

    SELECT COUNT(*) FROM ztsd_e002_itmprc AS ip
      INNER JOIN ztsd_e002_item  AS i ON i~item_uuid  = ip~item_uuid
      INNER JOIN ztsd_e002_order AS o ON o~order_uuid = i~order_uuid
      WHERE o~request_id = @gc_request_id
      INTO @DATA(lv_itmprc_count).

    DATA lv_initial_uuid TYPE sysuuid_x16.

    SELECT COUNT(*) FROM ztsd_e002_itmprc
      WHERE order_uuid = @lv_initial_uuid
      INTO @DATA(lv_itmprc_orphan).

    io_out->write( |--- VERIFY ---| ).
    io_out->write( |ZTSD_E002_ORDER  : { lv_order_count }  (expected 3)| ).
    io_out->write( |ZTSD_E002_ITEM   : { lv_item_count }  (expected 6)| ).
    io_out->write( |ZTSD_E002_ORDPRC : { lv_ordprc_count }  (expected 6)| ).
    io_out->write( |ZTSD_E002_ORDMSG : { lv_ordmsg_count }  (expected 9)| ).
    io_out->write( |ZTSD_E002_ITMPRC : { lv_itmprc_count }  (expected 12)| ).
    io_out->write( |ITMPRC rows with empty ORDER_UUID : { lv_itmprc_orphan }  (expected 0)| ).

  ENDMETHOD.

  METHOD create_full_sample.

    DATA lt_order  TYPE STANDARD TABLE OF ztsd_e002_order.
    DATA lt_item   TYPE STANDARD TABLE OF ztsd_e002_item.
    DATA lt_ordprc TYPE STANDARD TABLE OF ztsd_e002_ordprc.
    DATA lt_itmprc TYPE STANDARD TABLE OF ztsd_e002_itmprc.
    DATA lt_ordmsg TYPE STANDARD TABLE OF ztsd_e002_ordmsg.

    DATA lv_now TYPE timestampl.

    GET TIME STAMP FIELD lv_now.

    DATA(lv_user)       = cl_abap_context_info=>get_user_technical_name( ).
    DATA(lv_order_uuid) = new_uuid( ).
    DATA(lv_item1_uuid) = new_uuid( ).
    DATA(lv_item2_uuid) = new_uuid( ).

    " ---------- the raw JSON of this one order, exactly as SBPA sends it ----------
    DATA(lv_body) = concat_lines_of(
      table = VALUE string_table(
        ( `{` )
        ( `  "sfHeaderIdRef": "SPIKE-FULL",` )
        ( `  "salesOrderTempId": "TMP9001",` )
        ( `  "processType": "01",` )
        ( `  "tranType": "N",` )
        ( `  "salesOrderType": "ZOR",` )
        ( `  "salesOrganization": "1000",` )
        ( `  "distributionChannel": "10",` )
        ( `  "division": "00",` )
        ( `  "soldToParty": "0000001000",` )
        ( `  "customerBranch": "00001",` )
        ( `  "shipToParty": "0000001001",` )
        ( `  "billToParty": "0000001002",` )
        ( `  "payer": "0000001003",` )
        ( `  "stockVan": "0000009001",` )
        ( `  "customerReference": "PO-SPIKE-FULL-001",` )
        ( `  "customerReferenceDate": "2026-08-28",` )
        ( `  "documentDate": "2026-08-30",` )
        ( `  "reqDeliveryDate": "2026-09-05",` )
        ( `  "shippingConditions": "01",` )
        ( `  "paymentTransactionReference": "TXN-2026-08-30-0001",` )
        ( `  "taxDocumentNo": "TAX0012345",` )
        ( `  "relatedDocumentReference": "REL0098765",` )
        ( `  "currency": "THB",` )
        ( `  "paymentTerm": "0001",` )
        ( `  "originalSalesDocument": "0000001234",` )
        ( `  "orderReason": "01",` )
        ( `  "orderReasonText": "Customer requested replacement for damaged goods",` )
        ( `  "customerPo": "CUSTPO-778899",` )
        ( `  "pricing": [` )
        ( `    {` )
        ( `      "conditionType": "ZDI2",` )
        ( `      "conditionAmount": "100.00",` )
        ( `      "conditionCurrency": "THB",` )
        ( `      "conditionPricingUnit": "1",` )
        ( `      "conditionUnitOfMeasure": "EA"` )
        ( `    },` )
        ( `    {` )
        ( `      "conditionType": "ZDI3",` )
        ( `      "conditionAmount": "50.00",` )
        ( `      "conditionCurrency": "THB",` )
        ( `      "conditionPricingUnit": "1",` )
        ( `      "conditionUnitOfMeasure": "EA"` )
        ( `    }` )
        ( `  ],` )
        ( `  "item": [` )
        ( `    {` )
        ( `      "item": "000010",` )
        ( `      "materialNumber": "MAT-FULL-01",` )
        ( `      "customerMaterial": "CMAT-01",` )
        ( `      "itemCategory": "ZTAN",` )
        ( `      "requestedQuantity": "10.000",` )
        ( `      "salesUnit": "EA",` )
        ( `      "plant": "1000",` )
        ( `      "storageLocation": "0001",` )
        ( `      "matTaxClass": "1",` )
        ( `      "salesText": "Full sample sales text for item 000010",` )
        ( `      "unitText": "Carton of 12",` )
        ( `      "promotionIdText": "PROMO-2026-Q3",` )
        ( `      "batch": "BATCH00001",` )
        ( `      "route": "R00001",` )
        ( `      "sfItemIdRef": "SFITEM-FULL-01",` )
        ( `      "pricing": [` )
        ( `        {` )
        ( `          "conditionType": "ZPI1",` )
        ( `          "conditionAmount": "250.00",` )
        ( `          "conditionCurrency": "THB",` )
        ( `          "conditionPricingUnit": "1",` )
        ( `          "conditionUnitOfMeasure": "EA"` )
        ( `        },` )
        ( `        {` )
        ( `          "conditionType": "ZDI1",` )
        ( `          "conditionAmount": "25.00",` )
        ( `          "conditionCurrency": "THB",` )
        ( `          "conditionPricingUnit": "1",` )
        ( `          "conditionUnitOfMeasure": "EA"` )
        ( `        }` )
        ( `      ]` )
        ( `    },` )
        ( `    {` )
        ( `      "item": "000020",` )
        ( `      "materialNumber": "MAT-FULL-02",` )
        ( `      "customerMaterial": "CMAT-02",` )
        ( `      "itemCategory": "ZTAN",` )
        ( `      "requestedQuantity": "5.000",` )
        ( `      "salesUnit": "EA",` )
        ( `      "plant": "1000",` )
        ( `      "storageLocation": "0002",` )
        ( `      "matTaxClass": "1",` )
        ( `      "salesText": "Full sample sales text for item 000020",` )
        ( `      "unitText": "Box of 6",` )
        ( `      "promotionIdText": "PROMO-2026-Q3",` )
        ( `      "batch": "BATCH00002",` )
        ( `      "route": "R00002",` )
        ( `      "sfItemIdRef": "SFITEM-FULL-02",` )
        ( `      "pricing": [` )
        ( `        {` )
        ( `          "conditionType": "ZPI1",` )
        ( `          "conditionAmount": "480.00",` )
        ( `          "conditionCurrency": "THB",` )
        ( `          "conditionPricingUnit": "1",` )
        ( `          "conditionUnitOfMeasure": "EA"` )
        ( `        },` )
        ( `        {` )
        ( `          "conditionType": "ZDI1",` )
        ( `          "conditionAmount": "30.00",` )
        ( `          "conditionCurrency": "THB",` )
        ( `          "conditionPricingUnit": "1",` )
        ( `          "conditionUnitOfMeasure": "EA"` )
        ( `        }` )
        ( `      ]` )
        ( `    }` )
        ( `  ]` )
        ( `}` ) )
      sep = |\n| ).

    " ---------- header : every column filled ----------
    APPEND VALUE #( order_uuid                  = lv_order_uuid
                    request_id                  = gc_request_id
                    request_body                = lv_body
                    sfheaderidref               = 'SPIKE-FULL'
                    salesordertempid            = 'TMP9001'
                    processtype                 = '01'
                    trantype                    = 'N'
                    salesordertype              = 'ZOR'
                    salesorganization           = '1000'
                    distributionchannel         = '10'
                    division                    = '00'
                    soldtoparty                 = '0000001000'
                    customerbranch              = '00001'
                    shiptoparty                 = '0000001001'
                    billtoparty                 = '0000001002'
                    payer                       = '0000001003'
                    stockvan                    = '0000009001'
                    customerreference           = 'PO-SPIKE-FULL-001'
                    customerreferencedate       = '2026-08-28'
                    documentdate                = '2026-08-30'
                    reqdeliverydate             = '2026-09-05'
                    shippingconditions          = '01'
                    paymenttransactionreference = 'TXN-2026-08-30-0001'
                    taxdocumentno               = 'TAX0012345'
                    relateddocumentreference    = 'REL0098765'
                    currency                    = 'THB'
                    paymentterm                 = '0001'
                    originalsalesdocument       = '0000001234'
                    orderreason                 = '01'
                    orderreasontext             = 'Customer requested replacement for damaged goods'
                    customerpo                  = 'CUSTPO-778899'
                    salesordernumber            = '0000004712'
                    order_status                = 'W'
                    created_by                  = lv_user
                    created_at                  = lv_now
                    last_changed_by             = lv_user
                    last_changed_at             = lv_now
                    local_last_changed_at       = lv_now
                  ) TO lt_order.

    " ---------- header pricing ----------
    APPEND VALUE #( order_pricing_uuid     = new_uuid( )
                    order_uuid             = lv_order_uuid
                    conditiontype          = 'ZDI2'
                    conditionamount        = '100.00'
                    conditioncurrency      = 'THB'
                    conditionpricingunit   = '1'
                    conditionunitofmeasure = 'EA'
                    local_last_changed_at  = lv_now
                  ) TO lt_ordprc.

    APPEND VALUE #( order_pricing_uuid     = new_uuid( )
                    order_uuid             = lv_order_uuid
                    conditiontype          = 'ZDI3'
                    conditionamount        = '50.00'
                    conditioncurrency      = 'THB'
                    conditionpricingunit   = '1'
                    conditionunitofmeasure = 'EA'
                    local_last_changed_at  = lv_now
                  ) TO lt_ordprc.

    " ---------- messages ----------
    APPEND VALUE #( order_message_uuid    = new_uuid( )
                    order_uuid            = lv_order_uuid
                    msg_seq               = '0001'
                    area                  = 'HEADER'
                    status                = 'S'
                    message               = 'Sales order 0000004712 created'
                    local_last_changed_at = lv_now
                  ) TO lt_ordmsg.

    APPEND VALUE #( order_message_uuid    = new_uuid( )
                    order_uuid            = lv_order_uuid
                    msg_seq               = '0002'
                    area                  = 'ITEM'
                    status                = 'W'
                    message               = 'Item 000020 confirmed quantity is lower than requested quantity'
                    local_last_changed_at = lv_now
                  ) TO lt_ordmsg.

    APPEND VALUE #( order_message_uuid    = new_uuid( )
                    order_uuid            = lv_order_uuid
                    msg_seq               = '0003'
                    area                  = 'COMMIT_HEADER'
                    status                = 'S'
                    message               = 'Document saved'
                    local_last_changed_at = lv_now
                  ) TO lt_ordmsg.

    " ---------- item 000010 ----------
    APPEND VALUE #( item_uuid             = lv_item1_uuid
                    order_uuid            = lv_order_uuid
                    item                  = '000010'
                    materialnumber        = 'MAT-FULL-01'
                    customermaterial      = 'CMAT-01'
                    itemcategory          = 'ZTAN'
                    requestedquantity     = '10.000'
                    salesunit             = 'EA'
                    plant                 = '1000'
                    storagelocation       = '0001'
                    mattaxclass           = '1'
                    salestext             = 'Full sample sales text for item 000010'
                    unittext              = 'Carton of 12'
                    promotionidtext       = 'PROMO-2026-Q3'
                    batch                 = 'BATCH00001'
                    route                 = 'R00001'
                    sfitemidref           = 'SFITEM-FULL-01'
                    local_last_changed_at = lv_now
                  ) TO lt_item.

    APPEND VALUE #( item_pricing_uuid      = new_uuid( )
                    item_uuid              = lv_item1_uuid
                    order_uuid             = lv_order_uuid
                    conditiontype          = 'ZPI1'
                    conditionamount        = '250.00'
                    conditioncurrency      = 'THB'
                    conditionpricingunit   = '1'
                    conditionunitofmeasure = 'EA'
                    local_last_changed_at  = lv_now
                  ) TO lt_itmprc.

    APPEND VALUE #( item_pricing_uuid      = new_uuid( )
                    item_uuid              = lv_item1_uuid
                    order_uuid             = lv_order_uuid
                    conditiontype          = 'ZDI1'
                    conditionamount        = '25.00'
                    conditioncurrency      = 'THB'
                    conditionpricingunit   = '1'
                    conditionunitofmeasure = 'EA'
                    local_last_changed_at  = lv_now
                  ) TO lt_itmprc.

    " ---------- item 000020 ----------
    APPEND VALUE #( item_uuid             = lv_item2_uuid
                    order_uuid            = lv_order_uuid
                    item                  = '000020'
                    materialnumber        = 'MAT-FULL-02'
                    customermaterial      = 'CMAT-02'
                    itemcategory          = 'ZTAN'
                    requestedquantity     = '5.000'
                    salesunit             = 'EA'
                    plant                 = '1000'
                    storagelocation       = '0002'
                    mattaxclass           = '1'
                    salestext             = 'Full sample sales text for item 000020'
                    unittext              = 'Box of 6'
                    promotionidtext       = 'PROMO-2026-Q3'
                    batch                 = 'BATCH00002'
                    route                 = 'R00002'
                    sfitemidref           = 'SFITEM-FULL-02'
                    local_last_changed_at = lv_now
                  ) TO lt_item.

    APPEND VALUE #( item_pricing_uuid      = new_uuid( )
                    item_uuid              = lv_item2_uuid
                    order_uuid             = lv_order_uuid
                    conditiontype          = 'ZPI1'
                    conditionamount        = '480.00'
                    conditioncurrency      = 'THB'
                    conditionpricingunit   = '1'
                    conditionunitofmeasure = 'EA'
                    local_last_changed_at  = lv_now
                  ) TO lt_itmprc.

    APPEND VALUE #( item_pricing_uuid      = new_uuid( )
                    item_uuid              = lv_item2_uuid
                    order_uuid             = lv_order_uuid
                    conditiontype          = 'ZDI1'
                    conditionamount        = '30.00'
                    conditioncurrency      = 'THB'
                    conditionpricingunit   = '1'
                    conditionunitofmeasure = 'EA'
                    local_last_changed_at  = lv_now
                  ) TO lt_itmprc.

    INSERT ztsd_e002_order  FROM TABLE @lt_order.
    INSERT ztsd_e002_item   FROM TABLE @lt_item.
    INSERT ztsd_e002_ordprc FROM TABLE @lt_ordprc.
    INSERT ztsd_e002_itmprc FROM TABLE @lt_itmprc.
    INSERT ztsd_e002_ordmsg FROM TABLE @lt_ordmsg.

    COMMIT WORK.

    io_out->write( |--- full sample order SPIKE-FULL created ---| ).
    io_out->write( |request_body length : { strlen( lv_body ) } chars| ).

  ENDMETHOD.

ENDCLASS.
