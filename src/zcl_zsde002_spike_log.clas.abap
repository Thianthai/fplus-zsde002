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
*    create_test_data( out ).
*    create_full_sample( out ).
*    verify( out ).

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
                      request_body          = |\{ "sf_header_id_ref": "SPIKE-{ lv_o }", "sales_order_type": "ZOR" \}|
                      sf_header_id_ref         = |SPIKE-{ lv_o }|
                      sales_order_temp_id      = |TMP{ lv_o }|
                      process_type           = '01'
                      tran_type              = 'N'
                      sales_order_type        = 'ZOR'
                      sales_organization     = '1000'
                      distribution_channel   = '10'
                      division              = '00'
                      sold_to_party           = '0000001000'
                      ship_to_party           = '0000001000'
                      bill_to_party           = '0000001000'
                      payer                 = '0000001000'
                      customer_reference     = |PO-SPIKE-{ lv_o }|
                      document_date          = '2026-08-30'
                      req_delivery_date       = '2026-09-05'
                      shipping_conditions    = '01'
                      currency              = 'THB'
                      payment_term           = '0001'
                      sales_order_number      = COND #( WHEN lv_o = 1 THEN '0000004711' ELSE space )
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
                      condition_type          = 'ZDI2'
                      condition_amount        = '100.00'
                      condition_currency      = 'THB'
                      condition_pricing_unit   = '1'
                      condition_unit_of_measure = 'EA'
                      local_last_changed_at  = lv_now
                    ) TO lt_ordprc.

      APPEND VALUE #( order_pricing_uuid     = new_uuid( )
                      order_uuid             = lv_order_uuid
                      condition_type          = 'ZDI3'
                      condition_amount        = '50.00'
                      condition_currency      = 'THB'
                      condition_pricing_unit   = '1'
                      condition_unit_of_measure = 'EA'
                      local_last_changed_at  = lv_now
                    ) TO lt_ordprc.

      " ---------- messages ----------
      APPEND VALUE #( order_message_uuid    = new_uuid( )
                      order_uuid            = lv_order_uuid
                      msg_seq               = '0001'
                      message_area          = 'HEADER'
                      status                = 'S'
                      message               = |Spike message 1 for order { lv_o }|
                      local_last_changed_at = lv_now
                    ) TO lt_ordmsg.

      APPEND VALUE #( order_message_uuid    = new_uuid( )
                      order_uuid            = lv_order_uuid
                      msg_seq               = '0002'
                      message_area          = 'ITEM'
                      status                = 'W'
                      message               = |Spike message 2 for order { lv_o }|
                      local_last_changed_at = lv_now
                    ) TO lt_ordmsg.

      APPEND VALUE #( order_message_uuid    = new_uuid( )
                      order_uuid            = lv_order_uuid
                      msg_seq               = '0003'
                      message_area          = 'COMMIT_HEADER'
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
                        material_number        = |MAT-{ lv_o }{ lv_i }|
                        customer_material      = |CMAT-{ lv_i }|
                        item_category          = 'ZTAN'
                        requested_quantity     = '10.000'
                        sales_unit             = 'EA'
                        plant                 = '1000'
                        storage_location       = '0001'
                        sales_text             = |Spike sales text for item { lv_i }|
                        sf_item_id_ref           = |SFITEM-{ lv_o }{ lv_i }|
                        local_last_changed_at = lv_now
                      ) TO lt_item.

        " ---------- item pricing : order_uuid filled directly, no RAP needed ----------
        APPEND VALUE #( item_pricing_uuid      = new_uuid( )
                        item_uuid              = lv_item_uuid
                        order_uuid             = lv_order_uuid
                        condition_type          = 'ZPI1'
                        condition_amount        = '250.00'
                        condition_currency      = 'THB'
                        condition_pricing_unit   = '1'
                        condition_unit_of_measure = 'EA'
                        local_last_changed_at  = lv_now
                      ) TO lt_itmprc.

        APPEND VALUE #( item_pricing_uuid      = new_uuid( )
                        item_uuid              = lv_item_uuid
                        order_uuid             = lv_order_uuid
                        condition_type          = 'ZDI1'
                        condition_amount        = '25.00'
                        condition_currency      = 'THB'
                        condition_pricing_unit   = '1'
                        condition_unit_of_measure = 'EA'
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
        ( `  "sf_header_id_ref": "SPIKE-FULL",` )
        ( `  "sales_order_temp_id": "TMP9001",` )
        ( `  "process_type": "01",` )
        ( `  "tran_type": "N",` )
        ( `  "sales_order_type": "ZOR",` )
        ( `  "sales_organization": "1000",` )
        ( `  "distribution_channel": "10",` )
        ( `  "division": "00",` )
        ( `  "sold_to_party": "0000001000",` )
        ( `  "customer_branch": "00001",` )
        ( `  "ship_to_party": "0000001001",` )
        ( `  "bill_to_party": "0000001002",` )
        ( `  "payer": "0000001003",` )
        ( `  "stock_van": "0000009001",` )
        ( `  "customer_reference": "PO-SPIKE-FULL-001",` )
        ( `  "customer_reference_date": "2026-08-28",` )
        ( `  "document_date": "2026-08-30",` )
        ( `  "req_delivery_date": "2026-09-05",` )
        ( `  "shipping_conditions": "01",` )
        ( `  "payment_transaction_reference": "TXN-2026-08-30-0001",` )
        ( `  "tax_document_no": "TAX0012345",` )
        ( `  "related_document_reference": "REL0098765",` )
        ( `  "currency": "THB",` )
        ( `  "payment_term": "0001",` )
        ( `  "original_sales_document": "0000001234",` )
        ( `  "order_reason": "01",` )
        ( `  "order_reason_text": "Customer requested replacement for damaged goods",` )
        ( `  "customer_po": "CUSTPO-778899",` )
        ( `  "pricing": [` )
        ( `    {` )
        ( `      "condition_type": "ZDI2",` )
        ( `      "condition_amount": "100.00",` )
        ( `      "condition_currency": "THB",` )
        ( `      "condition_pricing_unit": "1",` )
        ( `      "condition_unit_of_measure": "EA"` )
        ( `    },` )
        ( `    {` )
        ( `      "condition_type": "ZDI3",` )
        ( `      "condition_amount": "50.00",` )
        ( `      "condition_currency": "THB",` )
        ( `      "condition_pricing_unit": "1",` )
        ( `      "condition_unit_of_measure": "EA"` )
        ( `    }` )
        ( `  ],` )
        ( `  "item": [` )
        ( `    {` )
        ( `      "item": "000010",` )
        ( `      "material_number": "MAT-FULL-01",` )
        ( `      "customer_material": "CMAT-01",` )
        ( `      "item_category": "ZTAN",` )
        ( `      "requested_quantity": "10.000",` )
        ( `      "sales_unit": "EA",` )
        ( `      "plant": "1000",` )
        ( `      "storage_location": "0001",` )
        ( `      "mat_tax_class": "1",` )
        ( `      "sales_text": "Full sample sales text for item 000010",` )
        ( `      "unit_text": "Carton of 12",` )
        ( `      "promotion_id_text": "PROMO-2026-Q3",` )
        ( `      "batch": "BATCH00001",` )
        ( `      "route": "R00001",` )
        ( `      "sf_item_id_ref": "SFITEM-FULL-01",` )
        ( `      "pricing": [` )
        ( `        {` )
        ( `          "condition_type": "ZPI1",` )
        ( `          "condition_amount": "250.00",` )
        ( `          "condition_currency": "THB",` )
        ( `          "condition_pricing_unit": "1",` )
        ( `          "condition_unit_of_measure": "EA"` )
        ( `        },` )
        ( `        {` )
        ( `          "condition_type": "ZDI1",` )
        ( `          "condition_amount": "25.00",` )
        ( `          "condition_currency": "THB",` )
        ( `          "condition_pricing_unit": "1",` )
        ( `          "condition_unit_of_measure": "EA"` )
        ( `        }` )
        ( `      ]` )
        ( `    },` )
        ( `    {` )
        ( `      "item": "000020",` )
        ( `      "material_number": "MAT-FULL-02",` )
        ( `      "customer_material": "CMAT-02",` )
        ( `      "item_category": "ZTAN",` )
        ( `      "requested_quantity": "5.000",` )
        ( `      "sales_unit": "EA",` )
        ( `      "plant": "1000",` )
        ( `      "storage_location": "0002",` )
        ( `      "mat_tax_class": "1",` )
        ( `      "sales_text": "Full sample sales text for item 000020",` )
        ( `      "unit_text": "Box of 6",` )
        ( `      "promotion_id_text": "PROMO-2026-Q3",` )
        ( `      "batch": "BATCH00002",` )
        ( `      "route": "R00002",` )
        ( `      "sf_item_id_ref": "SFITEM-FULL-02",` )
        ( `      "pricing": [` )
        ( `        {` )
        ( `          "condition_type": "ZPI1",` )
        ( `          "condition_amount": "480.00",` )
        ( `          "condition_currency": "THB",` )
        ( `          "condition_pricing_unit": "1",` )
        ( `          "condition_unit_of_measure": "EA"` )
        ( `        },` )
        ( `        {` )
        ( `          "condition_type": "ZDI1",` )
        ( `          "condition_amount": "30.00",` )
        ( `          "condition_currency": "THB",` )
        ( `          "condition_pricing_unit": "1",` )
        ( `          "condition_unit_of_measure": "EA"` )
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
                    sf_header_id_ref               = 'SPIKE-FULL'
                    sales_order_temp_id            = 'TMP9001'
                    process_type                 = '01'
                    tran_type                    = 'N'
                    sales_order_type              = 'ZOR'
                    sales_organization           = '1000'
                    distribution_channel         = '10'
                    division                    = '00'
                    sold_to_party                 = '0000001000'
                    customer_branch              = '00001'
                    ship_to_party                 = '0000001001'
                    bill_to_party                 = '0000001002'
                    payer                       = '0000001003'
                    stock_van                    = '0000009001'
                    customer_reference           = 'PO-SPIKE-FULL-001'
                    customer_reference_date       = '2026-08-28'
                    document_date                = '2026-08-30'
                    req_delivery_date             = '2026-09-05'
                    shipping_conditions          = '01'
                    payment_transaction_reference = 'TXN-2026-08-30-0001'
                    tax_document_no               = 'TAX0012345'
                    related_document_reference    = 'REL0098765'
                    currency                    = 'THB'
                    payment_term                 = '0001'
                    original_sales_document       = '0000001234'
                    order_reason                 = '01'
                    order_reason_text             = 'Customer requested replacement for damaged goods'
                    customer_po                  = 'CUSTPO-778899'
                    sales_order_number            = '0000004712'
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
                    condition_type          = 'ZDI2'
                    condition_amount        = '100.00'
                    condition_currency      = 'THB'
                    condition_pricing_unit   = '1'
                    condition_unit_of_measure = 'EA'
                    local_last_changed_at  = lv_now
                  ) TO lt_ordprc.

    APPEND VALUE #( order_pricing_uuid     = new_uuid( )
                    order_uuid             = lv_order_uuid
                    condition_type          = 'ZDI3'
                    condition_amount        = '50.00'
                    condition_currency      = 'THB'
                    condition_pricing_unit   = '1'
                    condition_unit_of_measure = 'EA'
                    local_last_changed_at  = lv_now
                  ) TO lt_ordprc.

    " ---------- messages ----------
    APPEND VALUE #( order_message_uuid    = new_uuid( )
                    order_uuid            = lv_order_uuid
                    msg_seq               = '0001'
                    message_area          = 'HEADER'
                    status                = 'S'
                    message               = 'Sales order 0000004712 created'
                    local_last_changed_at = lv_now
                  ) TO lt_ordmsg.

    APPEND VALUE #( order_message_uuid    = new_uuid( )
                    order_uuid            = lv_order_uuid
                    msg_seq               = '0002'
                    message_area          = 'ITEM'
                    status                = 'W'
                    message               = 'Item 000020 confirmed quantity is lower than requested quantity'
                    local_last_changed_at = lv_now
                  ) TO lt_ordmsg.

    APPEND VALUE #( order_message_uuid    = new_uuid( )
                    order_uuid            = lv_order_uuid
                    msg_seq               = '0003'
                    message_area          = 'COMMIT_HEADER'
                    status                = 'S'
                    message               = 'Document saved'
                    local_last_changed_at = lv_now
                  ) TO lt_ordmsg.

    " ---------- item 000010 ----------
    APPEND VALUE #( item_uuid             = lv_item1_uuid
                    order_uuid            = lv_order_uuid
                    item                  = '000010'
                    material_number        = 'MAT-FULL-01'
                    customer_material      = 'CMAT-01'
                    item_category          = 'ZTAN'
                    requested_quantity     = '10.000'
                    sales_unit             = 'EA'
                    plant                 = '1000'
                    storage_location       = '0001'
                    mat_tax_class           = '1'
                    sales_text             = 'Full sample sales text for item 000010'
                    unit_text              = 'Carton of 12'
                    promotion_id_text       = 'PROMO-2026-Q3'
                    batch                 = 'BATCH00001'
                    route                 = 'R00001'
                    sf_item_id_ref           = 'SFITEM-FULL-01'
                    local_last_changed_at = lv_now
                  ) TO lt_item.

    APPEND VALUE #( item_pricing_uuid      = new_uuid( )
                    item_uuid              = lv_item1_uuid
                    order_uuid             = lv_order_uuid
                    condition_type          = 'ZPI1'
                    condition_amount        = '250.00'
                    condition_currency      = 'THB'
                    condition_pricing_unit   = '1'
                    condition_unit_of_measure = 'EA'
                    local_last_changed_at  = lv_now
                  ) TO lt_itmprc.

    APPEND VALUE #( item_pricing_uuid      = new_uuid( )
                    item_uuid              = lv_item1_uuid
                    order_uuid             = lv_order_uuid
                    condition_type          = 'ZDI1'
                    condition_amount        = '25.00'
                    condition_currency      = 'THB'
                    condition_pricing_unit   = '1'
                    condition_unit_of_measure = 'EA'
                    local_last_changed_at  = lv_now
                  ) TO lt_itmprc.

    " ---------- item 000020 ----------
    APPEND VALUE #( item_uuid             = lv_item2_uuid
                    order_uuid            = lv_order_uuid
                    item                  = '000020'
                    material_number        = 'MAT-FULL-02'
                    customer_material      = 'CMAT-02'
                    item_category          = 'ZTAN'
                    requested_quantity     = '5.000'
                    sales_unit             = 'EA'
                    plant                 = '1000'
                    storage_location       = '0002'
                    mat_tax_class           = '1'
                    sales_text             = 'Full sample sales text for item 000020'
                    unit_text              = 'Box of 6'
                    promotion_id_text       = 'PROMO-2026-Q3'
                    batch                 = 'BATCH00002'
                    route                 = 'R00002'
                    sf_item_id_ref           = 'SFITEM-FULL-02'
                    local_last_changed_at = lv_now
                  ) TO lt_item.

    APPEND VALUE #( item_pricing_uuid      = new_uuid( )
                    item_uuid              = lv_item2_uuid
                    order_uuid             = lv_order_uuid
                    condition_type          = 'ZPI1'
                    condition_amount        = '480.00'
                    condition_currency      = 'THB'
                    condition_pricing_unit   = '1'
                    condition_unit_of_measure = 'EA'
                    local_last_changed_at  = lv_now
                  ) TO lt_itmprc.

    APPEND VALUE #( item_pricing_uuid      = new_uuid( )
                    item_uuid              = lv_item2_uuid
                    order_uuid             = lv_order_uuid
                    condition_type          = 'ZDI1'
                    condition_amount        = '30.00'
                    condition_currency      = 'THB'
                    condition_pricing_unit   = '1'
                    condition_unit_of_measure = 'EA'
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
